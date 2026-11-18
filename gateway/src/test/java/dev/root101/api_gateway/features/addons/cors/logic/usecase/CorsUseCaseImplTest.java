package dev.root101.api_gateway.features.addons.cors.logic.usecase;

import dev.root101.api_gateway.features.addons.base.data.entity.AddonEntity;
import dev.root101.api_gateway.features.addons.base.data.entity.AddonJson;
import dev.root101.api_gateway.features.addons.base.data.repo.AddonRepo;
import dev.root101.api_gateway.features.addons.cors.logic.model.Cors;
import dev.root101.api_gateway.features.addons.cors.logic.model.CorsResponse;
import dev.root101.api_gateway.features.routes.data.repo.RouteRepo;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * The migration of `CORS_ALLOWED_ORIGINS` into the gateway's add-on, once, and how the response tells about it
 */
@SuppressWarnings("removal")
class CorsUseCaseImplTest {

    private final ObjectMapper mapper = JsonMapper.builder().build();
    private final AddonRepo repo = mock(AddonRepo.class);

    private Cors seeded(String envOrigins) {
        when(repo.findByRouteIdIsNullAndType(Cors.TYPE)).thenReturn(Mono.empty());
        when(repo.save(any())).thenAnswer(call -> Mono.just(call.getArgument(0)));
        new CorsUseCaseImpl(repo, mock(RouteRepo.class), mapper, envOrigins).seed().block();
        ArgumentCaptor<AddonEntity> saved = ArgumentCaptor.forClass(AddonEntity.class);
        verify(repo).save(saved.capture());
        assertThat(saved.getValue().getRouteId()).isNull();
        return mapper.readValue(saved.getValue().getConfig().json(), Cors.class);
    }

    @Test
    void noEnvVarSeedsAnyOrigin() {
        assertThat(seeded("")).isEqualTo(new Cors(true, List.of("*"), false));
    }

    @Test
    void envVarSeedsItsOrigins() {
        assertThat(seeded(" https://a.com , https://*.b.com,")).isEqualTo(new Cors(true, List.of("https://a.com", "https://*.b.com"), false));
    }

    @Test
    void existingRowWinsOverTheEnvVar() {
        AddonEntity row = new AddonEntity(null, null, Cors.TYPE,
                new AddonJson(mapper.writeValueAsString(new Cors(true, List.of("https://console.com"), false))), null, null, null);
        when(repo.findByRouteIdIsNullAndType(Cors.TYPE)).thenReturn(Mono.just(row));
        new CorsUseCaseImpl(repo, mock(RouteRepo.class), mapper, "https://other.com").seed().block();
        verify(repo, never()).save(any());
    }

    private CorsResponse.EnvVar envVar(String envOrigins, List<String> inUse) {
        AddonEntity row = new AddonEntity(null, null, Cors.TYPE,
                new AddonJson(mapper.writeValueAsString(new Cors(true, inUse, false))), null, null, null);
        when(repo.findByType(Cors.TYPE)).thenReturn(Flux.just(row));
        CorsUseCaseImpl useCase = new CorsUseCaseImpl(repo, mock(RouteRepo.class), mapper, envOrigins);
        useCase.reload().block();
        CorsResponse response = useCase.gatewayResponse();
        assertThat(response.allowedOrigins()).isEqualTo(inUse);
        return response.envVar();
    }

    /**
     * Not set: nothing to tell. Set: whether it is the same as the add-on (any order) or ignored.
     */
    @Test
    void envVarInTheResponse() {
        assertThat(envVar("", List.of("*"))).isNull();
        assertThat(envVar("https://b.com, https://a.com", List.of("https://a.com", "https://b.com")))
                .isEqualTo(new CorsResponse.EnvVar("CORS_ALLOWED_ORIGINS", List.of("https://b.com", "https://a.com"), true));
        assertThat(envVar("https://a.com", List.of("https://a.com", "https://b.com")).matches()).isFalse();
    }

    @Test
    void anyOrigin() {
        assertThat(new Cors(true, List.of("*"), true).allowsAnyOrigin()).isTrue();
        assertThat(new Cors(true, List.of("https://a.com", "https://*"), true).allowsAnyOrigin()).isTrue();
        assertThat(new Cors(true, List.of("https://*:8080"), true).allowsAnyOrigin()).isTrue();
        assertThat(new Cors(true, List.of("https://*.a.com", "http://localhost:[*]"), true).allowsAnyOrigin()).isFalse();
    }
}
