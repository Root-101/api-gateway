package dev.root101.api_gateway.core.feature.addons.cors.logic.usecase;

import lombok.extern.slf4j.Slf4j;
import dev.root101.api_gateway.core.error.Errors;
import dev.root101.api_gateway.core.feature.addons.base.data.entity.AddonEntity;
import dev.root101.api_gateway.core.feature.addons.base.data.entity.AddonJson;
import dev.root101.api_gateway.core.feature.addons.base.data.repo.AddonRepo;
import dev.root101.api_gateway.core.feature.addons.cors.logic.model.Cors;
import dev.root101.api_gateway.core.feature.addons.cors.logic.model.CorsResponse;
import dev.root101.api_gateway.core.feature.routes.data.repo.RouteRepo;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Mono;
import tools.jackson.databind.ObjectMapper;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * The CORS of the gateway and of each route, kept in memory: every request with an `Origin` reads it. Changes made by
 * another instance are not seen until a restart (as the routes).
 * <br/>
 * The gateway's row always exists: on the first start it is created from `CORS_ALLOWED_ORIGINS` (deprecated), or `*`.
 */
@Slf4j
@Service
class CorsUseCase_Impl implements CorsUseCase, SmartInitializingSingleton {

    private final AddonRepo addonRepo;
    private final RouteRepo routeRepo;
    private final ObjectMapper objectMapper;
    //the deprecated env var, empty when it isn't set
    private final List<String> envOrigins;

    //replaced as a whole on each reload: a request never sees half of it
    private volatile State state = new State(null, Map.of());

    private record State(Cors gateway, Map<String, Cors> routes) {
    }

    CorsUseCase_Impl(AddonRepo addonRepo, RouteRepo routeRepo, ObjectMapper objectMapper,
                    @Value("${app.cors.allowed-origins:}") String envOrigins) {
        this.addonRepo = addonRepo;
        this.routeRepo = routeRepo;
        this.objectMapper = objectMapper;
        this.envOrigins = Arrays.stream(envOrigins.split(",")).map(String::trim).filter(StringUtils::hasText).toList();
    }

    /**
     * Loaded before the server accepts traffic, as the routes: the console can call the admin API right away
     */
    @Override
    public void afterSingletonsInstantiated() {
        seed().then(reload()).block(Duration.ofSeconds(60));
    }

    /**
     * Creates the gateway's row the first time, from the deprecated env var or `*`; after that the env var is ignored
     */
    Mono<Void> seed() {
        if (!envOrigins.isEmpty()) {
            log.warn("CORS_ALLOWED_ORIGINS is deprecated and will be removed in 7.0: CORS is edited from the console or the admin API (PUT /addons/cors)");
        }
        return addonRepo.findByRouteIdIsNullAndType(Cors.TYPE)
                .doOnNext(addon -> {
                    Cors current = read(addon.getConfig());
                    if (!envOrigins.isEmpty() && (current == null || !sameOrigins(current.allowedOrigins()))) {
                        log.warn("CORS_ALLOWED_ORIGINS ({}) is ignored: the gateway's CORS add-on is used ({})",
                                envOrigins, current != null ? current.allowedOrigins() : "unreadable");
                    }
                })
                .switchIfEmpty(Mono.defer(() -> {
                    Cors cors = new Cors(true, envOrigins.isEmpty() ? List.of("*") : envOrigins, false);
                    log.info("Creating the gateway's CORS add-on with the origins {}", cors.allowedOrigins());
                    return write(newAddon(null), cors);
                }))
                //two instances starting together: the other one created it first
                .onErrorResume(DataIntegrityViolationException.class, e -> Mono.empty())
                .then();
    }

    @Override
    public Cors ofGateway() {
        return state.gateway();
    }

    @Override
    @SuppressWarnings("removal")
    public CorsResponse gatewayResponse() {
        Cors gateway = state.gateway();
        if (gateway == null) return null;
        CorsResponse.EnvVar envVar = envOrigins.isEmpty() ? null
                : new CorsResponse.EnvVar("CORS_ALLOWED_ORIGINS", envOrigins, sameOrigins(gateway.allowedOrigins()));
        return new CorsResponse(gateway.enabled(), gateway.allowedOrigins(), gateway.allowCredentials(), envVar);
    }

    //in any order: the same set of origins is the same policy
    private boolean sameOrigins(List<String> origins) {
        return Set.copyOf(envOrigins).equals(Set.copyOf(origins));
    }

    @Override
    public Cors ofRoute(String routeId) {
        return state.routes().get(routeId);
    }

