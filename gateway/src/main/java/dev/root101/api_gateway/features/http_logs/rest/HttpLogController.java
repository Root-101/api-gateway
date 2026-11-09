package dev.root101.api_gateway.features.http_logs.rest;

import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchResponse;
import dev.root101.api_gateway.features.http_logs.logic.usecase.HttpLogUseCase;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

/**
 * Http Logs controller for managing the http logs of gateway.
 * By default, is secured and only ROLE_GATEWAY_ADMIN can access (configured in global security config)
 * <br/>
 * This controller is ignored in logs... the requests made to this controller will not be logged.
 */
@RestController
@RequestMapping("/${app.admin.base-path}/http-log")
public class HttpLogController {

    private final HttpLogUseCase httpLogUseCase;
    private final ValidationService validationService;

    @Autowired
    public HttpLogController(
            HttpLogUseCase httpLogUseCase,
            ValidationService validationService
    ) {
        this.httpLogUseCase = httpLogUseCase;
        this.validationService = validationService;
    }

    /**
     * Get all routes
     *
     * @return Flux with all the routes
     */
    @PostMapping("/search")
    public Mono<HttpLogSearchResponse> searchLogs(@RequestBody final HttpLogSearchRequest request) {
        this.validationService.validate(request);

        return httpLogUseCase.search(request);
    }

}
