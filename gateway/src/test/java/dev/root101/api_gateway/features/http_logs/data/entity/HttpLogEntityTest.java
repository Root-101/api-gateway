package dev.root101.api_gateway.features.http_logs.data.entity;

import org.junit.jupiter.api.Test;

import java.time.OffsetDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class HttpLogEntityTest {

    @Test
    void routeJsonRoundTrip() {
        HttpLogEntity.RouteLog route = new HttpLogEntity.RouteLog("id-1", "name", "http://host/x");
        HttpLogEntity entity = new HttpLogEntity(null, "ip", OffsetDateTime.now(), null, "GET", "/x", 200, 1, route);

        assertThat(entity.getRoute()).isEqualTo(route);
        //the stored json is camelCase (old rows and the route_id search rely on it)
        assertThat(route.toStringJson()).isEqualTo("{\"routeId\":\"id-1\",\"routeName\":\"name\",\"routePath\":\"http://host/x\"}");
        assertThat(HttpLogEntity.RouteLog.fromStringJson(route.toStringJson())).isEqualTo(route);
    }

    @Test
    void nullRoute() {
        HttpLogEntity entity = new HttpLogEntity(null, "ip", OffsetDateTime.now(), null, "GET", "/x", 200, 1, null);
        assertThat(entity.getRoute()).isNull();

        entity.setRawRoute(null);
        assertThat(entity.getRoute()).isNull();
        assertThat(HttpLogEntity.RouteLog.fromStringJson(null)).isNull();
    }

    @Test
    void adminRoute() {
        assertThat(HttpLogEntity.RouteLog.admin("http://gw/_admin/routes"))
                .isEqualTo(new HttpLogEntity.RouteLog("00000000-0000-0000-0000-000000000000", "Admin", "http://gw/_admin/routes"));
    }
}
