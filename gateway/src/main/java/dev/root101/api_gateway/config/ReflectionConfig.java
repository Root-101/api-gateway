package dev.root101.api_gateway.config;

import dev.root101.api_gateway.core.feature.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.core.feature.auth.logic.model.LoginResponse;
import dev.root101.api_gateway.core.feature.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.core.feature.http_logs.logic.model.HttpLogResponse;
import dev.root101.api_gateway.core.feature.http_logs.logic.model.SearchHttpLogResponse;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.Addons;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.AddonsRequest;
import dev.root101.api_gateway.core.feature.addons.base.logic.model.GatewayAddons;
import dev.root101.api_gateway.core.feature.addons.cors.logic.model.Cors;
import dev.root101.api_gateway.core.feature.addons.cors.logic.model.CorsResponse;
import dev.root101.api_gateway.core.feature.addons.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.core.feature.addons.health_check.logic.model.HealthCheckResponse;
import dev.root101.api_gateway.core.feature.addons.health_check.logic.model.HealthCheckState;
import dev.root101.api_gateway.core.feature.addons.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.core.feature.addons.maintenance.logic.model.MaintenanceResponse;
import dev.root101.api_gateway.core.feature.addons.maintenance.logic.model.MaintenanceState;
import dev.root101.api_gateway.core.feature.addons.rate_limit.logic.model.RateLimit;
import dev.root101.api_gateway.core.feature.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteRequest;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteResponse;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteRules;
import org.springframework.aot.hint.annotation.RegisterReflectionForBinding;
import org.springframework.context.annotation.Configuration;

import java.time.OffsetDateTime;

@Configuration
//the deprecated CorsResponse.EnvVar still needs its hints until 7.0
@SuppressWarnings("removal")
@RegisterReflectionForBinding({
        //--------- CONFIG ---------\\
        GlobalExceptionHandlerConfig.class,
        //--------- ROUTES ---------\\
        RewritePathModel.class, RouteRequest.class, RouteResponse.class,
        //the validator of @ValidRoute, created by hibernate validator
        RouteRules.class,
        OffsetDateTime.class,
        //--------- ADD-ONS ---------\\
        Addons.class, GatewayAddons.class, AddonsRequest.class,
        //also written to and read from the db as json
        Maintenance.class, MaintenanceState.class, MaintenanceResponse.class,
        HealthCheck.class, HealthCheckState.class, HealthCheckResponse.class,
        RateLimit.class, Cors.class, CorsResponse.class, CorsResponse.EnvVar.class,
        //--------- AUTH ---------\\
        LoginRequest.class, LoginResponse.class,
        //--------- HTTP LOGS ---------\\
        SearchHttpLogResponse.class, HttpLogResponse.class, HttpLogEntity.RouteLog.class,
        //--------- Flyway ---------\\
        org.flywaydb.database.postgresql.TransactionalModel.class,
        //--------- CLOUD ---------\\
        //the gateway's load balancer auto-configuration is read by reflection at startup (see build.gradle)
        org.springframework.cloud.client.loadbalancer.reactive.ReactiveLoadBalancer.class,
})
public class ReflectionConfig {
}