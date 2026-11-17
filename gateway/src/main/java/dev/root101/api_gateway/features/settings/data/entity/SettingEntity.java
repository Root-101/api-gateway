package dev.root101.api_gateway.features.settings.data.entity;


import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * A setting of the gateway (`routeId` null) or of a route: one row per feature (`key`), its value a json
 */
@Data
@NoArgsConstructor
@AllArgsConstructor

@Table("setting")
public class SettingEntity {

    @Id
    @Column("setting_id")
    private UUID settingId;

    /**
     * The route it belongs to; null = the whole gateway
     */
    @Column("route_id")
    private UUID routeId;

    @Column("key")
    private String key;

    @Column("value")
    private SettingValue value;

    @Column("updated_at")
    private OffsetDateTime updatedAt;
}
