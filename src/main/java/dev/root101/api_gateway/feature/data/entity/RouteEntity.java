package dev.root101.api_gateway.feature.data.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.validator.constraints.URL;

import java.io.Serializable;
import java.time.Instant;

@Data
@NoArgsConstructor
@AllArgsConstructor

@Entity(name = "route")
@Table(name = "route", schema = "public", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"name"})
})
public class RouteEntity implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Basic(optional = false)
    @Column(name = "route_id", nullable = false)
    private Integer routeId;

    @NotBlank
    @Size(max = 255)
    @Basic(optional = false)
    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @NotBlank
    @Size(max = 255)
    @Basic(optional = false)
    @Column(name = "path", nullable = false, length = 255)
    private String path;

    @NotBlank
    @Size(max = 255)
    @URL
    @Basic(optional = false)
    @Column(name = "uri", nullable = false, length = 255)
    private String uri;

    @Size(max = 255)
    @Basic(optional = false)
    @Column(name = "rewrite_path_from", nullable = true, length = 255)
    private String rewritePathFrom;

    @Size(max = 255)
    @Basic(optional = false)
    @Column(name = "rewrite_path_to", nullable = true, length = 255)
    private String rewritePathTo;

    @Size(max = 2147483647)
    @Basic(optional = false)
    @Column(name = "description", nullable = true, length = 2147483647)
    private String description;

    @Basic(optional = false)
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
