package dev.root101.api_gateway.config;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.features.auth.logic.model.LoginResponse;
import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogResponse;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchResponse;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import dev.root101.commons.exceptions.ValidationException;
import dev.root101.commons.validation.annotations.EnumValidatorRegister_ListOfString;
import dev.root101.commons.validation.annotations.EnumValidatorRegister_String;
import dev.root101.commons.validation.annotations.SortRegister;
import org.springframework.aot.hint.annotation.RegisterReflectionForBinding;
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
        OffsetDateTime.class,
        //--------- AUTH ---------\\
        LoginRequest.class, LoginResponse.class,
        //--------- HTTP LOGS ---------\\
        HttpLogSearchResponse.class, HttpLogResponse.class, HttpLogEntity.RouteLog.class,
        //--------- Flyway ---------\\
        org.flywaydb.database.postgresql.TransactionalModel.class,
})
public class ReflectionConfig {
}