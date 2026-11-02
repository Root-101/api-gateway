package dev.root101.api_gateway.features.http_logs.logic.usecase;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.data.repo.HttpLogWriter;
import dev.root101.api_gateway.features.http_logs.data.repo.HttpLogSearchRepo;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogResponse;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchResponse;
import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.logic.usecase.RouteUseCase;
import dev.root101.commons.validation.ValidationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class HttpLogUseCaseImpl implements HttpLogUseCase {

    private static final Logger log = LoggerFactory.getLogger(HttpLogUseCaseImpl.class);

    private final HttpLogWriter writer;
    private final HttpLogSearchRepo searchRepo;
    private final ValidationService vs;
    private final RouteUseCase routeUseCase;

    private final String adminBasePath;

    private final int maxSearchSize;

    public HttpLogUseCaseImpl(
            HttpLogWriter writer, HttpLogSearchRepo searchRepo,
            ValidationService vs,
            @Value("${app.admin.base-path}")
            String adminBasePath,
            @Value("${app.logs.max-search-size}")
            int maxSearchSize,
            final RouteUseCase routeUseCase
    ) {
        this.writer = writer;
        this.searchRepo = searchRepo;
        this.vs = vs;
        this.adminBasePath = adminBasePath;
        this.maxSearchSize = maxSearchSize;
        this.routeUseCase = routeUseCase;
    }

    /**
     * Same logic as the gateway: base uri + path rewritten by the RewritePath filter (if any).
     */
    static String buildFinalRoute(RouteEntity route, String requestedPath) {
        String path = requestedPath;
        if (route.getRewritePathFrom() != null && route.getRewritePathTo() != null) {
            //RewritePathGatewayFilterFactory also accepts `$\{` as an escaped `${`
            path = requestedPath.replaceAll(route.getRewritePathFrom(), route.getRewritePathTo().replace("$\\", "$"));
        }
        return route.getUri() + path;
    }

    private boolean isAdminPath(String path) {
        String base = "/" + adminBasePath;
        return path.equals(base) || path.startsWith(base + "/");
    }

    @Override
    public void saveHttpLog(HttpLogRequest request) {
        try {
            //validate the request
            vs.validate(request);

            //check if it's a request to a configured route, if it is, load the corresponding RouteEntity
            RouteEntity routeEntity = (request.getRoute() != null) ? routeUseCase.findCachedById(request.getRoute().getId()) : null;

            HttpLogEntity.RouteLog routeLog;
            //if route != null, it's a real route, we parse it to route-log
            //if not (route == null), we check if it's admin, if its admin, we create a 'dummy' RouteLog
            //if not a null route-log will be used
            if (routeEntity != null) {
                routeLog = new HttpLogEntity.RouteLog(
                        routeEntity.getRouteId().toString(),
                        routeEntity.getName(),
                        buildFinalRoute(routeEntity, request.getRequestedPath())
                );
            } else if (isAdminPath(request.getRequestedPath())) {
                routeLog = HttpLogEntity.RouteLog.admin(request.getServerIp() + request.getRequestedPath());
            } else {
                routeLog = null;
            }

            HttpLogEntity entity = new HttpLogEntity(
                    null,
                    request.getClientIp(),
                    request.getServerTime(),
                    request.getUserAgent(),
                    request.getHttpMethod().name(),
                    request.getRequestedPath(),
                    (request.getStatusCode() == null ? 0 : request.getStatusCode().value()),
                    request.getDuration(),
                    routeLog
            );
            vs.validate(entity);
            writer.enqueue(entity);
        } catch (Exception e) {
            log.error("Something went wrong saving log", e);
        }
    }

    @Override
    public Mono<HttpLogSearchResponse> search(HttpLogSearchRequest request) {
        Integer originalSize = request.getSize();

        //null size means "all", but capped so a big table can't be loaded fully in memory
        int realSize = originalSize != null ? Math.min(originalSize, maxSearchSize) : maxSearchSize;

        return searchRepo.search(request, realSize)
                .map(page -> new HttpLogSearchResponse(
                        page.getNumber(),                // current page
                        originalSize == null
                                ? (int) Math.min(page.getTotalElements(), realSize)
                                : page.getSize(),        // page size
                        page.getTotalPages(),            // total pages
                        page.getTotalElements(),         // total elements
                        page                             // page content
                                .getContent()
                                .stream()
                                .map(this::toResponse)
                                .toList()                // page content
                ));
    }

    private HttpLogResponse toResponse(HttpLogEntity entity) {
        return new HttpLogResponse(
                entity.getHttpLogId(),
                entity.getSourceIp(),
                entity.getRequestedAt(),
                entity.getUserAgent(),
                entity.getHttpMethod(),
                entity.getPath(),
                entity.getResponseCode(),
                entity.getRequestDuration(),
                entity.getRoute()
        );
    }
}
