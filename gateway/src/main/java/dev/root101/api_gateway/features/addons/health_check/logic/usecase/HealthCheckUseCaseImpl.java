package dev.root101.api_gateway.features.addons.health_check.logic.usecase;

import dev.root101.api_gateway.config.LocalizedException;
import dev.root101.api_gateway.features.addons.base.data.entity.AddonEntity;
import dev.root101.api_gateway.features.addons.base.data.entity.AddonJson;
import dev.root101.api_gateway.features.addons.base.data.repo.AddonRepo;
import dev.root101.api_gateway.features.addons.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.features.addons.health_check.logic.model.HealthCheckResponse;
import dev.root101.api_gateway.features.addons.health_check.logic.model.HealthCheckState;
import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import tools.jackson.databind.ObjectMapper;

import java.net.URI;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * The health check of each route, kept in memory and called by a scheduler that looks every few seconds for the ones
 * due. Each instance calls its own (as the routes, see decision 6).
 */
@Service
class HealthCheckUseCaseImpl implements HealthCheckUseCase, SmartInitializingSingleton {

    private static final Logger log = LoggerFactory.getLogger(HealthCheckUseCaseImpl.class);

    /**
     * The longest a call can take; under the shortest interval, so a slow service never piles calls up
     */
    static final Duration TIMEOUT = Duration.ofSeconds(5);

    private final AddonRepo addonRepo;
    private final RouteRepo routeRepo;
    private final ObjectMapper objectMapper;
    //the default client: no redirects followed, so a check never leaves the host of its route
    private final WebClient webClient = WebClient.create();

    //replaced as a whole on each reload, by route id
    private volatile Map<String, Entry> state = Map.of();

    //the routes with a call on the way: the scheduler never starts a second one
    private final Set<String> running = ConcurrentHashMap.newKeySet();

    private record Entry(HealthCheck config, HealthCheckState state) {
    }

