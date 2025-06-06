package dev.root101.api_gateway.config;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
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
        ValidationException.class, ValidationException.ValidationErrorMessage.class, SortRegister.class, EnumValidatorRegister_ListOfString.class, EnumValidatorRegister_String.class,
        //--------- ROUTES ---------\\
        RewritePathModel.class, RouteConfigRequest.class, RouteConfigResponse.class,
        OffsetDateTime.class,
        //--------- ROUTES ---------\\
        LoginRequest.class
})
public class ReflectionConfig {
}