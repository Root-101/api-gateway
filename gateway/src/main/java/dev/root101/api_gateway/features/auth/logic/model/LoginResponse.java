package dev.root101.api_gateway.features.auth.logic.model;

/**
 * @param token     To send as `Authorization: Bearer {token}`
 * @param expiresIn Seconds until the token expires
 */
public record LoginResponse(String token, long expiresIn) {
}
