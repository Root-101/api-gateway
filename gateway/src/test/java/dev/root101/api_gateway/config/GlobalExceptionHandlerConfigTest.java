package dev.root101.api_gateway.config;

import tools.jackson.databind.json.JsonMapper;
import io.netty.channel.ConnectTimeoutException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteRequest;
import org.springframework.core.MethodParameter;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;
import org.springframework.web.bind.support.WebExchangeBindException;
import org.springframework.context.support.ResourceBundleMessageSource;
import org.springframework.dao.DataIntegrityViolationException;
import tools.jackson.databind.PropertyNamingStrategies;
import org.springframework.web.server.ResponseStatusException;

import java.net.ConnectException;
import java.net.UnknownHostException;
import java.util.concurrent.TimeoutException;
import java.util.stream.Stream;
import dev.root101.api_gateway.core.error.Errors;
import dev.root101.api_gateway.core.validation.FieldProblems;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.web.ErrorResponseException;
import org.springframework.http.MediaType;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;
import reactor.test.StepVerifier;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerConfigTest {

    //as Spring Boot sets it up (spring.messages.*)
    static final ResourceBundleMessageSource MESSAGES = new ResourceBundleMessageSource();

    static {
        MESSAGES.setBasename("messages");
        MESSAGES.setDefaultEncoding("UTF-8");
        MESSAGES.setFallbackToSystemLocale(false);
    }

    private static final FieldProblems FIELD_PROBLEMS = new FieldProblems(MESSAGES, new PropertyNamingStrategies.SnakeCaseStrategy());

    private final GlobalExceptionHandlerConfig handler = new GlobalExceptionHandlerConfig(JsonMapper.builderWithJackson2Defaults().build(), MESSAGES, FIELD_PROBLEMS);

    private MockServerWebExchange exchange() {
        return MockServerWebExchange.from(MockServerHttpRequest.get("/any"));
    }

    private String body(Throwable error, String acceptLanguage) {
        MockServerWebExchange exchange = MockServerWebExchange.from(MockServerHttpRequest.get("/any").header("Accept-Language", acceptLanguage));
        handler.handle(exchange, error).block();
        return exchange.getResponse().getBodyAsString().block();
    }

    @Test
    void unexpectedErrorDoesNotLeakItsMessage() {
        MockServerWebExchange exchange = exchange();

        StepVerifier.create(handler.handle(exchange, new IllegalStateException("password authentication failed for user \"postgres\"")))
                .verifyComplete();

        assertThat(exchange.getResponse().getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(exchange.getResponse().getHeaders().getContentType()).isEqualTo(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(exchange.getResponse().getBodyAsString().block()).isEqualTo(
                "{\"type\":\"about:blank\",\"title\":\"Internal Server Error\",\"status\":500,\"detail\":\"Internal server error\",\"instance\":\"/any\",\"code\":\"internal-server-error\"}");
    }

    @Test
    void committedResponseIsLeftAlone() {
        MockServerWebExchange exchange = exchange();
        exchange.getResponse().setComplete().block();
        IOException error = new IOException("connection reset");

        StepVerifier.create(handler.handle(exchange, error))
                .verifyErrorMatches(e -> e == error);
    }

    private MockServerWebExchange handled(Throwable error) {
        MockServerWebExchange exchange = exchange();
        handler.handle(exchange, error).block();
        return exchange;
    }

    @ParameterizedTest
    @MethodSource("errors")
    void statusAndBodyPerException(Throwable error, HttpStatus status, String body) {
        MockServerWebExchange exchange = handled(error);

        assertThat(exchange.getResponse().getStatusCode().value()).isEqualTo(status.value());
        assertThat(exchange.getResponse().getBodyAsString().block()).contains(body);
    }

    static Stream<Arguments> errors() {
        return Stream.of(
                Arguments.of(Errors.notFound("error.route.not-found", "x"), HttpStatus.NOT_FOUND, "Route does not exist: x"),
                Arguments.of(new DataIntegrityViolationException("duplicate key value violates unique constraint \"unique_route_name\""),
                        HttpStatus.CONFLICT, "Conflict with existing data"),
                Arguments.of(new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Too many"), HttpStatus.TOO_MANY_REQUESTS, "\"detail\":\"Too many\""),
                Arguments.of(new ConnectException("Connection refused: /10.0.0.5:8081"), HttpStatus.BAD_GATEWAY, "The service can't be reached"),
                Arguments.of(new UnknownHostException("internal-host"), HttpStatus.BAD_GATEWAY, "The service can't be reached"),
                Arguments.of(new ConnectTimeoutException("connection timed out: /10.0.0.5:8081"), HttpStatus.GATEWAY_TIMEOUT, "The service didn't connect in time"),
                Arguments.of(new TimeoutException("Did not observe any item"), HttpStatus.GATEWAY_TIMEOUT, "The service didn't answer in time")
        );
    }

    @Test
    void upstreamErrorsDontLeakTheHost() {
        assertThat(handled(new ConnectException("Connection refused: /10.0.0.5:8081")).getResponse().getBodyAsString().block())
                .doesNotContain("10.0.0.5");
    }

    @Test
    void detailIsUtf8() {
        MockServerWebExchange exchange = exchange();

        handler.handle(exchange, Errors.conflict("error.route.name-taken", "ñ")).block();

        assertThat(exchange.getResponse().getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(exchange.getResponse().getBodyAsString().block()).contains("\"detail\":\"Route already exists: ñ\"");
    }

    @Test
    void textsInTheLanguageOfTheRequest() {
        ErrorResponseException notFound = Errors.notFound("error.route.not-found", "x");

        assertThat(body(notFound, "es")).contains("\"title\":\"No encontrado\"", "\"detail\":\"La ruta no existe: x\"");
        assertThat(body(notFound, "es-ES,es;q=0.9")).contains("La ruta no existe: x");
        assertThat(body(notFound, "en")).contains("\"title\":\"Not Found\"", "\"detail\":\"Route does not exist: x\"");
        //a language without its file, or no header: English
        assertThat(body(notFound, "fr")).contains("Route does not exist: x");
        assertThat(handled(notFound).getResponse().getBodyAsString().block()).contains("Route does not exist: x");
    }

    @Test
    void validationMessagesInTheLanguageOfTheRequest() throws NoSuchMethodException {
        //the validator as ServiceConfig builds it, and the error of a `@Valid` body
        LocalValidatorFactoryBean validator = new ServiceConfig().defaultValidator(MESSAGES);
        validator.afterPropertiesSet();
        RouteRequest route = new RouteRequest("", "/a/**", "http://a" + "a".repeat(255), null, null, null);
        BeanPropertyBindingResult result = new BeanPropertyBindingResult(route, "route");
        validator.validate(route, result);
        WebExchangeBindException error = new WebExchangeBindException(new MethodParameter(Object.class.getMethod("equals", Object.class), 0), result);

        assertThat(body(error, "es")).contains(
                "\"detail\":\"La petición tiene campos inválidos\"",
                "\"code\":\"validation\"",
                "{\"pointer\":\"#/name\",\"code\":\"not-blank\",\"detail\":\"No puede estar vacío\",\"params\":{}}",
                "{\"pointer\":\"#/uri\",\"code\":\"size\",\"detail\":\"Debe tener entre 0 y 255 caracteres\",\"params\":{\"max\":255,\"min\":0}}");
        assertThat(body(error, "en")).contains(
                "{\"pointer\":\"#/name\",\"code\":\"not-blank\",\"detail\":\"Must not be blank\",\"params\":{}}",
                "{\"pointer\":\"#/uri\",\"code\":\"size\",\"detail\":\"Size must be between 0 and 255\",\"params\":{\"max\":255,\"min\":0}}");
    }

    @Test
    void pointersAsInTheJson() {
        assertThat(FIELD_PROBLEMS.pointer("name", null)).isEqualTo("#/name");
        assertThat(FIELD_PROBLEMS.pointer("rewritePath.replaceFrom", null)).isEqualTo("#/rewrite_path/replace_from");
        assertThat(FIELD_PROBLEMS.pointer("allowedOrigins[1]", null)).isEqualTo("#/allowed_origins/1");
        assertThat(FIELD_PROBLEMS.pointer("name", 2)).isEqualTo("#/2/name");
    }

    @Test
    void codeIsTheKeyWithoutItsPrefix() {
        assertThat(body(Errors.notFound("error.route.not-found", "x"), "en")).contains("\"code\":\"route.not-found\"");
        assertThat(body(new DataIntegrityViolationException("dup"), "en")).contains("\"code\":\"conflict\"");
        assertThat(body(new ConnectException("refused"), "en")).contains("\"code\":\"upstream.unreachable\"");
        assertThat(body(new IllegalStateException("bug"), "en")).contains("\"code\":\"internal-server-error\"");
        //Spring's own: the generic code of its status
        assertThat(body(new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Too many"), "en")).contains("\"code\":\"too-many-requests\"");
        assertThat(body(new ResponseStatusException(HttpStatus.METHOD_NOT_ALLOWED), "en")).contains("\"code\":\"method-not-allowed\"");
        assertThat(body(new ResponseStatusException(HttpStatusCode.valueOf(413)), "en")).contains("\"code\":\"content-too-large\"");
    }
}
