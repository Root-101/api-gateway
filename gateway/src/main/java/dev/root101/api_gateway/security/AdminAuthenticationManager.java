package dev.root101.api_gateway.security;

import dev.root101.commons.exceptions.UnauthorizedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Collection;
import java.util.Collections;

@Component
public class AdminAuthenticationManager implements ReactiveAuthenticationManager {

    private static final Logger log = LoggerFactory.getLogger(AdminAuthenticationManager.class);

    private final String adminUsername;

    private final String adminPassword;

    private final String adminRole;

    public AdminAuthenticationManager(
            @Value("${app.admin.username}") String adminUsername,
            @Value("${app.admin.password}") String adminPassword,
            @Value("${app.admin.role}") String adminRole,
            @Value("${app.defaults.username}") String defaultUsername,
            @Value("${app.defaults.password}") String defaultPassword
    ) {
        this.adminUsername = adminUsername;
        this.adminPassword = adminPassword;
        this.adminRole = adminRole;

        //the password alone is what matters: a custom username with the public password is just as open
        if (adminPassword.equals(defaultPassword)) {
            log.warn("Server starting with the DEFAULT admin password. Set the ADMIN_PASSWORD environment variable for any real environment");
        }
    }

    /**
     * Constant-time check of the admin credentials (also used by the login endpoint).
     */
    public boolean matches(String username, String password) {
        //`&` (not `&&`): always compare both, so the time doesn't tell which one failed
        return equalsConstantTime(username, adminUsername) & equalsConstantTime(password, adminPassword);
    }

    private static boolean equalsConstantTime(String given, String expected) {
        return given != null && MessageDigest.isEqual(
                given.getBytes(StandardCharsets.UTF_8),
                expected.getBytes(StandardCharsets.UTF_8)
        );
    }

    @Override
    public Mono<Authentication> authenticate(Authentication authentication) {
        String base64Credentials = authentication.getCredentials().toString();
        final String[] values;
        try {
            values = new String(Base64.getDecoder().decode(base64Credentials.trim()), StandardCharsets.UTF_8).split(":", 2);
        } catch (IllegalArgumentException e) {//not valid base64
            return Mono.error(new UnauthorizedException("auth.invalid_basic"));
        }

        if (values.length == 2 && values[0] != null && values[1] != null && !values[0].isBlank() && !values[1].isBlank()) {
            if (matches(values[0], values[1])) {
                return Mono.just(adminAuthentication());
            } else {
                return Mono.error(new UnauthorizedException("auth.wrong_credentials"));
            }
        } else {
            return Mono.error(new UnauthorizedException("auth.invalid_basic"));
        }
    }

    /**
     * The authentication of the admin, once its credentials or token have been checked.
     */
    public Authentication adminAuthentication() {
        CustomUserDetails user = new CustomUserDetails(adminUsername, Collections.singletonList(new SimpleGrantedAuthority(adminRole)));
        return new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
    }

    public static class CustomUserDetails implements UserDetails {

        private final String username;
        private final Collection<? extends GrantedAuthority> authorities;

        public CustomUserDetails(String username, Collection<? extends GrantedAuthority> authorities) {
            this.username = username;
            this.authorities = authorities;
        }

        @Override
        public Collection<? extends GrantedAuthority> getAuthorities() {
            return authorities;
        }

        @Override
        public String getPassword() {
            return null;//never kept in memory after the check
        }

        @Override
        public String getUsername() {
            return username;
        }

        @Override
        public boolean isAccountNonExpired() {
            return true; // Adjust this logic if needed
        }

        @Override
        public boolean isAccountNonLocked() {
            return true; // Adjust this logic if needed
        }

        @Override
        public boolean isCredentialsNonExpired() {
            return true; // Adjust this logic if needed
        }

        @Override
        public boolean isEnabled() {
            return true; // Adjust this logic if needed
        }
    }

}
