package dev.root101.api_gateway.features.addons.data.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * An add-on of the gateway (`routeId` null) or of a route: one row per type
 */
@Data
@NoArgsConstructor
@AllArgsConstructor

@Table("addon")
public class AddonEntity {

    @Id
    @Column("addon_id")
    private UUID addonId;

    /**
     * The route it belongs to; null = the whole gateway
     */
    @Column("route_id")
    private UUID routeId;

    @Column("type")
    private String type;

    /**
     * What the admin sets
     */
    @Column("config")
    private AddonJson config;

    /**
     * What the gateway itself writes, null when there is nothing
     */
    @Column("state")
    private AddonJson state;

    @Column("created_at")
    private OffsetDateTime createdAt;

    /**
     * The last change of {@link #config}
     */
    @Column("updated_at")
    private OffsetDateTime updatedAt;
}
