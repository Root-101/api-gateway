package dev.root101.api_gateway.config;

import lombok.extern.slf4j.Slf4j;
import io.netty.channel.ConnectTimeoutException;
import org.springframework.boot.webflux.error.ErrorWebExceptionHandler;
import dev.root101.api_gateway.core.i18n.I18n;
import org.springframework.context.MessageSource;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import dev.root101.api_gateway.core.error.FieldProblem;
import dev.root101.api_gateway.core.validation.FieldProblems;
import org.springframework.web.ErrorResponseException;
import org.springframework.validation.method.ParameterErrors;
import org.springframework.stereotype.Component;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.support.WebExchangeBindException;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
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
import java.util.stream.Stream;
import java.util.concurrent.TimeoutException;

/**
 * Every error of the gateway as a Problem Details (RFC 9457, `application/problem+json`): `type`, `title`, `status`,
 * `detail`, `instance`, the stable `code` clients decide on (the message key without `error.`), plus `errors` in a
 * `422`. The texts are in the language of the request's `Accept-Language` (see {@link I18n}).
 */
@Slf4j
@Component
@Order(-2)
public class GlobalExceptionHandlerConfig implements ErrorWebExceptionHandler {

    private static final MediaType PROBLEM_JSON = MediaType.APPLICATION_PROBLEM_JSON;

    private static final String KEY_PREFIX = "error.";

    private final ObjectMapper objectMapper;
    private final MessageSource messages;
    private final FieldProblems fieldProblems;

