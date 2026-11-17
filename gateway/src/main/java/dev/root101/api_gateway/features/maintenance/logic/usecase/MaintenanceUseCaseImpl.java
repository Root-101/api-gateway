package dev.root101.api_gateway.features.maintenance.logic.usecase;

import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.settings.data.entity.SettingEntity;
import dev.root101.api_gateway.features.settings.data.entity.SettingValue;
import dev.root101.api_gateway.features.settings.data.repo.SettingRepo;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import tools.jackson.databind.ObjectMapper;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * The maintenance of the gateway and of each route, kept in memory: every proxied request reads it. Changes made by
 * another instance are not seen until a restart (as the routes).
 */
@Service
class MaintenanceUseCaseImpl implements MaintenanceUseCase, SmartInitializingSingleton {

    private final SettingRepo settingRepo;
    private final ObjectMapper objectMapper;

    //replaced as a whole on each reload: a request never sees half of it
    private volatile State state = new State(null, Map.of());

    private record State(Maintenance global, Map<String, Maintenance> routes) {
    }

    MaintenanceUseCaseImpl(SettingRepo settingRepo, ObjectMapper objectMapper) {
        this.settingRepo = settingRepo;
        this.objectMapper = objectMapper;
    }

    /**
     * Loaded before the server accepts traffic, as the routes: a route in maintenance never answers after a deploy
     */
    @Override
    public void afterSingletonsInstantiated() {
        reload().block(Duration.ofSeconds(60));
    }

    @Override
    public Maintenance global() {
        return state.global();
    }

    @Override
    public Mono<Maintenance> setGlobal(Maintenance maintenance) {
        return settingRepo.findByRouteIdIsNullAndKey(Maintenance.KEY)
                .defaultIfEmpty(new SettingEntity(null, null, Maintenance.KEY, null, null))
                .flatMap(setting -> write(setting, maintenance))
                .then(reload())
                .thenReturn(maintenance);
    }

    @Override
    public Maintenance ofRoute(String routeId) {
        return state.routes().get(routeId);
    }

    @Override
    public Maintenance active(String routeId) {
        State current = state;
        Maintenance route = current.routes().get(routeId);
        if (route != null && route.on()) return route;
        return current.global() != null && current.global().on() ? current.global() : null;
    }

    @Override
    public Mono<Void> save(UUID routeId, Maintenance maintenance) {
        return settingRepo.findByRouteIdAndKey(routeId, Maintenance.KEY)
                .defaultIfEmpty(new SettingEntity(null, routeId, Maintenance.KEY, null, null))
                .flatMap(setting -> write(setting, maintenance))
                .then();
    }

    private Mono<SettingEntity> write(SettingEntity setting, Maintenance maintenance) {
        setting.setValue(new SettingValue(objectMapper.writeValueAsString(maintenance)));
        setting.setUpdatedAt(OffsetDateTime.now().truncatedTo(ChronoUnit.MICROS));
        return settingRepo.save(setting);
    }

    @Override
    public Mono<Void> reload() {
        return settingRepo.findByKey(Maintenance.KEY)
                .collectList()
                .doOnNext(settings -> {
                    Maintenance global = null;
                    Map<String, Maintenance> routes = new HashMap<>();
                    for (SettingEntity setting : settings) {
                        Maintenance maintenance = objectMapper.readValue(setting.getValue().json(), Maintenance.class);
                        if (setting.getRouteId() == null) {
                            global = maintenance;
                        } else {
                            routes.put(setting.getRouteId().toString(), maintenance);
                        }
                    }
                    state = new State(global, Map.copyOf(routes));
                })
                .then();
    }
}
