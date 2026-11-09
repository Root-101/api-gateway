package dev.root101.api_gateway.config;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.features.auth.logic.model.LoginResponse;
import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogResponse;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchResponse;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import dev.root101.api_gateway.features.routes.logic.model.RouteFilterModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteHeaderModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteRules;
import dev.root101.commons.exceptions.ValidationException;
import dev.root101.commons.validation.annotations.EnumValidatorRegister_ListOfString;
import dev.root101.commons.validation.annotations.EnumValidatorRegister_String;
import dev.root101.commons.validation.annotations.SortRegister;
import org.springframework.aot.hint.annotation.RegisterReflectionForBinding;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.cloud.gateway.filter.factory.AbstractNameValueGatewayFilterFactory;
import org.springframework.cloud.gateway.filter.factory.AddResponseHeaderGatewayFilterFactory;
import org.springframework.cloud.gateway.handler.predicate.HeaderRoutePredicateFactory;
import org.springframework.cloud.gateway.handler.predicate.HostRoutePredicateFactory;
import org.springframework.cloud.gateway.handler.predicate.MethodRoutePredicateFactory;
import org.springframework.context.annotation.Configuration;

import java.time.OffsetDateTime;

@Configuration
@RegisterReflectionForBinding({
        //--------- CONFIG ---------\\
        GlobalExceptionHandler.class,
        //--------- COMMONS ---------\\
        ValidationException.class, ValidationException.ValidationErrorMessage.class, SortRegister.class,
        EnumValidatorRegister_ListOfString.class, EnumValidatorRegister_String.class,
        //--------- ROUTES ---------\\
        RewritePathModel.class, RouteConfigRequest.class, RouteConfigResponse.class,
        RouteRules.class, RouteHeaderModel.class, RouteFilterModel.class,
        OffsetDateTime.class,
        //--------- AUTH ---------\\
        LoginRequest.class, LoginResponse.class,
        //--------- HTTP LOGS ---------\\
        HttpLogSearchRequest.class, HttpLogSearchResponse.class, HttpLogResponse.class, HttpLogEntity.RouteLog.class,
        //--------- Flyway ---------\\
        org.flywaydb.database.postgresql.TransactionalModel.class,
        //--------- CLOUD ---------\\
        org.springframework.cloud.client.loadbalancer.reactive.ReactiveLoadBalancer.class,
        //the gateway instantiates these by reflection when it builds a route with RouteConfigRequest's predicates and filters
        MethodRoutePredicateFactory.Config.class, HostRoutePredicateFactory.Config.class, HeaderRoutePredicateFactory.Config.class,
        AbstractNameValueGatewayFilterFactory.NameValueConfig.class, AbstractGatewayFilterFactory.NameConfig.class,
        AddResponseHeaderGatewayFilterFactory.Config.class,
})
public class ReflectionConfig {
}