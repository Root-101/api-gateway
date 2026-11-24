package dev.root101.api_gateway.config;

import lombok.extern.slf4j.Slf4j;
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.PropertyNamingStrategies;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.cfg.DateTimeFeature;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.cloud.gateway.filter.headers.TrustedProxies;
import org.springframework.context.event.EventListener;
import org.hibernate.validator.messageinterpolation.ResourceBundleMessageInterpolator;
import dev.root101.api_gateway.core.i18n.I18n;
import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;
import org.springframework.validation.beanvalidation.MessageSourceResourceBundleLocator;


/**
 * Global/General Misc config for the server.
 * It configures:
 * - PropertyNamingStrategies.NamingBase
 * - ObjectMapper
 * - Validation Service
 */
@Slf4j
@Configuration
public class ServiceConfig {

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

    /**
     * The proxies whose `X-Forwarded-*` headers are believed (`TRUSTED_PROXIES`, empty = none).
     */
    @Bean
    public TrustedProxies trustedProxies(@Value("${spring.cloud.gateway.server.webflux.trusted-proxies:}") String regex) {
        return regex.isBlank() ? ip -> false : TrustedProxies.from(regex);
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

    /**
     * The bean validation of `@Valid` (replaces Spring Boot's): constraint messages from messages*.properties, in
     * every language, and the error handler picks the one of the request (see I18n). Primary: the gateway looks up
     * a single Spring Validator to check the route definitions (WebFlux registers another one)
     */
    @Bean
    @Primary
    public LocalValidatorFactoryBean defaultValidator(MessageSource messageSource) {
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.setMessageInterpolator(I18n.everyLanguage(
                new ResourceBundleMessageInterpolator(new MessageSourceResourceBundleLocator(messageSource))));
        return validator;
    }

}
