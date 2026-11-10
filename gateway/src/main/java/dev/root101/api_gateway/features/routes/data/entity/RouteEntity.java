package dev.root101.api_gateway.features.routes.data.entity;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.URL;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor

@Table("route")
public class RouteEntity {

    @Id
    @Column("route_id")
    private UUID routeId;

    @NotBlank
    @Size(max = 255)
    @Column("name")
    private String name;

    @NotBlank
    @Size(max = 255)
    @Column("path")
    private String path;

    @NotBlank
    @Size(max = 255)
    @URL
    @Column("uri")
    private String uri;

    @Size(max = 255)
    @Column("rewrite_path_from")
    private String rewritePathFrom;

    @Size(max = 255)
    @Column("rewrite_path_to")
    private String rewritePathTo;

    @Size()
    @Column("description")
    private String description;

    @Column("created_at")
    private OffsetDateTime createdAt;
}