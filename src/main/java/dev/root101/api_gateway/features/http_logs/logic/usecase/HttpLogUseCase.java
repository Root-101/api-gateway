package dev.root101.api_gateway.features.http_logs.logic.usecase;

import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogRequest;

public interface HttpLogUseCase {

    /**
     * Save an http log
     *
     * @param request The log to add
     */
    void saveHttpLog(HttpLogRequest request);

}
