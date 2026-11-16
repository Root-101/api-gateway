package dev.root101.api_gateway.features.http_logs.filter;

import org.junit.jupiter.api.Test;
import org.springframework.cloud.gateway.filter.headers.TrustedProxies;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;

import java.net.InetSocketAddress;

import static org.assertj.core.api.Assertions.assertThat;

class HttpLogsWebFilterTest {

    private static final TrustedProxies ANY = TrustedProxies.from(".*");
    private static final TrustedProxies NONE = ip -> false;
    //the proxies of a private network
    private static final TrustedProxies PRIVATE = TrustedProxies.from("10\\..*");

    private static String clientIp(String xff, TrustedProxies trusted) {
        MockServerHttpRequest.BaseBuilder<?> request = MockServerHttpRequest.get("http://gw:8080/x")
                .remoteAddress(new InetSocketAddress("10.1.1.1", 5555));
        if (xff != null) request.header("X-Forwarded-For", xff);
        return HttpLogsWebFilter.getClientIp(MockServerWebExchange.from(request), trusted);
    }

    private static String serverIp(MockServerHttpRequest.BaseBuilder<?> request, TrustedProxies trusted) {
        return HttpLogsWebFilter.getServerIp(MockServerWebExchange.from(request.remoteAddress(new InetSocketAddress("10.1.1.1", 5555))), trusted);
    }

    /**
     * Every proxy trusted (the default `.*`): the first entry, as before `TRUSTED_PROXIES`.
     */
    @Test
    void clientIpTrustingAnyProxy() {
        assertThat(clientIp(null, ANY)).isEqualTo("10.1.1.1");
        assertThat(clientIp("203.0.113.7", ANY)).isEqualTo("203.0.113.7");
        assertThat(clientIp(" 203.0.113.7 , 10.0.0.1, 10.0.0.2", ANY)).isEqualTo("203.0.113.7");
        assertThat(clientIp("", ANY)).isEqualTo("10.1.1.1");
        //an empty entry: the client is unknown from there on, the last entry read is kept
        assertThat(clientIp(" , 10.0.0.1", ANY)).isEqualTo("10.0.0.1");
        assertThat(clientIp("2001:db8:85a3::8a2e:370:7334", ANY)).isEqualTo("2001:db8:85a3::8a2e:370:7334");
        assertThat(clientIp("x".repeat(80), ANY)).hasSize(50);
    }

    /**
     * No proxy trusted: `X-Forwarded-For` is ignored, the connection's ip is the client.
     */
    @Test
    void clientIpTrustingNoProxy() {
        assertThat(clientIp(null, NONE)).isEqualTo("10.1.1.1");
        assertThat(clientIp("203.0.113.7", NONE)).isEqualTo("10.1.1.1");
    }

    /**
     * Only some proxies trusted: from the right, the first entry that isn't a trusted proxy. The entries on its left
     * were sent by the client (a spoofed ip to dodge the lockout), never believed.
     */
    @Test
    void clientIpTrustingSomeProxies() {
        assertThat(clientIp("203.0.113.7", PRIVATE)).isEqualTo("203.0.113.7");
        assertThat(clientIp("1.2.3.4, 203.0.113.7", PRIVATE)).isEqualTo("203.0.113.7");
        assertThat(clientIp("1.2.3.4, 203.0.113.7, 10.0.0.2", PRIVATE)).isEqualTo("203.0.113.7");
        //every entry a trusted proxy: the leftmost one
        assertThat(clientIp("10.0.0.3, 10.0.0.2", PRIVATE)).isEqualTo("10.0.0.3");

        //the connection is not a trusted proxy: its X-Forwarded-For is ignored
        assertThat(HttpLogsWebFilter.getClientIp(MockServerWebExchange.from(MockServerHttpRequest.get("/x")
                .remoteAddress(new InetSocketAddress("198.51.100.1", 5555))
                .header("X-Forwarded-For", "203.0.113.7")), PRIVATE)).isEqualTo("198.51.100.1");
    }

    @Test
    void clientIpWithoutRemoteAddress() {
        assertThat(HttpLogsWebFilter.getClientIp(MockServerWebExchange.from(MockServerHttpRequest.get("/x")
                .header("X-Forwarded-For", "203.0.113.7")), ANY)).isNull();
    }

    @Test
    void serverIp() {
        assertThat(serverIp(MockServerHttpRequest.get("http://gw:8080/x"), ANY)).isEqualTo("http://gw:8080");
        assertThat(serverIp(MockServerHttpRequest.get("http://gw:80/x"), ANY)).isEqualTo("http://gw");
        assertThat(serverIp(MockServerHttpRequest.get("https://gw:443/x"), ANY)).isEqualTo("https://gw");
        assertThat(serverIp(MockServerHttpRequest.get("https://gw:80/x"), ANY)).isEqualTo("https://gw:80");

        assertThat(serverIp(MockServerHttpRequest.get("http://internal:8080/x")
                .header("X-Forwarded-Proto", "https")
                .header("X-Forwarded-Host", "api.example.com"), ANY)).isEqualTo("https://api.example.com");
        assertThat(serverIp(MockServerHttpRequest.get("http://internal:8080/x")
                .header("X-Forwarded-Proto", "https")
                .header("X-Forwarded-Host", "api.example.com")
                .header("X-Forwarded-Port", "8443"), ANY)).isEqualTo("https://api.example.com:8443");
        //host already with port: X-Forwarded-Port ignored
        assertThat(serverIp(MockServerHttpRequest.get("http://internal:8080/x")
                .header("X-Forwarded-Proto", "https")
                .header("X-Forwarded-Host", "api.example.com:9000")
                .header("X-Forwarded-Port", "8443"), ANY)).isEqualTo("https://api.example.com:9000");
        //not from a trusted proxy: its forwarded headers are ignored
        assertThat(serverIp(MockServerHttpRequest.get("http://internal:8080/x")
                .header("X-Forwarded-Proto", "https")
                .header("X-Forwarded-Host", "api.example.com"), NONE)).isEqualTo("http://internal:8080");
    }
}
