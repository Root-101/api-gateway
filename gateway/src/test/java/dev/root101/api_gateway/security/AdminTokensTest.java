package dev.root101.api_gateway.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AdminTokensTest {

    @Test
    void issuedTokenIsValidAndUnique() {
        AdminTokens tokens = new AdminTokens(10);

        String token = tokens.issue();

        assertThat(tokens.isValid(token)).isTrue();
        assertThat(tokens.isValid("unknown")).isFalse();
        assertThat(tokens.issue()).isNotEqualTo(token);
        assertThat(tokens.ttlMillis()).isEqualTo(600_000);
    }

    @Test
    void expiredTokenIsInvalid() {
        AdminTokens tokens = new AdminTokens(0);

        assertThat(tokens.isValid(tokens.issue())).isFalse();
    }
}
