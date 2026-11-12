package dev.root101.api_gateway.features.http_logs.logic.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class HttpLogSearchResponse {
    private int page;
    private int size;
    private int totalPages;
    /**
     * Capped at `HttpLogSearchRepo.COUNT_CAP` (then `totalCapped` is true and there are more)
     */
    private long totalElements;

    private boolean totalCapped;

    private List<HttpLogResponse> items;
}
