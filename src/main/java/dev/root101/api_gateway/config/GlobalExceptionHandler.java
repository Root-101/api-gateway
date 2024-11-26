package dev.root101.api_gateway.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import dev.root101.commons.exceptions.ApiException;
import dev.root101.commons.exceptions.ValidationException;
import org.springframework.boot.web.reactive.error.ErrorWebExceptionHandler;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
@Order(-2)
public class GlobalExceptionHandler implements ErrorWebExceptionHandler {

    private final ObjectMapper om;

    public GlobalExceptionHandler(ObjectMapper om) {
        this.om = om;
    }

    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable rawEx) {
        try {
            Object body;
            HttpStatus status;

            switch (rawEx) {
                case ValidationException validationExc -> {
                    body = validationExc.getMessages();
                    status = validationExc.getStatusCode();
                }
                case ApiException apiExc -> {
                    body = apiExc.getMessage();
                    status = apiExc.status();
                }
                case HttpClientErrorException ex -> {
                    body = ex.getResponseBodyAsString();
                    status = HttpStatus.valueOf(ex.getStatusCode().value());
                }
                default -> {
                    body = rawEx.getMessage();
                    status = HttpStatus.INTERNAL_SERVER_ERROR;
                }
            }
            exchange.getResponse().setStatusCode(status);

            byte[] bytes;
            if (body instanceof String) {
                bytes = ((String) body).getBytes();
            } else {
                exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);
                bytes = om.writeValueAsString(body).getBytes();
            }

            return exchange.getResponse().writeWith(Mono.just(exchange.getResponse()
                    .bufferFactory()
                    .wrap(bytes)));
        } catch (JsonProcessingException e) {
            return Mono.empty();
        }
    }
}
