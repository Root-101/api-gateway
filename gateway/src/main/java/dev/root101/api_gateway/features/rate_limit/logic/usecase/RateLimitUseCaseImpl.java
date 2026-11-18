package dev.root101.api_gateway.features.rate_limit.logic.usecase;

import dev.root101.api_gateway.config.LocalizedException;
import dev.root101.api_gateway.features.addons.data.entity.AddonEntity;
import dev.root101.api_gateway.features.addons.data.entity.AddonJson;
import dev.root101.api_gateway.features.addons.data.repo.AddonRepo;
import dev.root101.api_gateway.features.rate_limit.logic.model.RateLimit;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import tools.jackson.databind.ObjectMapper;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * The rate limit of the gateway and of each route, and the requests each client ip has left, all in memory: every
 * proxied request reads it and nothing is written to db per request. Per instance (see decision 6).
 * <br/>
 * shortcut: one bucket per client ip and limit, forgotten once full again (every minute); many distinct ips within
 * that minute (a spoofed `X-Forwarded-For` with `TRUSTED_PROXIES=.*` exposed directly) grow the map. Move to a
 * bounded cache, or Redis with several replicas, if that is ever seen.
 */
@Service
class RateLimitUseCaseImpl implements RateLimitUseCase, SmartInitializingSingleton {

    private static final Logger log = LoggerFactory.getLogger(RateLimitUseCaseImpl.class);

    //the key of the gateway's buckets, a route id never is empty
    private static final String GATEWAY = "";

    private final AddonRepo addonRepo;
    private final RouteRepo routeRepo;
    private final ObjectMapper objectMapper;

    //replaced as a whole on each reload, with empty buckets: a changed limit starts counting again
    private volatile State state = new State(null, Map.of(), new ConcurrentHashMap<>());

    private record State(RateLimit gateway, Map<String, RateLimit> routes, Map<String, TokenBucket> buckets) {
    }

    RateLimitUseCaseImpl(AddonRepo addonRepo, RouteRepo routeRepo, ObjectMapper objectMapper) {
        this.addonRepo = addonRepo;
        this.routeRepo = routeRepo;
        this.objectMapper = objectMapper;
    }

    /**
     * Loaded before the server accepts traffic, as the routes
     */
    @Override
    public void afterSingletonsInstantiated() {
        reload().block(Duration.ofSeconds(60));
    }

    @Override
    public RateLimit ofGateway() {
        return state.gateway();
    }

    @Override
    public RateLimit ofRoute(String routeId) {
        return state.routes().get(routeId);
    }

    @Override
    public long acquire(String routeId, String clientIp) {
        State current = state;
        long now = System.nanoTime();
        //the gateway's first: a request it stops never counts for the route
        long wait = take(current, current.gateway(), GATEWAY, clientIp, now);
        if (wait == 0) wait = take(current, current.routes().get(routeId), routeId, clientIp, now);
        //rounded up: never tells to come back before the time
        return wait == 0 ? 0 : Math.max(1, (wait + 999_999_999) / 1_000_000_000);
    }

    private static long take(State current, RateLimit config, String scope, String clientIp, long now) {
        if (config == null || !config.on()) return 0;
        return current.buckets().computeIfAbsent(scope + " " + clientIp, key -> new TokenBucket(config, now)).take(now);
    }

    /**
     * Forgets the buckets that are full again: the same as a new one
     */
    @Scheduled(fixedDelay = 60_000, initialDelay = 60_000)
    public void forgetFullBuckets() {
        long now = System.nanoTime();
        state.buckets().values().removeIf(bucket -> bucket.full(now));
    }

    @Override
    public Mono<RateLimit> setGateway(RateLimit rateLimit) {
        return addonRepo.findByRouteIdIsNullAndType(RateLimit.TYPE)
                .defaultIfEmpty(newAddon(null))
                .flatMap(addon -> write(addon, rateLimit))
                .then(reload())
                .then(Mono.fromSupplier(this::ofGateway));
    }

