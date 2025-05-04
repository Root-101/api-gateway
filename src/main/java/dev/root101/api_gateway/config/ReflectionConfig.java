package dev.root101.api_gateway.config;

import dev.root101.api_gateway.feature.model.RewritePath;
import dev.root101.api_gateway.feature.model.RouteConfigRequest;
import dev.root101.api_gateway.feature.model.RouteConfigResponse;
import dev.root101.commons.validation.annotations.EnumValidatorRegister_ListOfString;
import dev.root101.commons.validation.annotations.EnumValidatorRegister_String;
import dev.root101.commons.validation.annotations.SortRegister;
import org.springframework.aot.hint.annotation.RegisterReflectionForBinding;
import org.springframework.context.annotation.Configuration;

import java.time.OffsetDateTime;

@Configuration
@RegisterReflectionForBinding({
        //--------- COMMONS ---------\\
        SortRegister.class, EnumValidatorRegister_ListOfString.class, EnumValidatorRegister_String.class,
        //--------- MODEL ---------\\
        RewritePath.class, RouteConfigRequest.class, RouteConfigResponse.class,
        OffsetDateTime.class
})
public class ReflectionConfig {
}