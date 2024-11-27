package dev.root101.api_gateway.config;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.SerializationFeature;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;

@Service
public class ServiceConfig {

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
