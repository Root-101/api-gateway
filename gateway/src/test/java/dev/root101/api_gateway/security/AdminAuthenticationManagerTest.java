package dev.root101.api_gateway.security;

import dev.root101.commons.exceptions.ForbiddenException;
import dev.root101.commons.exceptions.UnauthorizedException;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import reactor.test.StepVerifier;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;

class AdminAuthenticationManagerTest {

    private final AdminAuthenticationManager manager = new AdminAuthenticationManager(
            "admin", "pa:ss-ñ", "ROLE_GATEWAY_ADMIN", "admin", "admin123**"
    );

    private static UsernamePasswordAuthenticationToken basic(String raw) {
        String token = Base64.getEncoder().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
        return new UsernamePasswordAuthenticationToken(token, token);
    }

    @Test
    void validCredentialsWithColonAndUtf8InPassword() {
        StepVerifier.create(manager.authenticate(basic("admin:pa:ss-ñ")))
                .assertNext(auth -> {
                    assertThat(auth.getAuthorities()).extracting(GrantedAuthority::getAuthority).containsExactly("ROLE_GATEWAY_ADMIN");
                    assertThat(auth.getCredentials()).isNull();
                    var user = (AdminAuthenticationManager.CustomUserDetails) auth.getPrincipal();
                    assertThat(user.getUsername()).isEqualTo("admin");
                    assertThat(user.getPassword()).isNull();
                    assertThat(user.isEnabled() && user.isAccountNonLocked() && user.isAccountNonExpired() && user.isCredentialsNonExpired()).isTrue();
                })
                .verifyComplete();
    }

    @Test
    void wrongCredentialsAre403() {
        StepVerifier.create(manager.authenticate(basic("admin:wrong"))).verifyError(ForbiddenException.class);
        StepVerifier.create(manager.authenticate(basic("other:pa:ss-ñ"))).verifyError(ForbiddenException.class);
    }

    @Test
    void malformedCredentialsAre401() {
        for (Authentication auth : new Authentication[]{
                new UsernamePasswordAuthenticationToken("%%%not-base64", "%%%not-base64"),
                basic("no-colon"),
                basic(":password"),
                basic("admin:"),
                basic(" : "),
        }) {
            StepVerifier.create(manager.authenticate(auth)).verifyError(UnauthorizedException.class);
        }
    }

    @Test
    void matches() {
        assertThat(manager.matches("admin", "pa:ss-ñ")).isTrue();
        assertThat(manager.matches("admin", "pa:ss-n")).isFalse();
        assertThat(manager.matches("admin", null)).isFalse();
        assertThat(manager.matches(null, "pa:ss-ñ")).isFalse();
    }
}
