package dev.root101.api_gateway.core.feature.addons.base.logic.usecase;

import dev.root101.api_gateway.core.feature.addons.base.logic.model.Addons;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.AddonsRequest;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.GatewayAddons;
import dev.root101.api_gateway.core.feature.addons.cors.logic.model.Cors;
import dev.root101.api_gateway.core.feature.addons.cors.logic.usecase.CorsUseCase;
import dev.root101.api_gateway.core.feature.addons.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.core.feature.addons.health_check.logic.usecase.HealthCheckUseCase;
import dev.root101.api_gateway.core.feature.addons.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.core.feature.addons.maintenance.logic.usecase.MaintenanceUseCase;
import dev.root101.api_gateway.core.feature.addons.rate_limit.logic.model.RateLimit;
import dev.root101.api_gateway.core.feature.addons.rate_limit.logic.usecase.RateLimitUseCase;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Locale;
import java.util.UUID;

@Service
class AddonsUseCase_Impl implements AddonsUseCase {

    private final MaintenanceUseCase maintenanceUseCase;
    private final HealthCheckUseCase healthCheckUseCase;
    private final RateLimitUseCase rateLimitUseCase;
    private final CorsUseCase corsUseCase;

    AddonsUseCase_Impl(MaintenanceUseCase maintenanceUseCase, HealthCheckUseCase healthCheckUseCase, RateLimitUseCase rateLimitUseCase, CorsUseCase corsUseCase) {
        this.maintenanceUseCase = maintenanceUseCase;
        this.healthCheckUseCase = healthCheckUseCase;
        this.rateLimitUseCase = rateLimitUseCase;
        this.corsUseCase = corsUseCase;
    }

    @Override
    public GatewayAddons ofGateway(Locale locale) {
        return new GatewayAddons(maintenanceUseCase.ofGateway(locale), rateLimitUseCase.ofGateway(), corsUseCase.gatewayResponse());
    }

    @Override
    public Addons ofRoute(String routeId, Locale locale) {
        return new Addons(maintenanceUseCase.ofRoute(routeId, locale), healthCheckUseCase.ofRoute(routeId), rateLimitUseCase.ofRoute(routeId), corsUseCase.ofRoute(routeId));
    }

    @Override
    public Mono<Void> restore(UUID routeId, AddonsRequest addons) {
        if (addons == null) return Mono.empty();
        Mono<Void> maintenance = addons.sent(Maintenance.TYPE) ? maintenanceUseCase.save(routeId, addons.getMaintenance()) : Mono.empty();
        Mono<Void> healthCheck = addons.sent(HealthCheck.TYPE) ? healthCheckUseCase.save(routeId, addons.getHealthCheck()) : Mono.empty();
        Mono<Void> rateLimit = addons.sent(RateLimit.TYPE) ? rateLimitUseCase.save(routeId, addons.getRateLimit()) : Mono.empty();
        Mono<Void> cors = addons.sent(Cors.TYPE) ? corsUseCase.save(routeId, addons.getCors()) : Mono.empty();
        return maintenance.then(healthCheck).then(rateLimit).then(cors);
    }

    @Override
    public Mono<Void> uriChanged(String routeId) {
        return Mono.defer(() -> healthCheckUseCase.ofRoute(routeId) == null ? Mono.empty() : healthCheckUseCase.run(routeId).then());
    }

    @Override
    public Mono<Void> reload() {
        return maintenanceUseCase.reload().then(healthCheckUseCase.reload()).then(rateLimitUseCase.reload()).then(corsUseCase.reload());
    }
}
