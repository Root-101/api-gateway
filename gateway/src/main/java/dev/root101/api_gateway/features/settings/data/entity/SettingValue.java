package dev.root101.api_gateway.features.settings.data.entity;

/**
 * The json of a setting, as text. Not the driver's `Json` in the entity on purpose: spring data AOT walks the types
 * reachable from the entity and fails on its netty internals. The converters to the `jsonb` column are in
 * {@code SettingsConfig}, outside this type for the same reason.
 */
public record SettingValue(String json) {
}
