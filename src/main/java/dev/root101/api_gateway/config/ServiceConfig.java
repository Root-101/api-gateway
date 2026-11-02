package dev.root101.api_gateway.config;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.SerializationFeature;
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
    public ObjectMapper objectMapper(PropertyNamingStrategies.NamingBase namingStrategy) {
        return new ObjectMapper()
                .findAndRegisterModules()
                .configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false)
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
                .setPropertyNamingStrategy(namingStrategy);
    }

    @Bean
    public ValidationService validationService(PropertyNamingStrategies.NamingBase namingStrategy) {
        return ValidationService.builder()
                .namingStrategy(namingStrategy)
                .build();
    }

}
