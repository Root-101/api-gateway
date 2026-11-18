package dev.root101.api_gateway.features.maintenance.logic.usecase;

import dev.root101.api_gateway.config.LocalizedException;
import dev.root101.api_gateway.features.addons.data.entity.AddonEntity;
import dev.root101.api_gateway.features.addons.data.entity.AddonJson;
import dev.root101.api_gateway.features.addons.data.repo.AddonRepo;
import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.maintenance.logic.model.MaintenanceResponse;
import dev.root101.api_gateway.features.maintenance.logic.model.MaintenanceState;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.context.MessageSource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import tools.jackson.databind.ObjectMapper;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * The maintenance of the gateway and of each route, kept in memory: every proxied request reads it. Changes made by
 * another instance are not seen until a restart (as the routes).
 */
@Service
class MaintenanceUseCaseImpl implements MaintenanceUseCase, SmartInitializingSingleton {

    private static final Logger log = LoggerFactory.getLogger(MaintenanceUseCaseImpl.class);

    private final AddonRepo addonRepo;
    private final RouteRepo routeRepo;
    private final ObjectMapper objectMapper;
    private final MessageSource messages;

    //replaced as a whole on each reload: a request never sees half of it
    private volatile State state = new State(null, Map.of());

    private record Entry(Maintenance config, MaintenanceState state) {
    }

    private record State(Entry gateway, Map<String, Entry> routes) {
    }

    MaintenanceUseCaseImpl(AddonRepo addonRepo, RouteRepo routeRepo, ObjectMapper objectMapper, MessageSource messages) {
        this.addonRepo = addonRepo;
        this.routeRepo = routeRepo;
        this.objectMapper = objectMapper;
        this.messages = messages;
    }

    /**
     * Loaded before the server accepts traffic, as the routes: a route in maintenance never answers after a deploy
     */
    @Override
    public void afterSingletonsInstantiated() {
        reload().block(Duration.ofSeconds(60));
    }

    @Override
    public MaintenanceResponse ofGateway(Locale locale) {
        return response(state.gateway(), locale);
    }

    @Override
    public MaintenanceResponse ofRoute(String routeId, Locale locale) {
        return response(state.routes().get(routeId), locale);
    }

    private MaintenanceResponse response(Entry entry, Locale locale) {
        if (entry == null) return null;
        Maintenance config = entry.config();
        return new MaintenanceResponse(
                config.enabled(),
                config.message(),
                config.retryAfter(),
                messages.getMessage("maintenance.default", null, locale),
                entry.state()
        );
    }

    @Override
    public Maintenance active(String routeId) {
        State current = state;
        if (current.gateway() != null && current.gateway().config().on()) return current.gateway().config();
        Entry route = current.routes().get(routeId);
        return route != null && route.config().on() ? route.config() : null;
    }

    @Override
    public Mono<MaintenanceResponse> setGateway(Maintenance maintenance, Locale locale) {
        return addonRepo.findByRouteIdIsNullAndType(Maintenance.TYPE)
                .defaultIfEmpty(newAddon(null))
                .flatMap(addon -> write(addon, maintenance))
                .then(reload())
                .then(Mono.fromSupplier(() -> ofGateway(locale)));
    }

    @Override
    public Mono<MaintenanceResponse> enableGateway(boolean enabled, Locale locale) {
        return addonRepo.findByRouteIdIsNullAndType(Maintenance.TYPE)
                .switchIfEmpty(Mono.error(new LocalizedException(HttpStatus.NOT_FOUND, "maintenance.gateway.not_found")))
                .flatMap(addon -> enable(addon, enabled))
                .then(reload())
                .then(Mono.fromSupplier(() -> ofGateway(locale)));
    }

    @Override
    public Mono<Void> deleteGateway() {
        return addonRepo.findByRouteIdIsNullAndType(Maintenance.TYPE)
                .flatMap(addonRepo::delete)
                .then(reload());
    }

