package dev.root101.api_gateway.core.error;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.ErrorResponseException;

/**
 * Errors with a message key ({@code error.route.not-found}) and its arguments instead of a fixed text: Spring's
 * {@link ErrorResponseException} with the key as its detail message code. {@code GlobalExceptionHandlerConfig} answers
 * them as Problem Details: the key, translated to the request language, is the {@code detail}.
 * {@code throw Errors.notFound("error.route.not-found", id)}.
 */
public final class Errors {

    private Errors() {
    }

    /**
     * Bad Request: A rule not tied to one field.
     */
    public static ErrorResponseException badRequest(String key, Object... args) {
        return of(HttpStatus.BAD_REQUEST, key, args);
    }

    /**
     * Unauthorized: Wrong credentials or token.
     */
    public static ErrorResponseException unauthorized(String key, Object... args) {
        return of(HttpStatus.UNAUTHORIZED, key, args);
    }

    /**
     * Forbidden: Authenticated but not allowed.
     */
    public static ErrorResponseException forbidden(String key, Object... args) {
        return of(HttpStatus.FORBIDDEN, key, args);
    }

    /**
     * Not Found: Missing resource.
     */
    public static ErrorResponseException notFound(String key, Object... args) {
        return of(HttpStatus.NOT_FOUND, key, args);
    }

    /**
     * Conflict: Conflicts with the current state.
     */
    public static ErrorResponseException conflict(String key, Object... args) {
        return of(HttpStatus.CONFLICT, key, args);
    }

    /**
     * Too Many Requests: Rate limit or lock.
     */
    public static ErrorResponseException tooManyRequests(String key, Object... args) {
        return of(HttpStatus.TOO_MANY_REQUESTS, key, args);
    }

    private static ErrorResponseException of(HttpStatus status, String key, Object[] args) {
        return new ErrorResponseException(status, ProblemDetail.forStatus(status), null, key, args);
    }
}
