package dev.root101.api_gateway.config;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.features.auth.logic.model.LoginResponse;
import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogResponse;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchResponse;
import dev.root101.api_gateway.features.addons.logic.model.Addons;
import dev.root101.api_gateway.features.addons.logic.model.AddonsRequest;
import dev.root101.api_gateway.features.addons.logic.model.GatewayAddons;
import dev.root101.api_gateway.features.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.features.health_check.logic.model.HealthCheckResponse;
import dev.root101.api_gateway.features.health_check.logic.model.HealthCheckState;
import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.maintenance.logic.model.MaintenanceResponse;
import dev.root101.api_gateway.features.maintenance.logic.model.MaintenanceState;
import dev.root101.api_gateway.features.rate_limit.logic.model.RateLimit;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import dev.root101.api_gateway.features.routes.utils.RouteRules;
import org.springframework.aot.hint.annotation.RegisterReflectionForBinding;
import org.springframework.context.annotation.Configuration;

import java.time.OffsetDateTime;

@Configuration
@RegisterReflectionForBinding({
        //--------- CONFIG ---------\\
        GlobalExceptionHandler.class,
        //--------- ROUTES ---------\\
        RewritePathModel.class, RouteConfigRequest.class, RouteConfigResponse.class,
        //the validator of @ValidRoute, created by hibernate validator
        RouteRules.class,
        OffsetDateTime.class,
        //--------- ADD-ONS ---------\\
        Addons.class, GatewayAddons.class, AddonsRequest.class,
        //also written to and read from the db as json
        Maintenance.class, MaintenanceState.class, MaintenanceResponse.class,
        HealthCheck.class, HealthCheckState.class, HealthCheckResponse.class,
        RateLimit.class,
        //--------- AUTH ---------\\
        LoginRequest.class, LoginResponse.class,
        //--------- HTTP LOGS ---------\\
        HttpLogSearchResponse.class, HttpLogResponse.class, HttpLogEntity.RouteLog.class,
        //--------- Flyway ---------\\
        org.flywaydb.database.postgresql.TransactionalModel.class,
        //--------- CLOUD ---------\\
        //the gateway's load balancer auto-configuration is read by reflection at startup (see build.gradle)
        org.springframework.cloud.client.loadbalancer.reactive.ReactiveLoadBalancer.class,
})
public class ReflectionConfig {
}