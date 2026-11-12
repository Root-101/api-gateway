package dev.root101.api_gateway.features.routes.utils;

import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.commons.exceptions.ValidationException;
import dev.root101.commons.exceptions.ValidationException.ValidationErrorMessage;
import org.springframework.web.util.pattern.PathPatternParser;

import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/**
 * What the bean validation of a route can't see: values the gateway can only use if they parse.
 * A route saved with a broken path pattern or regex would fail the refresh of every route (no change
 * applies) and, after a restart, every proxied request; a path in the uri would be silently dropped.
 */
public final class RouteRules {

    private RouteRules() {
    }

    /**
     * Throws a `422` with every broken field, named as the client sent it (`[0].path` in a list)
     */
    public static void check(List<RouteConfigRequest> routes) {
        List<ValidationErrorMessage> errors = new ArrayList<>();
        for (int i = 0; i < routes.size(); i++) {
            errors.addAll(errors(routes.get(i), "[%d].".formatted(i)));
        }
        if (!errors.isEmpty()) throw new ValidationException(errors);
    }

    public static void check(RouteConfigRequest route) {
        List<ValidationErrorMessage> errors = errors(route, "");
        if (!errors.isEmpty()) throw new ValidationException(errors);
    }

    static List<ValidationErrorMessage> errors(RouteConfigRequest route, String prefix) {
        List<ValidationErrorMessage> errors = new ArrayList<>();
        if (route.getPath() != null && !route.getPath().isBlank() && !route.getPath().startsWith("/")) {
            //request paths always start with `/`: without it the pattern parses but never matches
            errors.add(new ValidationErrorMessage(prefix + "path", route.getPath(), "route.path.no_leading_slash"));
        } else if (route.getPath() != null) {
            try {
                //the parser of the gateway's Path predicate
                PathPatternParser.defaultInstance.parse(route.getPath());
            } catch (RuntimeException e) {
                errors.add(new ValidationErrorMessage(prefix + "path", route.getPath(), "route.path.invalid"));
            }
        }
        if (route.getUri() != null) {
            try {
                String uriPath = URI.create(route.getUri()).getPath();
                //the gateway only takes scheme, host and port from the uri
                if (uriPath != null && !uriPath.isEmpty() && !uriPath.equals("/")) {
                    errors.add(new ValidationErrorMessage(prefix + "uri", route.getUri(), "route.uri.has_path"));
                }
            } catch (IllegalArgumentException e) {
                //not a URI at all: the @URL validation already reports it
            }
        }
        if (route.getRewritePath() != null && route.getRewritePath().getReplaceFrom() != null) {
            try {
                Pattern.compile(route.getRewritePath().getReplaceFrom());
            } catch (RuntimeException e) {
                errors.add(new ValidationErrorMessage(prefix + "rewrite_path.replace_from", route.getRewritePath().getReplaceFrom(), "route.replace_from.invalid"));
            }
        }
        return errors;
    }
}
