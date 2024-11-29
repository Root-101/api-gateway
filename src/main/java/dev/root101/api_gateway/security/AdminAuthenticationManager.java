package dev.root101.api_gateway.security;

import dev.root101.commons.exceptions.ForbiddenException;
import dev.root101.commons.exceptions.UnauthorizedException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.util.Base64;
import java.util.Collection;
import java.util.Collections;

@Component
public class AdminAuthenticationManager implements ReactiveAuthenticationManager {

    @Value("${app.admin.username}")
    private String adminUsername;

    @Value("${app.admin.password}")
    private String adminPassword;

    @Value("${app.admin.role}")
    private String adminRole;

    @Override
    public Mono<Authentication> authenticate(Authentication authentication) {
        String base64Credentials = authentication.getCredentials().toString();
        String credentials = new String(Base64.getDecoder().decode(base64Credentials));
        final String[] values = credentials.split(":", 2);

        if (values.length == 2 && values[0] != null && values[1] != null && !values[0].isBlank() && !values[1].isBlank()) {
            if (values[0].equals(adminUsername) && values[1].equals(adminPassword)) {
                Mono<CustomUserDetails> user = Mono.just(
                        new CustomUserDetails(
                                adminUsername,
                                adminPassword,
                                Collections.singletonList(
                                        new SimpleGrantedAuthority(adminRole)
                                )
                        )
                );
                return user.map(
                        userDetails -> new UsernamePasswordAuthenticationToken(
                                userDetails, null, userDetails.getAuthorities()
                        )
                );
            } else {
                throw new ForbiddenException();
            }
        } else {
            throw new UnauthorizedException();
        }
    }

    public static class CustomUserDetails implements UserDetails {

        private final String username;
        private final String password;
        private final Collection<? extends GrantedAuthority> authorities;

        public CustomUserDetails(String username, String password, Collection<? extends GrantedAuthority> authorities) {
            this.username = username;
            this.password = password;
            this.authorities = authorities;
        }

        public CustomUserDetails(String username, String password) {
            this(username, password, Collections.emptyList());
        }

        @Override
        public Collection<? extends GrantedAuthority> getAuthorities() {
            return authorities;
        }

        @Override
        public String getPassword() {
            return password;
        }

        @Override
        public String getUsername() {
            return username;
        }

        @Override
        public boolean isAccountNonExpired() {
            return true; // Ajusta esta lógica según sea necesario
        }

        @Override
        public boolean isAccountNonLocked() {
            return true; // Ajusta esta lógica según sea necesario
        }

        @Override
        public boolean isCredentialsNonExpired() {
            return true; // Ajusta esta lógica según sea necesario
        }

        @Override
        public boolean isEnabled() {
            return true; // Ajusta esta lógica según sea necesario
        }
    }

}