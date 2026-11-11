package dev.root101.api_gateway.features.auth.logic.usecase;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.features.auth.logic.model.LoginResponse;
import dev.root101.api_gateway.security.AdminAuthenticationManager;
import dev.root101.api_gateway.security.AdminTokens;
import dev.root101.commons.exceptions.UnauthorizedException;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

/**
 * This is the class who really 'login' the user: checks the credentials and issues the token
 */
@Service
class AuthUseCaseImpl implements AuthUseCase {

    private final ValidationService vs;

    private final AdminAuthenticationManager adminAuthenticationManager;

    private final AdminTokens adminTokens;

    @Autowired
    public AuthUseCaseImpl(
            AdminAuthenticationManager adminAuthenticationManager,
            AdminTokens adminTokens,
            ValidationService validationService
    ) {
        this.adminAuthenticationManager = adminAuthenticationManager;
        this.adminTokens = adminTokens;
        this.vs = validationService;
    }

    @Override
    public Mono<LoginResponse> login(LoginRequest request) {
        return Mono.fromRunnable(() -> vs.validate(request))
                .then(
                        Mono.defer(() -> {
                            if (adminAuthenticationManager.matches(request.getUsername(), request.getPassword())) {
                                String token = adminTokens.issue();
                                return Mono.just(new LoginResponse(token, adminTokens.ttlMillis(), adminTokens.expireAt(token)));
                            } else {
                                return Mono.error(new UnauthorizedException("Wrong username or password"));
                            }
                        })
                );
    }
}
