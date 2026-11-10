package dev.root101.api_gateway.features.http_logs.data.repo;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.logic.model.HttpLogSearchRequest;
import dev.root101.commons.exceptions.BadRequestException;
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

import java.util.UUID;

@Repository
@AllArgsConstructor
public class HttpLogSearchRepo {

    private final R2dbcEntityTemplate template;

    //criteria use the entity property names (mapped to the columns by the template)
    public Mono<Page<HttpLogEntity>> search(HttpLogSearchRequest request, int size) {

        Criteria criteria = Criteria.empty();

        if (request.getMethod() != null && !request.getMethod().isBlank()) {
            criteria = criteria.and("httpMethod").like(contains(request.getMethod()));
        }
        if (request.getResponseCode() != null && !request.getResponseCode().isBlank()) {
            try {
                int[] range = responseCodeRange(request.getResponseCode().trim());
                criteria = criteria.and("responseCode")
                        .greaterThanOrEquals(range[0])
                        .and("responseCode")
                        .lessThanOrEquals(range[1]);
            } catch (NumberFormatException e) {
                throw new BadRequestException("response_code must be a number");
            }
        }
        if (request.getQuery() != null && !request.getQuery().isBlank()) {
            String likeQuery = contains(request.getQuery());

            Criteria orCriteria = Criteria.where("sourceIp").like(likeQuery)
                    .or("userAgent").like(likeQuery)
                    .or("path").like(likeQuery)
                    .or("rawRoute").like(likeQuery);

            criteria = criteria.and(orCriteria);
        }
        if (request.getRouteId() != null) {
            if (request.getRouteId().equalsIgnoreCase("NO-ROUTE")) {
                criteria = criteria.and("routeId").isNull();
            } else if (!request.getRouteId().isBlank()) {
                try {
                    criteria = criteria.and("routeId").is(UUID.fromString(request.getRouteId().trim()));
                } catch (IllegalArgumentException e) {
                    throw new BadRequestException("route_id must be a uuid or NO-ROUTE");
                }
            }
        }

        if (request.getFromDate() != null && request.getToDate() != null) {
            criteria = criteria.and("requestedAt")
                    .greaterThanOrEquals(request.getFromDate())
                    .and("requestedAt")
                    .lessThanOrEquals(request.getToDate());
        } else if (request.getFromDate() != null) {
            criteria = criteria.and("requestedAt").greaterThanOrEquals(request.getFromDate());
        } else if (request.getToDate() != null) {
            criteria = criteria.and("requestedAt").lessThanOrEquals(request.getToDate());
        }

        PageRequest pageRequest = PageRequest.of(
                request.getPage(),
                size,
                Sort.by(Sort.Direction.DESC, "requestedAt")
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

    /**
     * `[from, to]` of the codes matching the value: fewer than 3 digits is a prefix ("4" = 400..499, "47" = 470..479)
     *
     * @throws NumberFormatException if the value is not a number
     */
    static int[] responseCodeRange(String code) {
        int value = Integer.parseInt(code);
        int span = code.length() >= 3 ? 1 : (int) Math.pow(10, 3 - code.length());
        return new int[]{value * span, value * span + span - 1};
    }

    /**
     * `%value%` with the LIKE wildcards of the user input escaped (postgres default escape char is `\`)
     */
    static String contains(String value) {
        return "%" + value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
    }
}
