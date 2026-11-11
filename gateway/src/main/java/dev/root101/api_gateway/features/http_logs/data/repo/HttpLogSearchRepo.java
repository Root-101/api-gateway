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
import org.springframework.data.r2dbc.core.StatementMapper;
import org.springframework.data.relational.core.sql.SqlIdentifier;
import org.springframework.r2dbc.core.PreparedOperation;
import org.springframework.data.relational.core.query.Criteria;
import org.springframework.data.relational.core.query.Query;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
@AllArgsConstructor
public class HttpLogSearchRepo {

    /**
     * Above this many matching logs, the total of a search is reported as capped
     */
    public static final int COUNT_CAP = 100_000;

    private final R2dbcEntityTemplate template;

    //criteria use the entity property names (mapped to the columns by the template)
    public Mono<Page<HttpLogEntity>> search(HttpLogSearchRequest request, int size) {

        Criteria criteria = Criteria.empty();

        if (request.getMethod() != null && !request.getMethod().isBlank()) {
            criteria = criteria.and(Criteria.where("httpMethod").like(contains(request.getMethod())).ignoreCase(true));
        }
        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            try {
                int[] range = responseCodeRange(request.getStatus().trim());
                criteria = criteria.and("responseCode")
                        .greaterThanOrEquals(range[0])
                        .and("responseCode")
                        .lessThanOrEquals(range[1]);
            } catch (NumberFormatException e) {
                throw new BadRequestException("status must be a number");
            }
        }
        if (request.getQuery() != null && !request.getQuery().isBlank()) {
            String likeQuery = contains(request.getQuery());

            Criteria orCriteria = Criteria.where("sourceIp").like(likeQuery).ignoreCase(true)
                    .or(Criteria.where("userAgent").like(likeQuery).ignoreCase(true))
                    .or(Criteria.where("path").like(likeQuery).ignoreCase(true))
                    .or(Criteria.where("rawRoute").like(likeQuery).ignoreCase(true));

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

        if (request.getFrom() != null) {
            criteria = criteria.and("requestedAt").greaterThanOrEquals(request.getFrom());
        }
        if (request.getTo() != null) {
            criteria = criteria.and("requestedAt").lessThanOrEquals(request.getTo());
        }

        PageRequest pageRequest = PageRequest.of(
                request.getPage(),
                size,
                Sort.by(Sort.Direction.DESC, "requestedAt")
        );
        Query query = Query.query(criteria)
                .with(pageRequest);

        Flux<HttpLogEntity> users = template.select(query, HttpLogEntity.class);

        return users.collectList()
                .zipWith(cappedCount(criteria), (list, total) ->
                        new PageImpl<>(list, pageRequest, total)
                );
    }

    /**
     * Matching rows, counted up to `COUNT_CAP + 1` (more than the cap means "at least that many"): a plain
     * `count(*)` scans every matching row of a table that can hold millions, on every page
     */
    private Mono<Long> cappedCount(Criteria criteria) {
        StatementMapper mapper = template.getDataAccessStrategy().getStatementMapper().forType(HttpLogEntity.class);
        SqlIdentifier table = template.getConverter().getMappingContext()
                .getRequiredPersistentEntity(HttpLogEntity.class).getQualifiedTableName();
        PreparedOperation<?> select = mapper.getMappedObject(mapper.createSelect(table)
                .withProjection(SqlIdentifier.unquoted("http_log_id"))
                .withCriteria(criteria)
                .limit(COUNT_CAP + 1));
        return template.getDatabaseClient().sql(select).map((row, meta) -> 1).all().count();
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
