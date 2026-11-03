package dev.root101.api_gateway.features.http_logs.data.entity;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.OffsetDateTime;
import java.util.UUID;

@NoArgsConstructor

@Table("http_log")
public class HttpLogEntity {

    @Getter
    @Setter
    @Id
    @Column("http_log_id")
    private UUID httpLogId;

    @Getter
    @Setter
    @Size(max = 50)
    @Column("source_ip")
    private String sourceIp;

    @Getter
    @Setter
    @NotNull
    @Column("requested_at")
    private OffsetDateTime requestedAt;

    @Getter
    @Setter
    @Column("user_agent")
    private String userAgent;

    @Getter
    @Setter
    @NotNull
    @Size(max = 25)
    @Column("http_method")
    private String httpMethod;

    @Getter
    @Setter
    @NotNull
    @Column("path")
    private String path;

    @Getter
    @Setter
    @NotNull
    @Column("response_code")
    private int responseCode;

    @Getter
    @Setter
    @NotNull
    @Column("request_duration")
    private int requestDuration;

    //R2DB is kinda stupid and dont parse complex types like the object itself or map or anything, solution: work with route as string parsing it to/from string
    //Cannot encode parameter of type java.util.HashMap ({})
    //Cannot encode parameter of type com.fasterxml.jackson.databind.JsonNode
    @Column("route")
    private String rawRoute;

    public HttpLogEntity(
            UUID httpLogId,
            String sourceIp,
            OffsetDateTime requestedAt,
            String userAgent,
            String httpMethod,
            String path,
            int responseCode,
            int requestDuration,
            RouteLog route
    ) {
        this.httpLogId = httpLogId;
        this.sourceIp = sourceIp;
        this.requestedAt = requestedAt;
        this.userAgent = userAgent;
        this.httpMethod = httpMethod;
        this.path = path;
        this.responseCode = responseCode;
        this.requestDuration = requestDuration;
        this.rawRoute = route == null ? null : route.toStringJson();
    }

    public RouteLog getRoute() {
        return rawRoute == null || rawRoute.isBlank() ? null : RouteLog.fromStringJson(rawRoute);
    }

    public void setRawRoute(RouteLog route) {
        this.rawRoute = route == null ? null : route.toStringJson();
    }

    public record RouteLog(
            @NotNull
            String routeId,

            @NotNull
            String routeName,

            @NotNull
            String routePath
    ) {
        public static RouteLog admin(String routePath) {
            return new RouteLog(
                    "00000000-0000-0000-0000-000000000000",
                    "Admin",
                    routePath
            );
        }

        public String toStringJson() {
            return RouteLogJson.MAPPER
                    .writeValueAsString(this);
        }

        public static RouteLog fromStringJson(String json) {
            if (json == null) return null;
            return RouteLogJson.MAPPER.readValue(json, RouteLog.class);
        }
    }
}