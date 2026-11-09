package dev.root101.api_gateway.features.auth.logic.usecase;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
import dev.root101.api_gateway.features.auth.logic.model.LoginResponse;
import reactor.core.publisher.Mono;

public interface AuthUseCase {

    /**
     * Login the admin user (for the moment just admin, buajajajajajajaja)
     *
     * @param request The user to log in
     * @return The token to use in the next requests
     */
    Mono<LoginResponse> login(LoginRequest request);

}
