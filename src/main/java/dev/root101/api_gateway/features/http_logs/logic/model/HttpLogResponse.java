package dev.root101.api_gateway.features.http_logs.logic.model;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class HttpLogResponse {

    /**
     * Unique identified of the log.
     */
    private UUID id;

    private String sourceIp;

    private OffsetDateTime requestedAt;

    private String userAgent;

    private String httpMethod;

    private String path;

    private int responseCode;

    private int requestDuration;

    private HttpLogEntity.RouteLog route;

}
