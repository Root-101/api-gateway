package dev.root101.api_gateway.features.http_logs.logic.usecase;

import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchRequest;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchResponse;
import reactor.core.publisher.Mono;

public interface HttpLogUseCase {

    /**
     * Save an http log
     *
     * @param request The log to add
     */
    void saveHttpLog(HttpLogRequest request);

    Mono<HttpLogSearchResponse> search(HttpLogSearchRequest request);
}
