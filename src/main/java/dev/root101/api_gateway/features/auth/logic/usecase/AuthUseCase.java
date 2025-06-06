package dev.root101.api_gateway.features.auth.logic.usecase;

import dev.root101.api_gateway.features.auth.logic.model.LoginRequest;
import reactor.core.publisher.Mono;

public interface AuthUseCase {

    /**
     * Login the admin user (for the moment just admin, buajajajajajajaja)
     * This method is to like validate the credentials are ok... this don't do anything else
     *
     * @param request The user to log in
     * @return Void
     */
    Mono<Void> login(LoginRequest request);

}
