package dev.root101.api_gateway.core.feature.http_logs.logic.usecase;

import lombok.extern.slf4j.Slf4j;
import dev.root101.api_gateway.core.feature.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.core.feature.http_logs.data.repo.HttpLogWriter;
import dev.root101.api_gateway.core.feature.http_logs.data.repo.HttpLogSearchRepo;
import dev.root101.api_gateway.core.feature.http_logs.logic.model.HttpLogRequest;
import dev.root101.api_gateway.core.feature.http_logs.logic.model.HttpLogResponse;
import dev.root101.api_gateway.core.feature.http_logs.logic.model.SearchHttpLogRequest;
import dev.root101.api_gateway.core.feature.http_logs.logic.model.SearchHttpLogResponse;
import dev.root101.api_gateway.core.feature.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.core.feature.routes.logic.usecase.RouteUseCase;
import dev.root101.api_gateway.core.error.Errors;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Validator;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Slf4j
@Service
class HttpLogUseCase_Impl implements HttpLogUseCase {

    private final HttpLogWriter writer;
    private final HttpLogSearchRepo searchRepo;
    private final Validator validator;
    private final RouteUseCase routeUseCase;

    private final String adminBasePath;

    private final int maxSearchSize;

    private static final int DEFAULT_PAGE_SIZE = 50;

    public HttpLogUseCase_Impl(
            HttpLogWriter writer, HttpLogSearchRepo searchRepo,
            Validator validator,
            @Value("${app.admin.base-path}")
            String adminBasePath,
            @Value("${app.logs.max-search-size}")
            int maxSearchSize,
            final RouteUseCase routeUseCase
    ) {
        this.writer = writer;
        this.searchRepo = searchRepo;
        this.validator = validator;
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
    public void save(HttpLogRequest request) {
        try {
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
            //a value the column can't hold would fail the whole batch insert: this log is dropped instead
            var violations = validator.validate(entity);
            if (!violations.isEmpty()) {
                throw new ConstraintViolationException(violations);
            }
            writer.enqueue(entity);
        } catch (Exception e) {
            log.error("Something went wrong saving log", e);
        }
    }

    @Override
    public Mono<SearchHttpLogResponse> search(SearchHttpLogRequest request) {
        validate(request);
        //capped so a big table can't be loaded fully in memory
        int realSize = Math.min(request.getSize() != null ? request.getSize() : DEFAULT_PAGE_SIZE, maxSearchSize);

        return searchRepo.search(request, realSize)
                .map(page -> new SearchHttpLogResponse(
                        page.getNumber(),                // current page
                        page.getSize(),                  // page size
                        //the count stops one past the cap: report the cap and flag it
                        (int) Math.ceil((double) Math.min(page.getTotalElements(), HttpLogSearchRepo.COUNT_CAP) / page.getSize()),
                        Math.min(page.getTotalElements(), HttpLogSearchRepo.COUNT_CAP),
                        page.getTotalElements() > HttpLogSearchRepo.COUNT_CAP,
                        page                             // page content
                                .getContent()
                                .stream()
                                .map(HttpLogResponse::build)
                                .toList()                // page content
                ));
    }

    /**
     * The filters the repo can't read: `400`
     */
    private static void validate(SearchHttpLogRequest request) {
        if (request.getPage() < 0) {
            throw Errors.badRequest("logs.page.invalid");
        }
        if (request.getSize() != null && request.getSize() < 1) {
            throw Errors.badRequest("logs.size.invalid");
        }
        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            try {
                Integer.parseInt(request.getStatus().trim());
            } catch (NumberFormatException e) {
                throw Errors.badRequest("logs.status.invalid");
            }
        }
        String routeId = request.getRouteId();
        if (routeId != null && !routeId.isBlank() && !routeId.equalsIgnoreCase("NO-ROUTE")) {
            try {
                UUID.fromString(routeId.trim());
            } catch (IllegalArgumentException e) {
                throw Errors.badRequest("logs.route_id.invalid");
            }
        }
    }
}
