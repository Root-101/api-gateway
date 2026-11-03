package dev.root101.api_gateway.config;

import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.cfg.DateTimeFeature;
import dev.root101.commons.validation.ValidationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;


/**
 * Global/General Misc config for the server.
 * It configures:
 * - PropertyNamingStrategies.NamingBase
 * - ObjectMapper
 * - Validation Service
 */
@Configuration
public class ServiceConfig {

    private static final Logger log = LoggerFactory.getLogger(ServiceConfig.class);

    @Value("${spring.r2dbc.password}")
    private String dbPassword;

    @Value("${app.defaults.db-password}")
    private String defaultDbPassword;

    @EventListener(ApplicationReadyEvent.class)
    public void warnDefaultDbPassword() {
        if (dbPassword.equals(defaultDbPassword)) {
            log.warn("Server running with the DEFAULT db password. Set the DB_PASSWORD environment variable for any real environment");
        }
    }

    @Bean
    public PropertyNamingStrategies.NamingBase namingStrategy() {
        return new PropertyNamingStrategies.SnakeCaseStrategy();
    }

    @Bean
    public JsonMapper jsonMapper(PropertyNamingStrategies.NamingBase namingStrategy) {
        //jackson 2 defaults: same json in/out as before the jackson 3 upgrade (API contract); dates as ISO strings
        return JsonMapper.builderWithJackson2Defaults()
                .findAndAddModules()
                .disable(DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS)
                .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
                .propertyNamingStrategy(namingStrategy)
                .build();
    }

    @Bean
    public ValidationService validationService(PropertyNamingStrategies.NamingBase namingStrategy) {
        return ValidationService.builder()
                .namingStrategy(namingStrategy)
                .build();
    }

}
