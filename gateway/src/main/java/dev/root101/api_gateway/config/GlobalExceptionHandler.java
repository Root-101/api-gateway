package dev.root101.api_gateway.config;

import dev.root101.commons.exceptions.ApiException;
import dev.root101.commons.exceptions.ValidationException;
import io.netty.channel.ConnectTimeoutException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.webflux.error.ErrorWebExceptionHandler;
import org.springframework.context.MessageSource;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.reactive.resource.NoResourceFoundException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.ServerWebInputException;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.PrematureCloseException;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

import java.net.ConnectException;
import java.net.UnknownHostException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.TimeoutException;

/**
 * Every error of the gateway as a Problem Details (RFC 9457, `application/problem+json`):
 * `type`, `title`, `status`, `detail`, `instance`, plus `violations` in a `422`. The texts are in the language of
 * the request's `Accept-Language` (see {@link I18n}).
 */
@Component
@Order(-2)
public class GlobalExceptionHandler implements ErrorWebExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private static final MediaType PROBLEM_JSON = MediaType.APPLICATION_PROBLEM_JSON;

    private final ObjectMapper objectMapper;
    private final MessageSource messages;

    public GlobalExceptionHandler(ObjectMapper objectMapper, MessageSource messages) {
        this.objectMapper = objectMapper;
        this.messages = messages;
    }

    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable rawEx) {
        if (exchange.getResponse().isCommitted()) {
            //status and headers already sent (ej: upstream failed mid-body), nothing we can write
            return Mono.error(rawEx);
        }
        Locale locale = I18n.locale(exchange);
        HttpStatusCode status;
        String detail;
        List<Map<String, String>> violations = null;

        switch (rawEx) {
            case ValidationException ex -> {
                status = ex.getStatusCode();
                detail = text("error.validation", locale);
                violations = ex.getMessages().stream()
                        .map(m -> violation(fieldName(m.source()), text(m.message(), locale)))
                        .toList();
            }
            //its message is a key of the messages files (or a plain text, kept as is)
            case ApiException ex -> {
                status = ex.status();
                detail = I18n.text(messages, ex.getMessage(), ex instanceof LocalizedException l ? l.args() : null, locale);
            }
            //unique constraints (ej: route name in a race condition)
            case DataIntegrityViolationException ex -> {
                status = HttpStatus.CONFLICT;
                detail = text("error.conflict", locale);
            }
            //a path that no route matches (and isn't an admin endpoint): don't expose the static resources message
            case NoResourceFoundException ex -> {
                status = HttpStatus.NOT_FOUND;
                detail = text("error.no_route", locale, exchange.getRequest().getPath().value());
            }
            //the gateway's response-timeout: its message names the configured timeout
            case ResponseStatusException ex when ex.getStatusCode().value() == HttpStatus.GATEWAY_TIMEOUT.value() -> {
                status = HttpStatus.GATEWAY_TIMEOUT;
                detail = text("error.upstream.timeout", locale);
            }
            case ServerWebInputException ex -> {
                status = ex.getStatusCode();
                detail = inputDetail(ex, locale);
            }
            //Spring's own (405, 415...): translated by its problemDetail.* key when the messages file has it
            case ErrorResponse ex -> {
                status = ex.getStatusCode();
                detail = ex.updateAndGetBody(messages, locale).getDetail();
            }
            //upstream errors: don't expose the internal host/port in the message
            case ConnectTimeoutException ex -> {
                status = HttpStatus.GATEWAY_TIMEOUT;
                detail = text("error.upstream.connect_timeout", locale);
            }
            case TimeoutException ex -> {
                status = HttpStatus.GATEWAY_TIMEOUT;
                detail = text("error.upstream.timeout", locale);
            }
            case ConnectException ex -> {
                status = HttpStatus.BAD_GATEWAY;
                detail = text("error.upstream.unreachable", locale);
            }
            case UnknownHostException ex -> {
                status = HttpStatus.BAD_GATEWAY;
                detail = text("error.upstream.unreachable", locale);
            }
            case PrematureCloseException ex -> {
                status = HttpStatus.BAD_GATEWAY;
                detail = text("error.upstream.closed", locale);
            }
            default -> {
                status = HttpStatus.INTERNAL_SERVER_ERROR;
                detail = text("error.internal", locale);
            }
        }

        if (status.is5xxServerError()) {
            log.error("{} on {} {}", status, exchange.getRequest().getMethod(), exchange.getRequest().getPath(), rawEx);
        }
        return write(exchange, status, locale, detail, violations);
    }

    /**
     * Writes a Problem Details as the response; also used by the security layer (401, 403, 429).
     *
     * @param key  key of the messages files, written in the language of the request
     * @param args its arguments ({0}, {1}...)
     */
    public Mono<Void> writeProblem(ServerWebExchange exchange, HttpStatusCode status, String key, Object... args) {
        Locale locale = I18n.locale(exchange);
        return write(exchange, status, locale, text(key, locale, args), null);
    }

    private String text(String key, Locale locale, Object... args) {
        return I18n.text(messages, key, args, locale);
    }

    private Mono<Void> write(ServerWebExchange exchange, HttpStatusCode status, Locale locale, String detail, List<Map<String, String>> violations) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("type", "about:blank");
        HttpStatus known = HttpStatus.resolve(status.value());
        String reasonPhrase = known != null ? known.getReasonPhrase() : String.valueOf(status.value());
        body.put("title", messages.getMessage("title." + status.value(), null, reasonPhrase, locale));
        body.put("status", status.value());
        if (detail != null && !detail.isBlank()) {
            body.put("detail", detail);
        }
        body.put("instance", exchange.getRequest().getPath().value());
        if (violations != null) {
            body.put("violations", violations);
        }

        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(status);
        response.getHeaders().setContentType(PROBLEM_JSON);
        try {
            byte[] bytes = objectMapper.writeValueAsBytes(body);
            return response.writeWith(Mono.just(response.bufferFactory().wrap(bytes)));
        } catch (JacksonException e) {
            log.error("Error writing the error response", e);
            return response.setComplete();
        }
    }

    /**
     * `fieldName` then `message`, always in that order (Map.of iterates in a random order per JVM run)
     */
    private static Map<String, String> violation(String fieldName, String message) {
        Map<String, String> violation = new LinkedHashMap<>();
        violation.put("fieldName", fieldName);
        violation.put("message", message);
        return violation;
    }

    /**
     * The JSON path of the field, as the client sent it: `rewrite_path.replace_from`, `[0].name` in a list
     */
    static String fieldName(String source) {
        return source == null ? "" : source.replaceFirst("^root(?=\\[)", "");
    }

    /**
     * What can't be read in the request, naming the field when Jackson knows it, never the Java types
     */
    private String inputDetail(ServerWebInputException ex, Locale locale) {
        for (Throwable cause = ex; cause != null; cause = cause.getCause()) {
            if (cause instanceof JacksonException jackson && !jackson.getPath().isEmpty()) {
                StringBuilder path = new StringBuilder();
                for (JacksonException.Reference ref : jackson.getPath()) {
                    if (ref.getPropertyName() != null) {
                        path.append(path.isEmpty() ? "" : ".").append(ref.getPropertyName());
                    } else if (ref.getIndex() >= 0) {
                        path.append('[').append(ref.getIndex()).append(']');
                    }
                }
                return text("error.input.field", locale, path.toString());
            }
            if (cause instanceof JacksonException) {
                return text("error.input.json", locale);
            }
        }
        //a query parameter of the wrong type (ej: ): name it
        if (ex.getMethodParameter() != null && ex.getMethodParameter().getParameterName() != null) {
            RequestParam param = ex.getMethodParameter().getParameterAnnotation(RequestParam.class);
            String name = param != null && !param.name().isEmpty() ? param.name() : ex.getMethodParameter().getParameterName();
            return text("error.input.field", locale, name);
        }
        return text("error.input.unreadable", locale);
    }
}
