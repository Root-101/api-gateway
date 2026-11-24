package dev.root101.api_gateway.core.feature.auth.rest;

import dev.root101.api_gateway.core.feature.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.core.feature.auth.logic.model.LoginResponse;
import dev.root101.api_gateway.core.feature.auth.logic.usecase.AuthUseCase;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

/**
 * Auth controller for managing the user login of gateway.
 */
@RestController
@RequestMapping("/${app.admin.base-path}/auth")
public class AuthController {

    private final AuthUseCase authUseCase;

    public AuthController(AuthUseCase authUseCase) {
        this.authUseCase = authUseCase;
    }

    /**
     * Login the current user
     *
     * @param request The user to login
     * @return The token to use in the next requests
     */
    @PostMapping("/login")
    public Mono<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return authUseCase.login(request);
    }

}
