package dev.root101.api_gateway.features.auth.logic.usecase;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.security.AdminAuthenticationManager;
import dev.root101.commons.exceptions.ForbiddenException;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

/**
 * This is the class who really 'login' the user (Again, just a simple check to see if it's the correct user)
 */
@Service
class AuthUseCaseImpl implements AuthUseCase {

    private final ValidationService vs;

    private final AdminAuthenticationManager adminAuthenticationManager;

    @Autowired
    public AuthUseCaseImpl(
            AdminAuthenticationManager adminAuthenticationManager,
            ValidationService validationService
    ) {
        this.adminAuthenticationManager = adminAuthenticationManager;
        this.vs = validationService;
    }

    @Override
    public Mono<Void> login(LoginRequest request) {
        return Mono.fromRunnable(() -> vs.validate(request))
                .then(
                        Mono.defer(() -> {
                            if (adminAuthenticationManager.matches(request.getUsername(), request.getPassword())) {
                                return Mono.empty();
                            } else {
                                return Mono.error(new ForbiddenException("Wrong username or password"));
                            }
                        })
                );
    }
}
