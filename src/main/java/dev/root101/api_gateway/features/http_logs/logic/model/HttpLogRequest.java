package dev.root101.api_gateway.features.http_logs.logic.model;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.cloud.gateway.route.Route;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatusCode;

import java.time.OffsetDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class HttpLogRequest {
    private String clientIp;
    private String serverIp;
    private OffsetDateTime serverTime;
    private String userAgent;
    private HttpMethod httpMethod;
    private String requestedPath;
    private HttpStatusCode statusCode;
    private int duration;
    private Route route;
}
