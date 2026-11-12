package dev.root101.api_gateway.features.http_logs.logic.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

/**
 * The filters of a log search, from the query of `GET /http-logs`. Every one is optional.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class HttpLogSearchRequest {

    private int page;

    private Integer size;

    private String query;

    private String method;

    /**
     * A status, or its prefix: `4` = 400..499, `47` = 470..479
     */
    private String status;

    /**
     * A route id, or `NO-ROUTE`
     */
    private String routeId;

    private OffsetDateTime from;

    private OffsetDateTime to;
}
