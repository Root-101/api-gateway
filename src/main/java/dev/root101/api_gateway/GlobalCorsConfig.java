package dev.root101.api_gateway;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
public class GlobalCorsConfig {

    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        corsConfiguration.setAllowedOriginPatterns(List.of("*"));             // Permite cualquier origen
        corsConfiguration.setAllowedMethods(List.of("*"));                    // Permite cualquier método
        corsConfiguration.setAllowedHeaders(List.of("*"));                    // Permite todos los encabezados
        corsConfiguration.setExposedHeaders(List.of("*"));                    // Permite todos los encabezados
        corsConfiguration.setAllowCredentials(true);                              // Habilita credenciales

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfiguration);

        return new CorsWebFilter(source);
    }
}