    public GlobalExceptionHandlerConfig(ObjectMapper objectMapper, MessageSource messages, FieldProblems fieldProblems) {
        this.objectMapper = objectMapper;
        this.messages = messages;
        this.fieldProblems = fieldProblems;
    }

    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable rawEx) {
        if (exchange.getResponse().isCommitted()) {
            //status and headers already sent (ej: upstream failed mid-body), nothing we can write
            return Mono.error(rawEx);
        }
        Locale locale = I18n.locale(exchange);
        HttpStatusCode status;
        String key;
        Object[] args = {};
        String detail = null;
        List<FieldProblem> errors = null;

        switch (rawEx) {
            //`@Valid` on a body: its fields
            case WebExchangeBindException ex -> {
                status = HttpStatus.UNPROCESSABLE_CONTENT;
                key = "error.validation";
                errors = fieldProblems.of(ex.getFieldErrors(), null, locale);
            }
            //`@Valid` on a list body: the fields of each element, `#/0/name`
            case HandlerMethodValidationException ex -> {
                status = HttpStatus.UNPROCESSABLE_CONTENT;
                key = "error.validation";
                errors = ex.getParameterValidationResults().stream()
                        .flatMap(result -> result instanceof ParameterErrors parameterErrors
                                ? fieldProblems.of(parameterErrors.getFieldErrors(), parameterErrors.getContainerIndex(), locale).stream()
                                : Stream.empty())
                        .toList();
            }
            //unique constraints (ej: route name in a race condition)
            case DataIntegrityViolationException ex -> {
                status = HttpStatus.CONFLICT;
                key = "error.conflict";
            }
            //a path that no route matches (and isn't an admin endpoint): don't expose the static resources message
            case NoResourceFoundException ex -> {
                status = HttpStatus.NOT_FOUND;
                key = "error.no-route";
                args = new Object[]{exchange.getRequest().getPath().value()};
            }
            //the gateway's response-timeout: its message names the configured timeout
            case ResponseStatusException ex when ex.getStatusCode().value() == HttpStatus.GATEWAY_TIMEOUT.value() -> {
                status = HttpStatus.GATEWAY_TIMEOUT;
                key = "error.upstream.timeout";
            }
            case ServerWebInputException ex -> {
                status = ex.getStatusCode();
                String field = inputField(ex);
                key = field != null ? "validation.invalid-value" : notJson(ex) ? "error.bad-request" : "error.unreadable-request";
                args = new Object[]{field};
            }
            //ours (`Errors`): its detail message code is our key
            case ErrorResponseException ex when ex.getDetailMessageCode().startsWith(KEY_PREFIX) -> {
                status = ex.getStatusCode();
                key = ex.getDetailMessageCode();
                args = ex.getDetailMessageArguments();
            }
            //Spring's own (405, 415...): the generic code of the status, translated by its problemDetail.* key when
            //the messages file has it
            case ErrorResponse ex -> {
                status = ex.getStatusCode();
                key = genericKey(status);
                detail = ex.updateAndGetBody(messages, locale).getDetail();
            }
            //upstream errors: don't expose the internal host/port in the message
            case ConnectTimeoutException ex -> {
                status = HttpStatus.GATEWAY_TIMEOUT;
                key = "error.upstream.connect-timeout";
            }
            case TimeoutException ex -> {
                status = HttpStatus.GATEWAY_TIMEOUT;
                key = "error.upstream.timeout";
            }
            case ConnectException ex -> {
                status = HttpStatus.BAD_GATEWAY;
                key = "error.upstream.unreachable";
            }
            case UnknownHostException ex -> {
                status = HttpStatus.BAD_GATEWAY;
                key = "error.upstream.unreachable";
            }
            case PrematureCloseException ex -> {
                status = HttpStatus.BAD_GATEWAY;
                key = "error.upstream.closed";
            }
            default -> {
                status = HttpStatus.INTERNAL_SERVER_ERROR;
                key = "error.internal-server-error";
            }
        }

        if (status.is5xxServerError()) {
            log.error("{} on {} {}", status, exchange.getRequest().getMethod(), exchange.getRequest().getPath(), rawEx);
        }
        return write(exchange, status, locale, code(key), detail != null ? detail : text(key, locale, args), errors);
    }

    /**
     * Writes a Problem Details as the response; also used by the security layer (401, 403, 429).
     *
     * @param key  key of the messages files, written in the language of the request; without `error.` it is the `code`
     * @param args its arguments ({0}, {1}...)
     */
    public Mono<Void> writeProblem(ServerWebExchange exchange, HttpStatusCode status, String key, Object... args) {
        Locale locale = I18n.locale(exchange);
        return write(exchange, status, locale, code(key), text(key, locale, args), null);
    }

    /**
     * Writes a Problem Details with a text written by the admin (ej: the message of a maintenance), as is
     *
     * @param key the key whose `code` it answers with
     */
    public Mono<Void> writeDetail(ServerWebExchange exchange, HttpStatusCode status, String key, String detail) {
        return write(exchange, status, I18n.locale(exchange), code(key), detail, null);
    }

    private String text(String key, Locale locale, Object... args) {
        return I18n.text(messages, key, args, locale);
    }

    /**
     * The `code` of a key: without its `error.` (or `validation.`) prefix
     */
    static String code(String key) {
        return key.substring(key.indexOf('.') + 1);
    }

    /**
     * `error.method-not-allowed` for a 405: the generic key of a status without one of ours
     */
    static String genericKey(HttpStatusCode status) {
        HttpStatus known = HttpStatus.resolve(status.value());
        return KEY_PREFIX + (known != null ? known.name().toLowerCase(Locale.ROOT).replace('_', '-') : String.valueOf(status.value()));
    }

    private Mono<Void> write(ServerWebExchange exchange, HttpStatusCode status, Locale locale, String code, String detail, List<FieldProblem> errors) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("type", "about:blank");
        HttpStatus known = HttpStatus.resolve(status.value());
        String reasonPhrase = known != null ? known.getReasonPhrase() : String.valueOf(status.value());
        body.put("title", messages.getMessage("status." + status.value(), null, reasonPhrase, locale));
        body.put("status", status.value());
        if (detail != null && !detail.isBlank()) {
            body.put("detail", detail);
        }
        body.put("instance", exchange.getRequest().getPath().value());
        body.put("code", code);
        if (errors != null) {
            body.put("errors", errors);
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
     * The field that can't be read, as the client sent it, or null: Jackson's path in the body, or the name of a
     * query parameter of the wrong type. Never the Java types.
     */
    private static String inputField(ServerWebInputException ex) {
        for (Throwable cause = ex; cause != null; cause = cause.getCause()) {
            if (cause instanceof JacksonException jackson) {
                if (jackson.getPath().isEmpty()) return null;
                StringBuilder path = new StringBuilder();
                for (JacksonException.Reference ref : jackson.getPath()) {
                    if (ref.getPropertyName() != null) {
                        path.append(path.isEmpty() ? "" : ".").append(ref.getPropertyName());
                    } else if (ref.getIndex() >= 0) {
                        path.append('[').append(ref.getIndex()).append(']');
                    }
                }
                return path.toString();
            }
        }
        //a query parameter of the wrong type (ej: `from=yesterday`): name it
        if (ex.getMethodParameter() != null && ex.getMethodParameter().getParameterName() != null) {
            RequestParam param = ex.getMethodParameter().getParameterAnnotation(RequestParam.class);
            return param != null && !param.name().isEmpty() ? param.name() : ex.getMethodParameter().getParameterName();
        }
        return null;
    }

    /**
     * Whether the body isn't JSON at all (Jackson failed with no field to name)
     */
    private static boolean notJson(ServerWebInputException ex) {
        for (Throwable cause = ex; cause != null; cause = cause.getCause()) {
            if (cause instanceof JacksonException) return true;
        }
        return false;
    }
}
