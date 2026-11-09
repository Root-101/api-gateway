package dev.root101.api_gateway.features.http_logs.data.repo;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class HttpLogSearchRepoTest {

    @Test
    void containsEscapesLikeWildcards() {
        assertThat(HttpLogSearchRepo.contains("abc")).isEqualTo("%abc%");
        assertThat(HttpLogSearchRepo.contains("50%")).isEqualTo("%50\\%%");
        assertThat(HttpLogSearchRepo.contains("a_b")).isEqualTo("%a\\_b%");
        assertThat(HttpLogSearchRepo.contains("c:\\dir")).isEqualTo("%c:\\\\dir%");
        //backslash escaped first, so it doesn't eat the escape of the `%`
        assertThat(HttpLogSearchRepo.contains("\\%")).isEqualTo("%\\\\\\%%");
    }
}