    HealthCheckUseCaseImpl(AddonRepo addonRepo, RouteRepo routeRepo, ObjectMapper objectMapper) {
        this.addonRepo = addonRepo;
        this.routeRepo = routeRepo;
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterSingletonsInstantiated() {
        reload().block(Duration.ofSeconds(60));
    }

    @Override
    public HealthCheckResponse ofRoute(String routeId) {
        Entry entry = state.get(routeId);
        if (entry == null) return null;
        HealthCheck config = entry.config();
        return new HealthCheckResponse(config.enabled(), config.path(), config.intervalSeconds(), entry.state());
    }

    @Override
    public Mono<HealthCheckResponse> setRoute(String routeId, HealthCheck healthCheck) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> save(route.getRouteId(), healthCheck))
                .then(reload())
                .then(Mono.fromSupplier(() -> ofRoute(routeId)));
    }

    @Override
    public Mono<HealthCheckResponse> enableRoute(String routeId, boolean enabled) {
        return configured(routeId)
                .flatMap(addon -> {
                    HealthCheck current = read(addon.getConfig(), HealthCheck.class);
                    return write(addon, new HealthCheck(enabled, current.path(), current.intervalSeconds()));
                })
                .then(reload())
                .then(Mono.fromSupplier(() -> ofRoute(routeId)));
    }

    @Override
    public Mono<Void> deleteRoute(String routeId) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> save(route.getRouteId(), null))
                .then(reload());
    }

    @Override
    public Mono<HealthCheckResponse> run(String routeId) {
        return configured(routeId)
                .flatMap(addon -> routeRepo.findById(addon.getRouteId())
                        .flatMap(route -> check(route, read(addon.getConfig(), HealthCheck.class))))
                .then(Mono.fromSupplier(() -> ofRoute(routeId)));
    }

    /**
     * The row of the health check of a route: `404` if the route has none, or one that can't be read
     */
    private Mono<AddonEntity> configured(String routeId) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> addonRepo.findByRouteIdAndType(route.getRouteId(), HealthCheck.TYPE))
                .filter(addon -> valid(read(addon.getConfig(), HealthCheck.class)))
                .switchIfEmpty(Mono.error(new LocalizedException(HttpStatus.NOT_FOUND, "health_check.route.not_found", routeId)));
    }

    /**
     * Calls every health check that is on and due. Each call writes its own result.
     */
    @Scheduled(fixedDelay = 5_000, initialDelay = 5_000)
    public void runDue() {
        OffsetDateTime now = OffsetDateTime.now();
        state.forEach((routeId, entry) -> {
            if (!entry.config().on()) return;
            OffsetDateTime last = entry.state().checkedAt();
            if (last != null && last.plusSeconds(entry.config().intervalSeconds()).isAfter(now)) return;
            if (!running.add(routeId)) return;
            routeRepo.findById(UUID.fromString(routeId))
                    .flatMap(route -> check(route, entry.config()))
                    .doFinally(signal -> running.remove(routeId))
                    .subscribe(null, e -> log.warn("Health check of route {} not saved", routeId, e));
        });
    }

    /**
     * Calls the service and saves the result in the state only: an edit of the admin is never overwritten
     */
    private Mono<Void> check(RouteEntity route, HealthCheck config) {
        return call(route.getUri(), config.path())
                .flatMap(result -> addonRepo.updateState(route.getRouteId(), HealthCheck.TYPE, objectMapper.writeValueAsString(result)))
                .then(reload());
    }

    /**
     * `GET {uri}{path}`, its body thrown away. Never fails: no answer in time is a result too (`status` null).
     */
    private Mono<HealthCheckState> call(String uri, String path) {
        long start = System.nanoTime();
        //the uri of a route has no path; the host is always the route's, whatever the path says
        return Mono.defer(() -> webClient.get()
                        .uri(URI.create(uri.replaceAll("/+$", "") + path))
                        .exchangeToMono(response -> response.releaseBody().thenReturn(response.statusCode().value())))
                .timeout(TIMEOUT)
                .map(status -> result(start, status))
                .onErrorResume(e -> Mono.just(result(start, null)));
    }

    private static HealthCheckState result(long start, Integer status) {
        return new HealthCheckState(
                OffsetDateTime.now().truncatedTo(ChronoUnit.MICROS),
                status != null && status >= 200 && status < 300,
                status,
                Duration.ofNanos(System.nanoTime() - start).toMillis()
        );
    }

    @Override
    public Mono<Void> save(UUID routeId, HealthCheck healthCheck) {
        Mono<AddonEntity> current = addonRepo.findByRouteIdAndType(routeId, HealthCheck.TYPE);
        if (healthCheck == null) {
            return current.flatMap(addonRepo::delete);
        }
        return current.defaultIfEmpty(new AddonEntity(null, routeId, HealthCheck.TYPE, null, null, null, null))
                .flatMap(addon -> write(addon, healthCheck))
                .then();
    }

    /**
     * Saves the config; the state (the last result) is kept
     */
    private Mono<AddonEntity> write(AddonEntity addon, HealthCheck healthCheck) {
        OffsetDateTime now = OffsetDateTime.now().truncatedTo(ChronoUnit.MICROS);
        addon.setConfig(new AddonJson(objectMapper.writeValueAsString(healthCheck)));
        if (addon.getCreatedAt() == null) addon.setCreatedAt(now);
        addon.setUpdatedAt(now);
        return addonRepo.save(addon);
    }

    private static boolean valid(HealthCheck config) {
        return config != null && config.enabled() != null && config.path() != null && config.intervalSeconds() != null;
    }

    //null when missing or unreadable: a broken row never breaks the gateway
    private <T> T read(AddonJson json, Class<T> type) {
        if (json == null) return null;
        try {
            return objectMapper.readValue(json.json(), type);
        } catch (RuntimeException e) {
            return null;
        }
    }

    @Override
    public Mono<Void> reload() {
        return addonRepo.findByType(HealthCheck.TYPE)
                .collectList()
                .doOnNext(addons -> {
                    Map<String, Entry> routes = new HashMap<>();
                    for (AddonEntity addon : addons) {
                        HealthCheck config = read(addon.getConfig(), HealthCheck.class);
                        if (addon.getRouteId() == null || !valid(config)) {
                            //never stops the startup: a broken row is skipped, as if it wasn't configured
                            log.warn("Skipping the health check add-on {}: its config can't be read", addon.getAddonId());
                            continue;
                        }
                        HealthCheckState result = read(addon.getState(), HealthCheckState.class);
                        routes.put(addon.getRouteId().toString(), new Entry(config, result != null ? result : HealthCheckState.NONE));
                    }
                    state = Map.copyOf(routes);
                })
                .then();
    }
}
