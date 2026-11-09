package dev.root101.api_gateway.security;


import dev.root101.api_gateway.features.http_logs.filter.HttpLogsWebFilter;
import dev.root101.commons.exceptions.ForbiddenException;
import dev.root101.commons.exceptions.UnauthorizedException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.web.server.authentication.AuthenticationWebFilter;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

/**
 * Created in `SecurityConfig`, NOT a bean (see comment there).
 */
public class AdminAuthenticationWebFilter extends AuthenticationWebFilter {

    private final static String BASIC = "Basic ";

    private final static String BEARER = "Bearer ";

    private final AdminAuthenticationManager adminAuthenticationManager;

    private final AdminTokens adminTokens;

    private final LoginAttemptsGuard loginAttemptsGuard;

    private final String adminBasePath;

    public AdminAuthenticationWebFilter(
            AdminAuthenticationManager adminAuthenticationManager,
            AdminTokens adminTokens,
            LoginAttemptsGuard loginAttemptsGuard,
            String adminBasePath
    ) {
        super(adminAuthenticationManager);
        this.adminAuthenticationManager = adminAuthenticationManager;
        this.adminTokens = adminTokens;
        this.loginAttemptsGuard = loginAttemptsGuard;
        this.adminBasePath = "/" + adminBasePath;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        //only process auth if the request is made to the gateway admin endpoints.
        //Proxied routes may use their own Basic auth, even with `_admin` somewhere in the path, so match the prefix only
        String path = exchange.getRequest().getURI().getPath();
        if (path.equals(adminBasePath) || path.startsWith(adminBasePath + "/")) {
            String clientIp = HttpLogsWebFilter.getClientIp(exchange);
            if (loginAttemptsGuard.isLocked(clientIp)) {
                return Mono.error(new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Too many failed attempts, try again later"));
            }

            Mono<Void> result;
            String token = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
            if (token != null && token.startsWith(BASIC)) {
                token = token.substring(BASIC.length());

                result = adminAuthenticationManager.authenticate(new UsernamePasswordAuthenticationToken(token, token))
                        .doOnNext(auth -> loginAttemptsGuard.succeeded(clientIp))
                        .flatMap(auth -> chain.filter(exchange)
                                .contextWrite(ReactiveSecurityContextHolder.withAuthentication(auth)));
            } else if (token != null && token.startsWith(BEARER) && adminTokens.isValid(token.substring(BEARER.length()))) {
                result = chain.filter(exchange)
                        .contextWrite(ReactiveSecurityContextHolder.withAuthentication(adminAuthenticationManager.adminAuthentication()));
            } else {
                //also an invalid or expired Bearer: anonymous, so 401 on protected paths while login and health keep working
                result = chain.filter(exchange);
            }

            if (path.equals(adminBasePath + "/auth/login")) {
                //wrong credentials in the login endpoint (its error goes through this filter too)
                result = result
                        .doOnSuccess(v -> loginAttemptsGuard.succeeded(clientIp))
                        .doOnError(UnauthorizedException.class, e -> loginAttemptsGuard.failed(clientIp));
            }
            //wrong credentials in Basic auth
            return result.doOnError(ForbiddenException.class, e -> loginAttemptsGuard.failed(clientIp));
        }
        return chain.filter(exchange);
    }
}
