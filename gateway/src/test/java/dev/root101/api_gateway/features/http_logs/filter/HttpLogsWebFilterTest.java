package dev.root101.api_gateway.features.http_logs.filter;

import org.junit.jupiter.api.Test;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;

import java.net.InetSocketAddress;

import static org.assertj.core.api.Assertions.assertThat;

class HttpLogsWebFilterTest {

    private static String clientIp(String xff) {
        MockServerHttpRequest.BaseBuilder<?> request = MockServerHttpRequest.get("http://gw:8080/x")
                .remoteAddress(new InetSocketAddress("10.1.1.1", 5555));
        if (xff != null) request.header("X-Forwarded-For", xff);
        return HttpLogsWebFilter.getClientIp(MockServerWebExchange.from(request));
    }

    private static String serverIp(MockServerHttpRequest.BaseBuilder<?> request) {
        return HttpLogsWebFilter.getServerIp(MockServerWebExchange.from(request));
    }

    @Test
    void clientIp() {
        assertThat(clientIp(null)).isEqualTo("10.1.1.1");
        assertThat(clientIp("203.0.113.7")).isEqualTo("203.0.113.7");
        assertThat(clientIp(" 203.0.113.7 , 10.0.0.1, 10.0.0.2")).isEqualTo("203.0.113.7");
        assertThat(clientIp("")).isEqualTo("10.1.1.1");
        assertThat(clientIp(" , 10.0.0.1")).isEqualTo("10.1.1.1");
        assertThat(clientIp("2001:db8:85a3::8a2e:370:7334")).isEqualTo("2001:db8:85a3::8a2e:370:7334");
        assertThat(clientIp("x".repeat(80))).hasSize(50);
    }

    @Test
    void clientIpWithoutRemoteAddress() {
        assertThat(HttpLogsWebFilter.getClientIp(MockServerWebExchange.from(MockServerHttpRequest.get("/x")))).isNull();
    }

    @Test
    void serverIp() {
        assertThat(serverIp(MockServerHttpRequest.get("http://gw:8080/x"))).isEqualTo("http://gw:8080");
        assertThat(serverIp(MockServerHttpRequest.get("http://gw:80/x"))).isEqualTo("http://gw");
        assertThat(serverIp(MockServerHttpRequest.get("https://gw:443/x"))).isEqualTo("https://gw");
        assertThat(serverIp(MockServerHttpRequest.get("https://gw:80/x"))).isEqualTo("https://gw:80");

        assertThat(serverIp(MockServerHttpRequest.get("http://internal:8080/x")
                .header("X-Forwarded-Proto", "https")
                .header("X-Forwarded-Host", "api.example.com"))).isEqualTo("https://api.example.com");
        assertThat(serverIp(MockServerHttpRequest.get("http://internal:8080/x")
                .header("X-Forwarded-Proto", "https")
                .header("X-Forwarded-Host", "api.example.com")
                .header("X-Forwarded-Port", "8443"))).isEqualTo("https://api.example.com:8443");
        //host already with port: X-Forwarded-Port ignored
        assertThat(serverIp(MockServerHttpRequest.get("http://internal:8080/x")
                .header("X-Forwarded-Proto", "https")
                .header("X-Forwarded-Host", "api.example.com:9000")
                .header("X-Forwarded-Port", "8443"))).isEqualTo("https://api.example.com:9000");
    }
}
