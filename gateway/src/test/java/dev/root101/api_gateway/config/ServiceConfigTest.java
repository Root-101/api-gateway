package dev.root101.api_gateway.config;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ServiceConfigTest {

    /**
     * `TRUSTED_PROXIES` empty trusts no proxy (Spring Cloud Gateway's own `TrustedProxies` rejects an empty regex).
     */
    @Test
    void trustedProxies() {
        ServiceConfig config = new ServiceConfig();
        assertThat(config.trustedProxies("").isTrusted("127.0.0.1")).isFalse();
        assertThat(config.trustedProxies(" ").isTrusted("127.0.0.1")).isFalse();
        assertThat(config.trustedProxies("10\\..*").isTrusted("10.0.0.1")).isTrue();
        assertThat(config.trustedProxies("10\\..*").isTrusted("127.0.0.1")).isFalse();
    }
}
