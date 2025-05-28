package dev.root101.api_gateway.features.auth.rest;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.features.auth.logic.usecase.AuthUseCase;
import org.springframework.beans.factory.annotation.Autowired;
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

    @Autowired
    public AuthController(AuthUseCase authUseCase) {
        this.authUseCase = authUseCase;
    }

    /**
     * Login the current user
     *
     * @param request The user to login
     * @return Void
     */
    @PostMapping
    public Mono<Void> addRoute(@RequestBody LoginRequest request) {
        return authUseCase.login(request);
    }

}
