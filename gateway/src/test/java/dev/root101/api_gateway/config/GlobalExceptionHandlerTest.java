package dev.root101.api_gateway.config;

import tools.jackson.databind.json.JsonMapper;
import dev.root101.commons.exceptions.NotFoundException;
import dev.root101.commons.exceptions.ValidationException;
import io.netty.channel.ConnectTimeoutException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.server.ResponseStatusException;

import java.net.ConnectException;
import java.net.UnknownHostException;
import java.util.concurrent.TimeoutException;
import java.util.stream.Stream;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;
import reactor.test.StepVerifier;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler(JsonMapper.builderWithJackson2Defaults().build());

    private MockServerWebExchange exchange() {
        return MockServerWebExchange.from(MockServerHttpRequest.get("/any"));
    }

    @Test
    void unexpectedErrorDoesNotLeakItsMessage() {
        MockServerWebExchange exchange = exchange();

        StepVerifier.create(handler.handle(exchange, new IllegalStateException("password authentication failed for user \"postgres\"")))
                .verifyComplete();

        assertThat(exchange.getResponse().getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(exchange.getResponse().getHeaders().getContentType()).isEqualTo(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(exchange.getResponse().getBodyAsString().block()).isEqualTo(
                "{\"type\":\"about:blank\",\"title\":\"Internal Server Error\",\"status\":500,\"detail\":\"Internal server error\",\"instance\":\"/any\"}");
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
                Arguments.of(new ValidationException(new ValidationException.ValidationErrorMessage("name", "", "must not be blank")),
                        HttpStatus.UNPROCESSABLE_CONTENT, "\"violations\":[{\"fieldName\":\"name\",\"message\":\"must not be blank\"}]"),
                Arguments.of(new NotFoundException("Route does not exist: x"), HttpStatus.NOT_FOUND, "Route does not exist: x"),
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

        handler.handle(exchange, new dev.root101.commons.exceptions.ConflictException("name already used: ñ")).block();

        assertThat(exchange.getResponse().getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(exchange.getResponse().getBodyAsString().block()).contains("\"detail\":\"name already used: ñ\"");
    }

    @Test
    void listFieldNamesDropTheRoot() {
        assertThat(GlobalExceptionHandler.fieldName("root[0].name")).isEqualTo("[0].name");
        assertThat(GlobalExceptionHandler.fieldName("rewrite_path.replace_from")).isEqualTo("rewrite_path.replace_from");
    }
}
