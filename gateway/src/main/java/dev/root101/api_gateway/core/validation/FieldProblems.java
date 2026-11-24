package dev.root101.api_gateway.core.validation;

import dev.root101.api_gateway.core.error.FieldProblem;
import dev.root101.api_gateway.core.i18n.I18n;
import jakarta.validation.ConstraintViolation;
import org.springframework.context.MessageSource;
import org.springframework.stereotype.Component;
import org.springframework.validation.FieldError;
import tools.jackson.databind.PropertyNamingStrategies;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Turns the Bean Validation errors of a request body ({@code @Valid}) into the {@code errors} of a 422: JSON Pointer to
 * the field (with the names of the JSON), code of the broken rule, its text in the request language and its limits.
 */
@Component
public class FieldProblems {

    //attributes of the annotation that are not limits of the rule
    private static final Set<String> IGNORED_ATTRIBUTES = Set.of("message", "groups", "payload");

    //"the value is missing" rules: first in their field, the one a client shows if it shows only one
    private static final Set<String> PRESENCE_CODES = Set.of("not-null", "not-blank", "not-empty");

    //a message template that is one of our keys: `{error.route.invalid-path}`
    private static final Pattern OWN_KEY = Pattern.compile("^\\{error\\.(.+)}$");

    private static final Pattern SEGMENT = Pattern.compile("([^.\\[]+)|\\[(\\d+)]");

    private final MessageSource messages;
    private final PropertyNamingStrategies.NamingBase namingStrategy;

    public FieldProblems(MessageSource messages, PropertyNamingStrategies.NamingBase namingStrategy) {
        this.messages = messages;
        this.namingStrategy = namingStrategy;
    }

    /**
     * In a stable order (Hibernate Validator does not keep the one of the violations): by pointer and, inside a field,
     * first the missing-value rules, then by code and detail.
     *
     * @param index the position of the body in a list body, null for an object body
     */
    public List<FieldProblem> of(List<FieldError> errors, Integer index, Locale locale) {
        return errors.stream()
                .map(error -> of(error, index, locale))
                .sorted(Comparator.comparing(FieldProblem::pointer)
                        .thenComparing(problem -> !PRESENCE_CODES.contains(problem.code()))
                        .thenComparing(FieldProblem::code)
                        .thenComparing(FieldProblem::detail))
                .toList();
    }

    private FieldProblem of(FieldError error, Integer index, Locale locale) {
        String detail = I18n.text(messages, error.getDefaultMessage(), null, locale);
        String pointer = pointer(error.getField(), index);
        if (!error.contains(ConstraintViolation.class)) {
            return new FieldProblem(pointer, kebab(String.valueOf(error.getCode())), detail, Map.of());
        }
        ConstraintViolation<?> violation = error.unwrap(ConstraintViolation.class);
        Matcher own = OWN_KEY.matcher(violation.getMessageTemplate());
        String code = own.matches()
                ? own.group(1)
                : kebab(violation.getConstraintDescriptor().getAnnotation().annotationType().getSimpleName());
        return new FieldProblem(pointer, code, detail, own.matches() ? Map.of() : params(violation));
    }

    /**
     * {@code rewritePath.replaceFrom} -> {@code #/rewrite_path/replace_from}, {@code allowedOrigins[1]} ->
     * {@code #/allowed_origins/1}; in a list body the index first: {@code #/0/name}
     */
    public String pointer(String field, Integer index) {
        List<String> parts = new ArrayList<>();
        if (index != null) parts.add(String.valueOf(index));
        Matcher matcher = SEGMENT.matcher(field == null ? "" : field);
        while (matcher.find()) {
            parts.add(matcher.group(1) != null ? namingStrategy.nameForField(null, null, matcher.group(1)) : matcher.group(2));
        }
        return parts.isEmpty() ? "#" : "#/" + String.join("/", parts);
    }

    // NotNull -> not-null, URL -> url
    private static String kebab(String name) {
        return name.replaceAll("([a-z0-9])([A-Z])", "$1-$2").toLowerCase(Locale.ROOT);
    }

    private static Map<String, Object> params(ConstraintViolation<?> violation) {
        Map<String, Object> params = new TreeMap<>();
        violation.getConstraintDescriptor().getAttributes().forEach((name, value) -> {
            if (IGNORED_ATTRIBUTES.contains(name) || value == null) {
                return;
            }
            if (value instanceof Number || value instanceof Boolean || value instanceof CharSequence) {
                params.put(name, value);
            } else if (value instanceof Enum<?> e) {
                params.put(name, e.name());
            }
        });
        return params;
    }
}
