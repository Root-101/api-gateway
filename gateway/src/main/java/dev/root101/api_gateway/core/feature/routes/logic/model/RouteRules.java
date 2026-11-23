package dev.root101.api_gateway.core.feature.routes.logic.model;

import dev.root101.api_gateway.core.feature.routes.logic.model.RouteRequest;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import org.springframework.web.util.pattern.PathPatternParser;

import java.net.URI;
import java.util.regex.Pattern;

/**
 * What the field annotations of a route can't see: values the gateway can only use if they parse.
 * A route saved with a broken path pattern or regex would fail the refresh of every route (no change
 * applies) and, after a restart, every proxied request; a path in the uri would be silently dropped.
 */
public class RouteRules implements ConstraintValidator<ValidRoute, RouteRequest> {

    @Override
    public boolean isValid(RouteRequest route, ConstraintValidatorContext context) {
        if (route == null) {
            return true;
        }
        context.disableDefaultConstraintViolation();
        boolean valid = true;
        if (route.getPath() != null && !route.getPath().isBlank() && !route.getPath().startsWith("/")) {
            //request paths always start with `/`: without it the pattern parses but never matches
            valid = violation(context, "{error.route.path-without-leading-slash}", "path");
        } else if (route.getPath() != null) {
            try {
                //the parser of the gateway's Path predicate
                PathPatternParser.defaultInstance.parse(route.getPath());
            } catch (RuntimeException e) {
                valid = violation(context, "{error.route.invalid-path}", "path");
            }
        }
        if (route.getUri() != null) {
            try {
                String uriPath = URI.create(route.getUri()).getPath();
                //the gateway only takes scheme, host and port from the uri
                if (uriPath != null && !uriPath.isEmpty() && !uriPath.equals("/")) {
                    valid = violation(context, "{error.route.uri-with-path}", "uri");
                }
            } catch (IllegalArgumentException e) {
                //not a URI at all: the @URL validation already reports it
            }
        }
        if (route.getRewritePath() != null && route.getRewritePath().getReplaceFrom() != null) {
            try {
                Pattern.compile(route.getRewritePath().getReplaceFrom());
            } catch (RuntimeException e) {
                valid = violation(context, "{error.route.invalid-replace-from}", "rewritePath", "replaceFrom");
            }
        }
        return valid;
    }

    /**
     * Reports the broken rule on its field, always returns false
     */
    private static boolean violation(ConstraintValidatorContext context, String template, String field, String... nested) {
        var node = context.buildConstraintViolationWithTemplate(template).addPropertyNode(field);
        for (String name : nested) {
            node = node.addPropertyNode(name);
        }
        node.addConstraintViolation();
        return false;
    }
}
