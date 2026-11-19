package dev.root101.api_gateway.config;

import org.springframework.http.HttpStatus;

/**
 * An error with its status, whose message is a key of the messages files with arguments ({0}), written by the
 * error handler in the language of the request.
 */
public class LocalizedException extends RuntimeException {

    private final HttpStatus status;

    private final Object[] args;

    public LocalizedException(HttpStatus status, String key, Object... args) {
        super(key);
        this.status = status;
        this.args = args;
    }

    public HttpStatus status() {
        return status;
    }

    public Object[] args() {
        return args;
    }
}
