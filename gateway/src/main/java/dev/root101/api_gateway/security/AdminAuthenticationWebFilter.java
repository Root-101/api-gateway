package dev.root101.api_gateway.security;


import dev.root101.api_gateway.features.http_logs.filter.HttpLogsWebFilter;
import dev.root101.api_gateway.config.GlobalExceptionHandler;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

/**
 * Created in `SecurityConfig`, NOT a bean (see comment there).
 */
public class AdminAuthenticationWebFilter implements WebFilter {

    private final static String BASIC = "Basic ";

    private final static String BEARER = "Bearer ";

    private final AdminAuthenticationManager adminAuthenticationManager;

    private final AdminTokens adminTokens;

    private final LoginAttemptsGuard loginAttemptsGuard;

    private final String adminBasePath;

    private final GlobalExceptionHandler errorHandler;

    public AdminAuthenticationWebFilter(
            AdminAuthenticationManager adminAuthenticationManager,
            AdminTokens adminTokens,
            LoginAttemptsGuard loginAttemptsGuard,
            String adminBasePath,
            GlobalExceptionHandler errorHandler
    ) {
        this.errorHandler = errorHandler;
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
        if (!path.equals(adminBasePath) && !path.startsWith(adminBasePath + "/")) {
            return chain.filter(exchange);
        }
        //public and probed often: a stray Authorization header there must not count as a try of the credentials
        if (path.equals(adminBasePath + "/health")) {
            return chain.filter(exchange);
        }
        String clientIp = HttpLogsWebFilter.getClientIp(exchange);
        String header = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        //only a POST is a try of the credentials (an OPTIONS or a GET there must not clear the count)
        boolean isLogin = path.equals(adminBasePath + "/auth/login") && exchange.getRequest().getMethod() == HttpMethod.POST;
        boolean isBasic = header != null && header.startsWith(BASIC);

        //the lockout only stops new tries of the credentials: a valid token and the health check keep working.
        //The try is taken before the check, so concurrent guesses can't all pass before any failure counts
        if ((isLogin || isBasic) && !loginAttemptsGuard.tryAcquire(clientIp)) {
            long seconds = loginAttemptsGuard.retryAfterSeconds(clientIp);
            exchange.getResponse().getHeaders().set(HttpHeaders.RETRY_AFTER, String.valueOf(seconds));
            return errorHandler.writeProblem(exchange, HttpStatus.TOO_MANY_REQUESTS,
                    "auth.locked", String.valueOf(seconds));
        }

        Mono<Void> result;
        if (isBasic) {
            String credentials = header.substring(BASIC.length());
            result = adminAuthenticationManager.authenticate(new UsernamePasswordAuthenticationToken(credentials, credentials))
                    .doOnNext(auth -> loginAttemptsGuard.succeeded(clientIp))
                    .flatMap(auth -> chain.filter(exchange)
                            .contextWrite(ReactiveSecurityContextHolder.withAuthentication(auth)));
        } else if (header != null && header.startsWith(BEARER) && adminTokens.isValid(header.substring(BEARER.length()))) {
            result = chain.filter(exchange)
                    .contextWrite(ReactiveSecurityContextHolder.withAuthentication(adminAuthenticationManager.adminAuthentication()));
        } else {
            //also an invalid or expired Bearer: anonymous, so 401 on protected paths while login and health keep working
            result = chain.filter(exchange);
        }

        if (isLogin) {
            //a login POST only completes without error with the right credentials (wrong ones: UnauthorizedException)
            result = result.doOnSuccess(v -> loginAttemptsGuard.succeeded(clientIp));
        }
        return result;
    }
}