    @Override
    public Mono<MaintenanceResponse> setRoute(String routeId, Maintenance maintenance, Locale locale) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> save(route.getRouteId(), maintenance))
                .then(reload())
                .then(Mono.fromSupplier(() -> ofRoute(routeId, locale)));
    }

    @Override
    public Mono<MaintenanceResponse> enableRoute(String routeId, boolean enabled, Locale locale) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> addonRepo.findByRouteIdAndType(route.getRouteId(), Maintenance.TYPE)
                        .switchIfEmpty(Mono.error(new LocalizedException(HttpStatus.NOT_FOUND, "maintenance.route.not_found", routeId))))
                .flatMap(addon -> enable(addon, enabled))
                .then(reload())
                .then(Mono.fromSupplier(() -> ofRoute(routeId, locale)));
    }

    @Override
    public Mono<Void> deleteRoute(String routeId) {
        return routeRepo.findExisting(routeId)
                .flatMap(route -> save(route.getRouteId(), null))
                .then(reload());
    }

    @Override
    public Mono<Void> save(UUID routeId, Maintenance maintenance) {
        Mono<AddonEntity> current = addonRepo.findByRouteIdAndType(routeId, Maintenance.TYPE);
        if (maintenance == null) {
            return current.flatMap(addonRepo::delete);
        }
        return current.defaultIfEmpty(newAddon(routeId))
                .flatMap(addon -> write(addon, maintenance))
                .then();
    }

    private AddonEntity newAddon(UUID routeId) {
        return new AddonEntity(null, routeId, Maintenance.TYPE, null, null, null, null);
    }

    //a row that can't be read (broken by hand) is as if it wasn't configured
    private Mono<AddonEntity> enable(AddonEntity addon, boolean enabled) {
        Maintenance current = read(addon.getConfig(), Maintenance.class);
        if (current == null || current.enabled() == null) {
            return addon.getRouteId() == null
                    ? Mono.error(new LocalizedException(HttpStatus.NOT_FOUND, "maintenance.gateway.not_found"))
                    : Mono.error(new LocalizedException(HttpStatus.NOT_FOUND, "maintenance.route.not_found", addon.getRouteId()));
        }
        return write(addon, new Maintenance(enabled, current.message(), current.retryAfter()));
    }

    /**
     * Saves the config, and the time in the state when `enabled` really changes
     */
    private Mono<AddonEntity> write(AddonEntity addon, Maintenance maintenance) {
        OffsetDateTime now = OffsetDateTime.now().truncatedTo(ChronoUnit.MICROS);
        Maintenance before = read(addon.getConfig(), Maintenance.class);
        MaintenanceState times = read(addon.getState(), MaintenanceState.class);
        if (times == null) times = MaintenanceState.NONE;

        boolean wasOn = before != null && before.on();
        if (!wasOn && maintenance.on()) times = new MaintenanceState(now, times.disabledAt());
        if (wasOn && !maintenance.on()) times = new MaintenanceState(times.enabledAt(), now);

        addon.setConfig(new AddonJson(objectMapper.writeValueAsString(maintenance)));
        addon.setState(times.equals(MaintenanceState.NONE) ? null : new AddonJson(objectMapper.writeValueAsString(times)));
        if (addon.getCreatedAt() == null) addon.setCreatedAt(now);
        addon.setUpdatedAt(now);
        return addonRepo.save(addon);
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
        return addonRepo.findByType(Maintenance.TYPE)
                .collectList()
                .doOnNext(addons -> {
                    Entry gateway = null;
                    Map<String, Entry> routes = new HashMap<>();
                    for (AddonEntity addon : addons) {
                        Maintenance config = read(addon.getConfig(), Maintenance.class);
                        if (config == null || config.enabled() == null) {
                            //never stops the startup: a broken row is skipped, as if it wasn't configured
                            log.warn("Skipping the maintenance add-on {}: its config can't be read", addon.getAddonId());
                            continue;
                        }
                        MaintenanceState times = read(addon.getState(), MaintenanceState.class);
                        Entry entry = new Entry(config, times != null ? times : MaintenanceState.NONE);
                        if (addon.getRouteId() == null) {
                            gateway = entry;
                        } else {
                            routes.put(addon.getRouteId().toString(), entry);
                        }
                    }
                    state = new State(gateway, Map.copyOf(routes));
                })
                .then();
    }
}
