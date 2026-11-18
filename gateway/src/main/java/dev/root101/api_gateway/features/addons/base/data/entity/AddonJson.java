package dev.root101.api_gateway.features.addons.base.data.entity;

/**
 * A `jsonb` column of an add-on, as text. Not the driver's `Json` in the entity on purpose: spring data AOT walks the
 * types reachable from the entity and fails on its netty internals. The converters to the column are in
 * {@code AddonsConfig}, outside this type for the same reason.
 */
public record AddonJson(String json) {
}
