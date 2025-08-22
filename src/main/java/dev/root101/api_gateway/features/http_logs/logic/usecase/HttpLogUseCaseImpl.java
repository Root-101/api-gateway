package dev.root101.api_gateway.features.http_logs.logic.usecase;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.data.repo.HttpLogRepo;
import dev.root101.api_gateway.features.http_logs.data.repo.HttpLogSearchRepo;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogResponse;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchResponse;
import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.logic.usecase.RouteUseCase;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class HttpLogUseCaseImpl implements HttpLogUseCase {

    private final HttpLogRepo repo;
    private final HttpLogSearchRepo searchRepo;
    private final ValidationService vs;
    private final RouteUseCase routeUseCase;

    private final String adminBasePath;

    public HttpLogUseCaseImpl(
            HttpLogRepo repo, HttpLogSearchRepo searchRepo,
            ValidationService vs,
            @Value("${app.admin.base-path}")
            String adminBasePath,
            final RouteUseCase routeUseCase
    ) {
        this.repo = repo;
        this.searchRepo = searchRepo;
        this.vs = vs;
        this.adminBasePath = adminBasePath;
        this.routeUseCase = routeUseCase;
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
            if (routeEntity != null) {//replace the requested path with the final URL intended to access
                String finalRoute =
                        (routeEntity.getUri() + request.getRequestedPath())
                                .replaceAll(
                                        routeEntity.getRewritePathFrom(),
                                        routeEntity.getRewritePathTo()
                                );
                routeLog = new HttpLogEntity.RouteLog(
                        routeEntity.getRouteId().toString(),
                        routeEntity.getName(),
                        finalRoute
                );
            } else {//route == null
                boolean isToAdminPath = request.getRequestedPath().contains(adminBasePath);
                if (isToAdminPath) {
                    String finalRoute = request.getServerIp() + request.getRequestedPath();
                    routeLog = HttpLogEntity.RouteLog.admin(finalRoute);
                } else {
                    routeLog = null;
                }
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
            repo.save(entity)
                    .doOnError(err -> System.err.println("Error guardando log: " + err.getMessage()))
                    .doOnSuccess(unused -> System.out.println("Success save of log"))
                    .subscribe();
        } catch (Exception e) {
            System.out.println("se jodio algo guardando el log");
        }
    }

    @Override
    public Mono<HttpLogSearchResponse> search(HttpLogSearchRequest request) {
        return searchRepo.search(request)
                .map(page -> new HttpLogSearchResponse(
                        page.getNumber(),                // current page
                        page.getSize(),                  // page size
                        page.getTotalPages(),            // total pages
                        page.getTotalElements(),         // total elements
                        page                             // page content
                                .getContent()
                                .stream()
                                .map(this::toResponse)
                                .toList()                        // page content
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
