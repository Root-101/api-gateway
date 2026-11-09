package dev.root101.api_gateway.config;

import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;
import dev.root101.commons.exceptions.ApiException;
import dev.root101.commons.exceptions.ValidationException;
import io.netty.channel.ConnectTimeoutException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.webflux.error.ErrorWebExceptionHandler;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.ErrorResponse;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.PrematureCloseException;

import java.net.ConnectException;
import java.net.UnknownHostException;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeoutException;

/**
 * Global exception handler for the gateway.
 * Allow parse exceptions to correct http code response
 */
@Component
@Order(-2)
public class GlobalExceptionHandler implements ErrorWebExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private final ObjectMapper objectMapper;

    public GlobalExceptionHandler(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable rawEx) {
        ServerHttpResponse response = exchange.getResponse();
        if (response.isCommitted()) {
            //status and headers already sent (ej: upstream failed mid-body), nothing we can write
            return Mono.error(rawEx);
        }
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
                //unique constraints (ej: route name in a race condition)
                case DataIntegrityViolationException ex -> {
                    body = "Conflict with existing data";
                    status = HttpStatus.CONFLICT;
                }
                case HttpClientErrorException ex -> {
                    body = ex.getResponseBodyAsString();
                    status = HttpStatus.valueOf(ex.getStatusCode().value());
                }
                case ErrorResponse error -> {
                    body = error.getBody();
                    status = HttpStatus.valueOf(error.getStatusCode().value());
                }
                //upstream errors: don't expose the internal host/port in the message
                case ConnectTimeoutException ex -> {
                    body = "Gateway timeout";
                    status = HttpStatus.GATEWAY_TIMEOUT;
                }
                case TimeoutException ex -> {
                    body = "Gateway timeout";
                    status = HttpStatus.GATEWAY_TIMEOUT;
                }
                case ConnectException ex -> {
                    body = "Bad gateway";
                    status = HttpStatus.BAD_GATEWAY;
                }
                case UnknownHostException ex -> {
                    body = "Bad gateway";
                    status = HttpStatus.BAD_GATEWAY;
                }
                case PrematureCloseException ex -> {
                    body = "Bad gateway";
                    status = HttpStatus.BAD_GATEWAY;
                }
                default -> {
                    body = "Internal server error";
                    status = HttpStatus.INTERNAL_SERVER_ERROR;
                }
            }

            if (status.is5xxServerError()) {
                log.error("{} on {} {}", status, exchange.getRequest().getMethod(), exchange.getRequest().getPath(), rawEx);
            }

            response.setStatusCode(status);

            byte[] bytes;
            if (body instanceof String text) {
                response.getHeaders().setContentType(new MediaType(MediaType.TEXT_PLAIN, StandardCharsets.UTF_8));
                bytes = text.getBytes(StandardCharsets.UTF_8);
            } else {
                response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
                bytes = objectMapper.writeValueAsBytes(body);
            }

            return response.writeWith(Mono.just(response.bufferFactory().wrap(bytes)));
        } catch (JacksonException e) {
            log.error("Error writing the error response", e);
            return Mono.error(rawEx);
        }
    }
}
