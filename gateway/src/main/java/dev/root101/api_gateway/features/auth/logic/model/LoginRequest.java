package dev.root101.api_gateway.features.auth.logic.model;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Model with the username/password of the user.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {

    /**
     * Username of the admin user.
     */
    @NotBlank
    private String username;

    /**
     * Password of the admin user.
     */
    @NotBlank
    private String password;
}