    @Override
    public Mono<RateLimit> enableGateway(boolean enabled) {
        return addonRepo.findByRouteIdIsNullAndType(RateLimit.TYPE)
                .filter(addon -> valid(read(addon.getConfig())))
                .switchIfEmpty(Mono.error(new LocalizedException(HttpStatus.NOT_FOUND, "rate_limit.gateway.not_found")))
                .flatMap(addon -> enable(addon, enabled))
                .then(reload())
                .then(Mono.fromSupplier(this::ofGateway));
    }

    @Override
    public Mono<Void> deleteGateway() {
        return addonRepo.findByRouteIdIsNullAndType(RateLimit.TYPE)
                .flatMap(addonRepo::delete)
                .then(reload());
    }

    @Override
    public Mono<RateLimit> setRoute(String routeId, RateLimit rateLimit) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> save(route.getRouteId(), rateLimit))
                .then(reload())
                .then(Mono.fromSupplier(() -> ofRoute(routeId)));
    }

    @Override
    public Mono<RateLimit> enableRoute(String routeId, boolean enabled) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> addonRepo.findByRouteIdAndType(route.getRouteId(), RateLimit.TYPE))
                .filter(addon -> valid(read(addon.getConfig())))
                .switchIfEmpty(Mono.error(new LocalizedException(HttpStatus.NOT_FOUND, "rate_limit.route.not_found", routeId)))
                .flatMap(addon -> enable(addon, enabled))
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
    public Mono<Void> save(UUID routeId, RateLimit rateLimit) {
        Mono<AddonEntity> current = addonRepo.findByRouteIdAndType(routeId, RateLimit.TYPE);
        if (rateLimit == null) {
            return current.flatMap(addonRepo::delete);
        }
        return current.defaultIfEmpty(newAddon(routeId))
                .flatMap(addon -> write(addon, rateLimit))
                .then();
    }

    private AddonEntity newAddon(UUID routeId) {
        return new AddonEntity(null, routeId, RateLimit.TYPE, null, null, null, null);
    }

    private Mono<AddonEntity> enable(AddonEntity addon, boolean enabled) {
        RateLimit current = read(addon.getConfig());
        return write(addon, new RateLimit(enabled, current.limit(), current.period(), current.burst()));
    }

    /**
     * Saves the config; a rate limit has no state of its own (the counts are in memory)
     */
    private Mono<AddonEntity> write(AddonEntity addon, RateLimit rateLimit) {
        OffsetDateTime now = OffsetDateTime.now().truncatedTo(ChronoUnit.MICROS);
        addon.setConfig(new AddonJson(objectMapper.writeValueAsString(rateLimit)));
        if (addon.getCreatedAt() == null) addon.setCreatedAt(now);
        addon.setUpdatedAt(now);
        return addonRepo.save(addon);
    }

    //the period is checked too: an unknown one would limit by the hour without saying so
    private static boolean valid(RateLimit config) {
        return config != null && config.enabled() != null && config.limit() != null && config.limit() >= 1
                && config.period() != null && config.period().matches("second|minute|hour")
                && (config.burst() == null || config.burst() >= 1);
    }

    //null when missing or unreadable: a broken row never breaks the gateway
    private RateLimit read(AddonJson json) {
        if (json == null) return null;
        try {
            return objectMapper.readValue(json.json(), RateLimit.class);
        } catch (RuntimeException e) {
            return null;
        }
    }

    @Override
    public Mono<Void> reload() {
        return addonRepo.findByType(RateLimit.TYPE)
                .collectList()
                .doOnNext(addons -> {
                    RateLimit gateway = null;
                    Map<String, RateLimit> routes = new HashMap<>();
                    for (AddonEntity addon : addons) {
                        RateLimit config = read(addon.getConfig());
                        if (!valid(config)) {
                            //never stops the startup: a broken row is skipped, as if it wasn't configured
                            log.warn("Skipping the rate limit add-on {}: its config can't be read", addon.getAddonId());
                            continue;
                        }
                        if (addon.getRouteId() == null) {
                            gateway = config;
                        } else {
                            routes.put(addon.getRouteId().toString(), config);
                        }
                    }
                    state = new State(gateway, Map.copyOf(routes), new ConcurrentHashMap<>());
                })
                .then();
    }
}
