package dev.root101.api_gateway.features.http_logs.data.repo;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class HttpLogSearchRepoTest {

    @Test
    void responseCodeRangeTreatsShortValuesAsPrefix() {
        assertThat(HttpLogSearchRepo.responseCodeRange("4")).containsExactly(400, 499);
        assertThat(HttpLogSearchRepo.responseCodeRange("47")).containsExactly(470, 479);
        assertThat(HttpLogSearchRepo.responseCodeRange("478")).containsExactly(478, 478);
        assertThat(HttpLogSearchRepo.responseCodeRange("2147483647")).containsExactly(Integer.MAX_VALUE, Integer.MAX_VALUE);
        assertThatThrownBy(() -> HttpLogSearchRepo.responseCodeRange("abc")).isInstanceOf(NumberFormatException.class);
    }

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
