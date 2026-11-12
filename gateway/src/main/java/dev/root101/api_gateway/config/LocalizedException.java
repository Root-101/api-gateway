package dev.root101.api_gateway.config;

import dev.root101.commons.exceptions.ApiException;
import org.springframework.http.HttpStatus;

/**
 * An error whose message is a key of the messages files with arguments ({0}), written by the error handler in the
 * language of the request. Without arguments, any {@link ApiException} with a key as its message is enough.
 */
public class LocalizedException extends ApiException {

    private final Object[] args;

    public LocalizedException(HttpStatus status, String key, Object... args) {
        super(status, key);
        this.args = args;
    }

    public Object[] args() {
        return args;
    }
}
