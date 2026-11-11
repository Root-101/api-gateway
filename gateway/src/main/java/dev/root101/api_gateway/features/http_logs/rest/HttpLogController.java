package dev.root101.api_gateway.features.http_logs.rest;

import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchResponse;
import dev.root101.api_gateway.features.http_logs.logic.usecase.HttpLogUseCase;
import dev.root101.commons.exceptions.BadRequestException;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.time.OffsetDateTime;

/**
 * Http Logs controller for managing the http logs of gateway.
 * By default, is secured and only ROLE_GATEWAY_ADMIN can access (configured in global security config)
 * <br/>
 * This controller is ignored in logs... the requests made to this controller will not be logged.
 */
@RestController
@RequestMapping("/${app.admin.base-path}/http-logs")
public class HttpLogController {

    private final HttpLogUseCase httpLogUseCase;

    public HttpLogController(HttpLogUseCase httpLogUseCase) {
        this.httpLogUseCase = httpLogUseCase;
    }

    /**
     * Search the logs, newest first. Every filter is optional; an empty one is no filter.
     */
    @GetMapping
    public Mono<HttpLogSearchResponse> searchLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String method,
            @RequestParam(required = false) String status,
            @RequestParam(name = "route_id", required = false) String routeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        if (page < 0) {
            throw new BadRequestException("logs.page.invalid");
        }
        if (size != null && size < 1) {
            throw new BadRequestException("logs.size.invalid");
        }
        return httpLogUseCase.search(new HttpLogSearchRequest(page, size, query, method, status, routeId, from, to));
    }
}
