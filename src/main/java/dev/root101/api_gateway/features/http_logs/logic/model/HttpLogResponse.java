package dev.root101.api_gateway.features.http_logs.logic.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class HttpLogResponse {

    /**
     * Unique identified of the log.
     */
    private String id;
}
