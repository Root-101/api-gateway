package dev.root101.api_gateway.features.http_logs.data.repo;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchRequest;
import lombok.AllArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.r2dbc.core.R2dbcEntityTemplate;
import org.springframework.data.relational.core.query.Criteria;
import org.springframework.data.relational.core.query.Query;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Repository
@AllArgsConstructor
public class HttpLogSearchRepo {

    private final R2dbcEntityTemplate template;

    public Mono<Page<HttpLogEntity>> search(HttpLogSearchRequest request) {

        Criteria criteria = Criteria.empty();

        if (request.getMethod() != null && !request.getMethod().isBlank()) {
            criteria = criteria.and("httpMethod").like("%" + request.getMethod() + "%");
        }
        if (request.getResponseCode() != null) {
            criteria = criteria.and("responseCode").is(request.getResponseCode());
        }
        if (request.getQuery() != null && !request.getQuery().isBlank()) {
            String likeQuery = "%" + request.getQuery() + "%";

            Criteria orCriteria = Criteria.where("source_ip").like(likeQuery)
                    .or("user_agent").like(likeQuery)
                    .or("path").like(likeQuery)
                    .or("route").like(likeQuery);

            criteria = criteria.and(orCriteria);
        }
        if (request.getRouteId() != null) {
            if (request.getRouteId().equalsIgnoreCase("NO-ROUTE")) {
                criteria = criteria.and("route").isNull();
            } else if (!request.getRouteId().isBlank()) {
                criteria = criteria.and("route").like("%" + request.getRouteId() + "%");
            }
        }

        PageRequest pageRequest = PageRequest.of(
                request.getPage(),
                request.getSize(),
                Sort.by(Sort.Direction.DESC, "requested_at")
        );
        Query query = Query.query(criteria)
                .with(pageRequest);

        Mono<Long> count = template.count(Query.query(criteria), HttpLogEntity.class);
        Flux<HttpLogEntity> users = template.select(query, HttpLogEntity.class);

        return users.collectList()
                .zipWith(count, (list, total) ->
                        new PageImpl<>(list, pageRequest, total)
                );
    }
}
