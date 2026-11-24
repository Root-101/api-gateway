package dev.root101.api_gateway.core.error;

import java.util.Map;

/**
 * One invalid field of a 422 problem.
 *
 * @param pointer JSON Pointer (RFC 6901) to the field in the request body: {@code #/rewrite_path/replace_from},
 *                {@code #/0/name} in a list body
 * @param code    stable code of the broken rule: the constraint ({@code size}, {@code not-blank}, {@code url}...) or
 *                our own key without {@code error.} ({@code route.invalid-path})
 * @param detail  the problem, in the request language
 * @param params  the limits of the rule ({@code min}, {@code max}...), so a client can build its own text; empty when
 *                there are none
 */
public record FieldProblem(
        String pointer,
        String code,
        String detail,
        Map<String, Object> params
) {
}
