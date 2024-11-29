package dev.root101.api_gateway.security;


import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.web.server.authentication.AuthenticationWebFilter;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilterChain;
import reactor.core.publisher.Mono;

@Component
public class AdminAuthenticationWebFilter extends AuthenticationWebFilter {

    private final static String BASIC = "Basic ";

    private final AdminAuthenticationManager jwtAuthenticationManager;

    public AdminAuthenticationWebFilter(AdminAuthenticationManager jwtAuthenticationManager) {
        super(jwtAuthenticationManager);
        this.jwtAuthenticationManager = jwtAuthenticationManager;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String token = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (token != null && token.startsWith(BASIC)) {
            token = token.replaceFirst(BASIC, "");

            return jwtAuthenticationManager.authenticate(new UsernamePasswordAuthenticationToken(token, token))
                    .flatMap(auth -> chain.filter(exchange)
                            .contextWrite(ReactiveSecurityContextHolder.withAuthentication(auth)));

        }
        return chain.filter(exchange);
    }
}