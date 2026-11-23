package dev.root101.api_gateway.core.feature.auth.logic.usecase;

import dev.root101.api_gateway.core.feature.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.core.feature.auth.logic.model.LoginResponse;
import dev.root101.api_gateway.security.AdminAuthenticationManager;
import dev.root101.api_gateway.security.AdminTokens;
import dev.root101.api_gateway.core.error.Errors;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

/**
 * This is the class who really 'login' the user: checks the credentials and issues the token
 */
@Service
class AuthUseCase_Impl implements AuthUseCase {

    private final AdminAuthenticationManager adminAuthenticationManager;

    private final AdminTokens adminTokens;

    public AuthUseCase_Impl(
            AdminAuthenticationManager adminAuthenticationManager,
            AdminTokens adminTokens
    ) {
        this.adminAuthenticationManager = adminAuthenticationManager;
        this.adminTokens = adminTokens;
    }

    @Override
    public Mono<LoginResponse> login(LoginRequest request) {
        return Mono.defer(() -> {
            if (adminAuthenticationManager.matches(request.getUsername(), request.getPassword())) {
                String token = adminTokens.issue();
                return Mono.just(new LoginResponse(token, adminTokens.ttlMillis(), adminTokens.expireAt(token)));
            } else {
                return Mono.error(Errors.unauthorized("auth.wrong_credentials"));
            }
        });
    }
}
