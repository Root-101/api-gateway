package dev.root101.api_gateway.core.feature.http_logs.logic.usecase;

import dev.root101.api_gateway.core.feature.http_logs.logic.model.HttpLogRequest;
import dev.root101.api_gateway.core.feature.http_logs.logic.model.SearchHttpLogRequest;
import dev.root101.api_gateway.core.feature.http_logs.logic.model.SearchHttpLogResponse;
import reactor.core.publisher.Mono;

public interface HttpLogUseCase {

    /**
     * Save an http log
     *
     * @param request The log to add
     */
    void saveHttpLog(HttpLogRequest request);

    Mono<SearchHttpLogResponse> search(SearchHttpLogRequest request);
}