    @Override
    public Cors active(String routeId) {
        State current = state;
        Cors route = routeId != null ? current.routes().get(routeId) : null;
        return route != null && route.on() ? route : current.gateway();
    }

    @Override
    public Mono<CorsResponse> setGateway(Cors cors, String origin) {
        return Mono.defer(() -> {
                    if (!cors.on()) return Mono.error(Errors.badRequest("cors.gateway.disabled"));
                    if (cors.credentials()) return Mono.error(Errors.badRequest("cors.gateway.credentials"));
                    //without a browser (curl) CORS doesn't apply: a broken policy is always fixable from there
                    if (origin != null && cors.toConfiguration().checkOrigin(origin) == null) {
                        return Mono.error(Errors.badRequest("cors.gateway.lockout", origin));
                    }
                    return addonRepo.findByRouteIdIsNullAndType(Cors.TYPE).defaultIfEmpty(newAddon(null));
                })
                .flatMap(addon -> write(addon, cors))
                .then(reload())
                .then(Mono.fromSupplier(this::gatewayResponse));
    }

    @Override
    public Mono<Cors> setRoute(String routeId, Cors cors) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> save(route.getRouteId(), cors))
                .then(reload())
                .then(Mono.fromSupplier(() -> ofRoute(routeId)));
    }

    @Override
    public Mono<Cors> enableRoute(String routeId, boolean enabled) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> addonRepo.findByRouteIdAndType(route.getRouteId(), Cors.TYPE))
                .filter(addon -> valid(read(addon.getConfig())))
                .switchIfEmpty(Mono.error(Errors.notFound("cors.route.not_found", routeId)))
                .flatMap(addon -> {
                    Cors current = read(addon.getConfig());
                    return write(addon, new Cors(enabled, current.allowedOrigins(), current.allowCredentials()));
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
    public Mono<Void> save(UUID routeId, Cors cors) {
        Mono<AddonEntity> current = addonRepo.findByRouteIdAndType(routeId, Cors.TYPE);
        if (cors == null) {
            return current.flatMap(addonRepo::delete);
        }
        //the pre-6.0.0 hole: any page reads a cookie-authenticated service through the gateway
        if (cors.credentials() && cors.allowsAnyOrigin()) {
            return Mono.error(Errors.badRequest("cors.credentials.any_origin"));
        }
        return current.defaultIfEmpty(newAddon(routeId))
                .flatMap(addon -> write(addon, cors))
                .then();
    }

    private AddonEntity newAddon(UUID routeId) {
        return new AddonEntity(null, routeId, Cors.TYPE, null, null, null, null);
    }

    private Mono<AddonEntity> write(AddonEntity addon, Cors cors) {
        OffsetDateTime now = OffsetDateTime.now().truncatedTo(ChronoUnit.MICROS);
        addon.setConfig(new AddonJson(objectMapper.writeValueAsString(cors)));
        if (addon.getCreatedAt() == null) addon.setCreatedAt(now);
        addon.setUpdatedAt(now);
        return addonRepo.save(addon);
    }

    //a row edited by hand into credentials with any origin is skipped too: never reopen that hole
    private static boolean valid(Cors config) {
        return config != null && config.enabled() != null && config.allowedOrigins() != null
                && !config.allowedOrigins().isEmpty() && !config.allowedOrigins().contains(null)
                && !(config.credentials() && config.allowsAnyOrigin());
    }

    //null when missing or unreadable: a broken row never breaks the gateway
    private Cors read(AddonJson json) {
        if (json == null) return null;
        try {
            return objectMapper.readValue(json.json(), Cors.class);
        } catch (RuntimeException e) {
            return null;
        }
    }

    @Override
    public Mono<Void> reload() {
        return addonRepo.findByType(Cors.TYPE)
                .collectList()
                .doOnNext(addons -> {
                    Cors gateway = null;
                    Map<String, Cors> routes = new HashMap<>();
                    for (AddonEntity addon : addons) {
                        Cors config = read(addon.getConfig());
                        if (!valid(config)) {
                            //never stops the startup: a broken row is skipped, as if it wasn't configured
                            log.warn("Skipping the CORS add-on {}: its config can't be read", addon.getAddonId());
                            continue;
                        }
                        if (addon.getRouteId() == null) {
                            gateway = config;
                        } else {
                            routes.put(addon.getRouteId().toString(), config);
                        }
                    }
                    state = new State(gateway, Map.copyOf(routes));
                })
                .then();
    }
}
