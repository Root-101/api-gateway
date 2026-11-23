package dev.root101.api_gateway.core.feature.auth.logic.model;

/**
 * @param accessToken To send as `Authorization: Bearer {access_token}`
 * @param expiresIn   Milliseconds the token is valid for
 * @param expireAt    When it expires, as epoch milliseconds
 */
public record LoginResponse(String accessToken, long expiresIn, long expireAt) {
}
