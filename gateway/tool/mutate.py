#!/usr/bin/env python3
"""
Targeted mutation testing (see CONTRIBUTING.md, "Mutation testing").

One mutation per business rule: each one changes an exact piece of src/main and names the one test that must
fail with it. The script applies each mutation, runs that test, expects it to FAIL, and restores the file.

    python tool/mutate.py                 # every mutation
    python tool/mutate.py routes. auth.   # only the ids starting with these
    python tool/mutate.py --list

Verdicts: KILLED (the test failed: ok), SURVIVED (the test passed: fix the test, never drop the mutation),
COMPILE ERROR / NO TESTS (fix the mutation or its test filter), BAD PATTERN (the old text is not there exactly once).

Restores from the original bytes kept in memory (never `git checkout`: it would also wipe uncommitted work) and
checks that `git diff -- src/main` is the same before and after. If the script is killed midway, the current
mutation stays applied: check that diff and restore it by hand.
"""
import hashlib
import os
import subprocess
import sys
import time
from pathlib import Path

GATEWAY = Path(__file__).resolve().parent.parent
SRC = GATEWAY / "src/main/java/dev/root101/api_gateway"
GRADLEW = str(GATEWAY / ("gradlew.bat" if os.name == "nt" else "gradlew"))

# (id, file under SRC, old text (exactly once), new text, test that must fail: `Class` or `Class.method`)
HC = "core/feature/addons/health_check/logic/usecase/HealthCheckUseCase_Impl.java"
RL = "core/feature/addons/rate_limit/logic/usecase/RateLimitUseCase_Impl.java"

MUTATIONS = [
    # --- route rules
    ("routes.rule.leading_slash", "core/feature/routes/logic/model/RouteRules.java",
     '&& !route.getPath().startsWith("/")) {', "&& false) {", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.path_pattern", "core/feature/routes/logic/model/RouteRules.java",
     "PathPatternParser.defaultInstance.parse(route.getPath());", "route.getPath();", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.uri_without_path", "core/feature/routes/logic/model/RouteRules.java",
     'if (uriPath != null && !uriPath.isEmpty() && !uriPath.equals("/")) {', "if (false) {", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.uri_trailing_slash_ok", "core/feature/routes/logic/model/RouteRules.java",
     ' && !uriPath.equals("/")', "", "ValidationIT.edgeValuesAreValid"),
    ("routes.rule.replace_from_regex", "core/feature/routes/logic/model/RouteRules.java",
     "Pattern.compile(route.getRewritePath().getReplaceFrom());", "route.getRewritePath().getReplaceFrom();", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.list_index", "config/GlobalExceptionHandlerConfig.java",
     '"[%d].".formatted(errors.getContainerIndex())', '""', "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.on_the_route", "core/feature/routes/logic/model/RouteRequest.java",
     "@ValidRoute\npublic class RouteRequest {", "public class RouteRequest {", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.rewrite_path_cascade", "core/feature/routes/logic/model/RouteRequest.java",
     "    @Valid\n    private RewritePathModel rewritePath;", "    private RewritePathModel rewritePath;", "ValidationIT.invalidRouteFieldIs422"),

    # --- every write endpoint validates the body (bean validation and route rules: `@Valid`)
    ("routes.post.validate", "core/feature/routes/rest/RouteController.java",
     "create(@Valid @RequestBody", "create(@RequestBody", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.batch.validate", "core/feature/routes/rest/RouteController.java",
     "createBatch(@RequestBody List<@Valid RouteRequest>", "createBatch(@RequestBody List<RouteRequest>", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.replace.validate", "core/feature/routes/rest/RouteController.java",
     "replaceAll(@RequestBody List<@Valid RouteRequest>", "replaceAll(@RequestBody List<RouteRequest>", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.edit.validate", "core/feature/routes/rest/RouteController.java",
     "String routeId, @Valid @RequestBody RouteRequest", "String routeId, @RequestBody RouteRequest", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.validate.validate", "core/feature/routes/rest/RouteController.java",
     "validate(@Valid @RequestBody", "validate(@RequestBody", "ValidationIT.invalidRouteFieldIs422"),
    ("auth.login.validate", "core/feature/auth/rest/AuthController.java",
     "login(@Valid @RequestBody", "login(@RequestBody", "ValidationIT.invalidLoginFieldIs422"),

    # --- routes use case
    ("routes.duplicated_in_list", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "entry.getValue().size() > 1", "entry.getValue().size() > 2", "RoutesIT.duplicatedNamesAre409"),
    ("routes.duplicated_in_db", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "request -> routeRepo.findByName(request.getName())", 'request -> routeRepo.findByName("-never-a-name-")', "RoutesIT.duplicatedNamesAre409"),
    ("routes.batch.transaction", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "entities -> routeRepo.saveAll(entities).collectList().as(tx::transactional)", "entities -> routeRepo.saveAll(entities).collectList()",
     "RoutesIT.batchFailingHalfwayRollsBack"),
    ("routes.replace.transaction", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "\n                                            .as(tx::transactional)", "",
     "RoutesIT.replaceFailingHalfwayRollsBack"),
    ("routes.replace.keeps_id", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "entity.setRouteId(old.getRouteId());", "", "RoutesIT.replaceSwapsAllTheRoutes"),
    ("routes.replace.keeps_created_at", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "entity.setCreatedAt(old.getCreatedAt());", "", "RoutesIT.replaceSwapsAllTheRoutes"),
    ("routes.replace.unloads_removed", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "return Flux.fromIterable(removed)", "return Flux.<RouteEntity>empty()", "RoutesIT.replaceSwapsAllTheRoutes"),
    ("routes.edit.own_name_ok", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     ".filter(existing -> !existing.getRouteId().equals(oldRoute.getRouteId()))", ".filter(existing -> true)",
     "RoutesIT.editRouteWithDuplicatedName"),
    ("routes.edit.name_taken", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     ".filter(existing -> !existing.getRouteId().equals(oldRoute.getRouteId()))", ".filter(existing -> false)",
     "RoutesIT.editRouteWithDuplicatedName"),
    ("routes.edit.keeps_created_at", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "entityToEdit.setCreatedAt(oldRoute.getCreatedAt());", "", "RoutesIT.editChangesTheRouting"),
    ("routes.edit.refreshes_gateway", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     ".flatMap(saved -> apply(List.of(saved), List.of()))", ".map(saved -> List.of(saved))", "RoutesIT.editChangesTheRouting"),
    ("routes.delete.normalized_id", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "String id = route.getRouteId().toString();", "String id = routeId;", "RoutesIT.deleteRouteWithUppercaseId"),
    ("routes.not_found", "core/feature/routes/data/repo/RouteRepo.java",
     "Errors.notFound(\"route.not_found\"", "Errors.badRequest(\"route.not_found\"", "RoutesIT.unknownIdIs404"),
    # the bug it pins: routes loaded async, after the server already takes traffic
    ("routes.loaded_before_traffic", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     ".count()\n                .block(Duration.ofSeconds(60));",
     ".count()\n                .delaySubscription(Duration.ofSeconds(5)).subscribe() == null ? 0L : 0L;",
     "RoutesIT.routesLoadedBeforeTraffic"),
    ("routes.rewrite_filter", "core/feature/routes/logic/usecase/RouteDefinitionMapper.java",
     "if (routeEntity.getRewritePathFrom() != null && routeEntity.getRewritePathTo() != null) {", "if (false) {",
     "RoutesIT.editChangesTheRouting"),

    # --- auth and lockout
    ("auth.credentials_both", "security/AdminAuthenticationManager.java",
     "equalsConstantTime(username, adminUsername) & equalsConstantTime", "equalsConstantTime(username, adminUsername) | equalsConstantTime",
     "SecurityIT.wrongCredentials"),
    ("auth.only_admin_prefix", "security/AdminAuthenticationWebFilter.java",
     'if (!path.equals(adminBasePath) && !path.startsWith(adminBasePath + "/")) {', "if (!path.contains(adminBasePath)) {",
     "SecurityIT.proxiedPathContainingAdminIsNotIntercepted"),
    ("auth.health_not_a_try", "security/AdminAuthenticationWebFilter.java",
     'if (path.equals(adminBasePath + "/health")) {', "if (false) {", "SecurityIT.basicOnHealthDoesNotCount"),
    ("auth.only_post_login_is_a_try", "security/AdminAuthenticationWebFilter.java",
     ' && exchange.getRequest().getMethod() == HttpMethod.POST', "", "SecurityIT.optionsToLoginDoesNotResetTheLockout"),
    ("auth.lockout_on_basic", "security/AdminAuthenticationWebFilter.java",
     "if ((isLogin || isBasic) && !loginAttemptsGuard.tryAcquire(clientIp)) {", "if (isLogin && !loginAttemptsGuard.tryAcquire(clientIp)) {",
     "SecurityIT.lockoutAfterFailedAttempts"),
    ("auth.lockout_message_minutes", "security/AdminAuthenticationWebFilter.java",
     'seconds >= 60 ? "auth.locked.minutes"', 'seconds >= 6000 ? "auth.locked.minutes"', "SecurityIT.lockoutAfterFailedAttempts"),
    ("auth.basic_success_resets", "security/AdminAuthenticationWebFilter.java",
     ".doOnNext(auth -> loginAttemptsGuard.succeeded(clientIp))", "", "SecurityIT.successfulLoginResetsFailedAttempts"),
    ("auth.login_success_resets", "security/AdminAuthenticationWebFilter.java",
     "if (status == null || status.is2xxSuccessful()) loginAttemptsGuard.succeeded(clientIp);", "",
     "SecurityIT.successfulLoginResetsFailedAttempts"),
    ("auth.only_success_resets", "security/AdminAuthenticationWebFilter.java",
     "if (status == null || status.is2xxSuccessful())", "if (true)", "SecurityIT.lockoutAfterFailedAttempts"),
    ("auth.bearer_checked", "security/AdminAuthenticationWebFilter.java",
     " && adminTokens.isValid(header.substring(BEARER.length()))", "", "SecurityIT.bearerToken"),
    ("auth.token_expires", "security/AdminTokens.java",
     "return expiration != null && System.currentTimeMillis() < expiration;", "return expiration != null;", "ExpiredTokenIT"),
    ("auth.lockout_limit", "security/LoginAttemptsGuard.java",
     "if (f.count() >= maxFailedAttempts) return f;", "if (f.count() > maxFailedAttempts) return f;", "SecurityIT.lockoutAfterFailedAttempts"),

    # --- what gets logged
    ("logs.skip_admin_get", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     "&& httpMethod == HttpMethod.GET)", "&& httpMethod == HttpMethod.DELETE)", "HttpLogsIT.whatIsAndIsNotLogged"),
    ("logs.skip_validate", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     '|| requestedPath.equals("/%s/routes/validate".formatted(adminBasePath))', "", "HttpLogsIT.whatIsAndIsNotLogged"),
    ("logs.skip_preflight", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     "|| CorsUtils.isPreFlightRequest(exchange.getRequest())", "", "HttpLogsIT.whatIsAndIsNotLogged"),
    ("logs.skip_health", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     '|| requestedPath.equals("/%s/health".formatted(adminBasePath))', "", "HttpLogsIT.whatIsAndIsNotLogged"),
    # --- client ip and TRUSTED_PROXIES
    ("ip.first_forwarded_ip", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     "if (trustsAny || !trustedProxies.isTrusted(tempClientIp)) break;", "break;",
     "HttpLogsWebFilterTest.clientIpTrustingSomeProxies"),
    ("ip.any_trusts_one_hop", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     "if (trustsAny || !trustedProxies.isTrusted(tempClientIp)) break;", "if (!trustedProxies.isTrusted(tempClientIp)) break;",
     "HttpLogsIT.logRouteWithoutRewriteAndLongForwardedFor"),
    ("ip.only_from_trusted_proxy", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     "if (forwardedFor != null && isTrustedProxy(tempClientIp, trustedProxies)) {", "if (forwardedFor != null) {",
     "UntrustedProxyIT.spoofedForwardedForIsIgnored"),
    ("ip.rightmost_untrusted", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     "if (trustsAny || !trustedProxies.isTrusted(tempClientIp)) break;", "",
     "HttpLogsWebFilterTest.clientIpTrustingSomeProxies"),
    ("ip.server_from_trusted_proxy", "core/feature/http_logs/filter/HttpLogsWebFilter.java",
     "boolean fromProxy = isTrustedProxy(connectionIp(exchange), trustedProxies);", "boolean fromProxy = true;",
     "HttpLogsWebFilterTest.serverIp"),
    ("ip.empty_trusts_none", "config/ServiceConfig.java",
     "return regex.isBlank() ? ip -> false : TrustedProxies.from(regex);", "return TrustedProxies.from(regex.isBlank() ? \".*\" : regex);",
     "ServiceConfigTest.trustedProxies"),
    ("logs.admin_route", "core/feature/http_logs/logic/usecase/HttpLogUseCase_Impl.java",
     "} else if (isAdminPath(request.getRequestedPath())) {", "} else if (false) {", "HttpLogsIT.whatIsAndIsNotLogged"),
    ("logs.final_route_rewrite", "core/feature/http_logs/logic/usecase/HttpLogUseCase_Impl.java",
     "if (route.getRewritePathFrom() != null && route.getRewritePathTo() != null) {", "if (false) {", "HttpLogsIT.logRouteWithRewrite"),

    # --- log search
    ("logs.search.size_cap", "core/feature/http_logs/logic/usecase/HttpLogUseCase_Impl.java",
     "Math.min(request.getSize() != null ? request.getSize() : DEFAULT_PAGE_SIZE, maxSearchSize)",
     "(request.getSize() != null ? request.getSize() : DEFAULT_PAGE_SIZE)", "HttpLogsIT.searchLogs"),
    ("logs.search.page_min", "core/feature/http_logs/logic/usecase/HttpLogUseCase_Impl.java",
     "if (request.getPage() < 0) {", "if (request.getPage() < -1) {", "HttpLogsIT.searchWithInvalidParamIs400"),
    ("logs.search.size_min", "core/feature/http_logs/logic/usecase/HttpLogUseCase_Impl.java",
     "getSize() != null && request.getSize() < 1", "getSize() != null && request.getSize() < 0", "HttpLogsIT.searchWithInvalidParamIs400"),
    ("logs.search.status_prefix", "core/feature/http_logs/data/repo/HttpLogSearchRepo.java",
     "(int) Math.pow(10, 3 - code.length())", "10", "HttpLogsIT.searchLogs"),
    ("logs.search.query_path", "core/feature/http_logs/data/repo/HttpLogSearchRepo.java",
     '.or(Criteria.where("path").like(likeQuery).ignoreCase(true))', "", "HttpLogsIT.searchLogs"),
    ("logs.search.method_ignore_case", "core/feature/http_logs/data/repo/HttpLogSearchRepo.java",
     'Criteria.where("httpMethod").like(contains(request.getMethod())).ignoreCase(true)',
     'Criteria.where("httpMethod").like(contains(request.getMethod())).ignoreCase(false)', "HttpLogsIT.searchIsCaseInsensitive"),
    ("logs.search.no_route", "core/feature/http_logs/data/repo/HttpLogSearchRepo.java",
     'criteria = criteria.and("routeId").isNull();', 'criteria = criteria.and("routeId").isNotNull();', "HttpLogsIT.searchLogs"),
    ("logs.search.from", "core/feature/http_logs/data/repo/HttpLogSearchRepo.java",
     'criteria.and("requestedAt").greaterThanOrEquals(request.getFrom())', 'criteria.and("requestedAt").lessThanOrEquals(request.getFrom())',
     "HttpLogsIT.searchLogs"),
    ("logs.search.to", "core/feature/http_logs/data/repo/HttpLogSearchRepo.java",
     'criteria.and("requestedAt").lessThanOrEquals(request.getTo())', 'criteria.and("requestedAt").greaterThanOrEquals(request.getTo())',
     "HttpLogsIT.searchLogs"),
    ("logs.search.escape_underscore", "core/feature/http_logs/data/repo/HttpLogSearchRepo.java",
     '.replace("_", "\\\\_")', "", "HttpLogsIT.searchLogs"),
    ("logs.search.newest_first", "core/feature/http_logs/data/repo/HttpLogSearchRepo.java",
     'Sort.Direction.DESC, "requestedAt"', 'Sort.Direction.ASC, "requestedAt"', "HttpLogsIT.searchLogs"),
    ("logs.cleanup.days", "core/feature/http_logs/task/CleanUpOldLogs.java",
     "OffsetDateTime.now().minusDays(maintainLogsFor)", "OffsetDateTime.now().minusDays(maintainLogsFor + 1)", "HttpLogsIT.cleanUpOldLogs"),

    # --- add-ons: maintenance
    ("maintenance.enabled", "core/feature/addons/maintenance/logic/model/Maintenance.java",
     "return Boolean.TRUE.equals(enabled);", "return enabled != null;", "MaintenanceIT.routeMaintenance"),
    ("maintenance.route", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "return route != null && route.config().on() ? route.config() : null;", "return null;", "MaintenanceIT.routeMaintenance"),
    ("maintenance.gateway", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "        if (current.gateway() != null && current.gateway().config().on()) return current.gateway().config();\n", "",
     "MaintenanceIT.gatewayWins"),
    ("maintenance.gateway_wins", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "        if (current.gateway() != null && current.gateway().config().on()) return current.gateway().config();\n"
     "        Entry route = current.routes().get(routeId);\n"
     "        return route != null && route.config().on() ? route.config() : null;",
     "        Entry route = current.routes().get(routeId);\n"
     "        if (route != null && route.config().on()) return route.config();\n"
     "        return current.gateway() != null && current.gateway().config().on() ? current.gateway().config() : null;",
     "MaintenanceIT.gatewayWins"),
    ("maintenance.gateway_right_away", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "                .flatMap(addon -> write(addon, maintenance))\n                .then(reload())",
     "                .flatMap(addon -> write(addon, maintenance))", "MaintenanceIT.gatewayWins"),
    ("maintenance.route_right_away", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "                .flatMap(route -> save(route.getRouteId(), maintenance))\n                .then(reload())",
     "                .flatMap(route -> save(route.getRouteId(), maintenance))", "MaintenanceIT.routeMaintenance"),
    ("maintenance.enable_right_away", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "                .flatMap(addon -> enable(addon, enabled))\n                .then(reload())\n                .then(Mono.fromSupplier(() -> ofRoute(",
     "                .flatMap(addon -> enable(addon, enabled))\n                .then(Mono.fromSupplier(() -> ofRoute(",
     "MaintenanceIT.routeMaintenance"),
    ("maintenance.enable_keeps_the_rest", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "new Maintenance(enabled, current.message(), current.retryAfter())", "new Maintenance(enabled, null, null)",
     "MaintenanceIT.routeMaintenance"),
    ("maintenance.enable_route_not_configured", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "\n                        .switchIfEmpty(Mono.error(Errors.notFound(\"maintenance.route.not_found\", routeId))))",
     ")", "MaintenanceIT.routeMaintenance"),
    ("maintenance.enable_gateway_not_configured", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "                .switchIfEmpty(Mono.error(Errors.notFound(\"maintenance.gateway.not_found\")))\n", "",
     "MaintenanceIT.gatewayNotConfigured"),
    ("maintenance.delete", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     ".flatMap(route -> save(route.getRouteId(), null))", ".flatMap(route -> Mono.<Void>empty())", "MaintenanceIT.routeMaintenance"),
    ("maintenance.state.on", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "if (!wasOn && maintenance.on()) times = new MaintenanceState(now, times.disabledAt());", "",
     "MaintenanceIT.stateOnlyOnRealChanges"),
    ("maintenance.state.off", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "if (wasOn && !maintenance.on()) times = new MaintenanceState(times.enabledAt(), now);", "",
     "MaintenanceIT.stateOnlyOnRealChanges"),
    ("maintenance.state.real_change", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "boolean wasOn = before != null && before.on();", "boolean wasOn = false;", "MaintenanceIT.stateOnlyOnRealChanges"),
    ("maintenance.default_message", "core/feature/addons/maintenance/filter/MaintenanceFilter.java",
     "maintenance.message() != null && !maintenance.message().isBlank()", "maintenance.message() != null",
     "MaintenanceIT.defaultMessageAndRetryAfter"),
    ("maintenance.default_message_field", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "messages.getMessage(\"maintenance.default\", null, locale),", "null,", "MaintenanceIT.routeMaintenance"),
    ("maintenance.retry_after_ahead", "core/feature/addons/maintenance/filter/MaintenanceFilter.java",
     "if (millis > 0) {", "if (true) {", "MaintenanceIT.defaultMessageAndRetryAfter"),
    ("maintenance.skip_unreadable", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "if (config == null || config.enabled() == null) {", "if (config == null) {", "MaintenanceIT.unreadableRowsAreSkipped"),
    ("maintenance.read_tolerant", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "        } catch (RuntimeException e) {\n            return null;", "        } catch (RuntimeException e) {\n            throw e;",
     "MaintenanceIT.unreadableRowsAreSkipped"),
    ("maintenance.gateway.validate", "core/feature/addons/maintenance/rest/MaintenanceController.java",
     "setGateway(@Valid @RequestBody", "setGateway(@RequestBody", "MaintenanceIT.invalidMaintenance"),
    ("maintenance.route.validate", "core/feature/addons/maintenance/rest/MaintenanceController.java",
     "setRoute(@PathVariable(\"route-id\") String routeId, @Valid @RequestBody", "setRoute(@PathVariable(\"route-id\") String routeId, @RequestBody",
     "MaintenanceIT.invalidMaintenance"),
    ("maintenance.delete_gateway", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "findByRouteIdIsNullAndType(Maintenance.TYPE)\n                .flatMap(addonRepo::delete)\n                .then(reload());",
     "findByRouteIdIsNullAndType(Maintenance.TYPE)\n                .then(reload());", "MaintenanceIT.gatewayNotConfigured"),
    ("maintenance.delete_gateway_right_away", "core/feature/addons/maintenance/logic/usecase/MaintenanceUseCase_Impl.java",
     "findByRouteIdIsNullAndType(Maintenance.TYPE)\n                .flatMap(addonRepo::delete)\n                .then(reload());",
     "findByRouteIdIsNullAndType(Maintenance.TYPE)\n                .flatMap(addonRepo::delete);", "MaintenanceIT.gatewayNotConfigured"),
    # --- add-ons: health check
    ("health_check.rerun_on_uri_change", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "boolean uriChanged = !entityToEdit.getUri().equals(oldRoute.getUri());",
     "boolean uriChanged = false;", "HealthCheckIT.editedUri"),
    ("health_check.rerun_only_on_uri_change", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "boolean uriChanged = !entityToEdit.getUri().equals(oldRoute.getUri());",
     "boolean uriChanged = true;", "HealthCheckIT.editedUri"),
    ("health_check.rerun_runs", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     "healthCheckUseCase.ofRoute(routeId) == null ? Mono.empty() : healthCheckUseCase.run(routeId).then()",
     "Mono.empty()", "HealthCheckIT.editedUri"),
    ("health_check.up_only_2xx", HC,
     "status != null && status >= 200 && status < 300", "status != null", "HealthCheckIT.routeHealthCheck"),
    ("health_check.same_host", HC,
     'URI.create(uri.replaceAll("/+$", "") + path)', "URI.create(uri).resolve(path)", "HealthCheckIT.unreachableAndSameHost"),
    ("health_check.no_answer_is_down", HC,
     ".onErrorResume(e -> Mono.just(result(start, null)))", "", "HealthCheckIT.unreachableAndSameHost"),
    ("health_check.run_calls", HC,
     ".flatMap(route -> check(route, read(addon.getConfig(), HealthCheck.class))))", ".then())", "HealthCheckIT.routeHealthCheck"),
    ("health_check.run_answers_new_result", HC,
     "objectMapper.writeValueAsString(result)))\n                .then(reload());",
     "objectMapper.writeValueAsString(result)))\n                .then();", "HealthCheckIT.routeHealthCheck"),
    ("health_check.only_state_written", "core/feature/addons/base/data/repo/AddonRepo.java",
     "SET state = CAST(:state AS jsonb) WHERE", "SET state = CAST(:state AS jsonb), updated_at = now() WHERE", "HealthCheckIT.scheduler"),
    ("health_check.scheduler_calls", HC,
     "                    .flatMap(route -> check(route, entry.config()))\n", "", "HealthCheckIT.scheduler"),
    ("health_check.scheduler_only_on", HC,
     "            if (!entry.config().on()) return;\n", "", "HealthCheckIT.scheduler"),
    ("health_check.scheduler_only_due", HC,
     "if (last != null && last.plusSeconds(entry.config().intervalSeconds()).isAfter(now)) return;", "", "HealthCheckIT.scheduler"),
    ("health_check.enabled", "core/feature/addons/health_check/logic/model/HealthCheck.java",
     "return Boolean.TRUE.equals(enabled);", "return enabled != null;", "HealthCheckIT.scheduler"),
    ("health_check.route_right_away", HC,
     "                .flatMap(route -> save(route.getRouteId(), healthCheck))\n                .then(reload())",
     "                .flatMap(route -> save(route.getRouteId(), healthCheck))", "HealthCheckIT.routeHealthCheck"),
    ("health_check.enable_keeps_the_rest", HC,
     "new HealthCheck(enabled, current.path(), current.intervalSeconds())", 'new HealthCheck(enabled, "/", 10)',
     "HealthCheckIT.routeHealthCheck"),
    ("health_check.enable_right_away", HC,
     "                })\n                .then(reload())\n", "                })\n", "HealthCheckIT.routeHealthCheck"),
    ("health_check.not_configured", HC,
     '\n                .switchIfEmpty(Mono.error(Errors.notFound("health_check.route.not_found", routeId)));',
     ";", "HealthCheckIT.routeHealthCheck"),
    ("health_check.delete", HC,
     ".flatMap(route -> save(route.getRouteId(), null))", ".flatMap(route -> Mono.<Void>empty())", "HealthCheckIT.routeHealthCheck"),
    ("health_check.update_keeps_state", HC,
     "        addon.setConfig(new AddonJson(objectMapper.writeValueAsString(healthCheck)));\n",
     "        addon.setConfig(new AddonJson(objectMapper.writeValueAsString(healthCheck)));\n        addon.setState(null);\n",
     "HealthCheckIT.routeHealthCheck"),
    ("health_check.skip_unreadable", HC,
     "if (addon.getRouteId() == null || !valid(config)) {", "if (config == null) {", "HealthCheckIT.unreadableRowsAreSkipped"),
    ("health_check.run_only_readable", HC,
     "                .filter(addon -> valid(read(addon.getConfig(), HealthCheck.class)))\n", "", "HealthCheckIT.unreadableRowsAreSkipped"),
    ("health_check.read_tolerant", HC,
     "        } catch (RuntimeException e) {\n            return null;", "        } catch (RuntimeException e) {\n            throw e;",
     "HealthCheckIT.unreadableRowsAreSkipped"),
    ("health_check.rule.path", "core/feature/addons/health_check/logic/model/HealthCheck.java",
     '@Pattern(regexp = "/\\\\S*", message = "{health_check.path.invalid}") ', "", "HealthCheckIT.invalidHealthCheck"),
    ("health_check.rule.path_size", "core/feature/addons/health_check/logic/model/HealthCheck.java",
     "@Size(max = 2000) ", "", "HealthCheckIT.invalidHealthCheck"),
    ("health_check.rule.interval_min", "core/feature/addons/health_check/logic/model/HealthCheck.java",
     "@Min(10) ", "", "HealthCheckIT.invalidHealthCheck"),
    ("health_check.rule.interval_max", "core/feature/addons/health_check/logic/model/HealthCheck.java",
     "@Max(3600) ", "", "HealthCheckIT.invalidHealthCheck"),
    ("health_check.validate", "core/feature/addons/health_check/rest/HealthCheckController.java",
     "@Valid @RequestBody HealthCheck", "@RequestBody HealthCheck", "HealthCheckIT.invalidHealthCheck"),
    ("health_check.restore.validate", "core/feature/addons/base/logic/model/AddonsRequest.java",
     "    @Valid\n    private HealthCheck healthCheck;", "    private HealthCheck healthCheck;", "HealthCheckIT.invalidHealthCheck"),
    ("health_check.in_routes", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     "healthCheckUseCase.ofRoute(routeId), rateLimitUseCase", "null, rateLimitUseCase", "HealthCheckIT.routeHealthCheck"),
    ("health_check.restore", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     "addons.sent(HealthCheck.TYPE) ?", "true ?", "HealthCheckIT.gatewayAndRestore"),
    ("health_check.restore_reload", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     "maintenanceUseCase.reload().then(healthCheckUseCase.reload())", "maintenanceUseCase.reload()", "HealthCheckIT.gatewayAndRestore"),
    # --- add-ons: rate limit
    ("rate_limit.enabled", "core/feature/addons/rate_limit/logic/model/RateLimit.java",
     "return Boolean.TRUE.equals(enabled);", "return enabled != null;", "RateLimitIT.routeRateLimit"),
    ("rate_limit.burst_is_capacity", "core/feature/addons/rate_limit/logic/model/RateLimit.java",
     "return burst != null ? burst : limit;", "return limit;", "TokenBucketTest.burstIsTheSizeOfTheBucket"),
    ("rate_limit.period.second", "core/feature/addons/rate_limit/logic/model/RateLimit.java",
     'case "second" -> Duration.ofSeconds(1);', 'case "second" -> Duration.ofMinutes(1);', "TokenBucketTest.burstIsTheSizeOfTheBucket"),
    ("rate_limit.period.minute", "core/feature/addons/rate_limit/logic/model/RateLimit.java",
     'case "minute" -> Duration.ofMinutes(1);', 'case "minute" -> Duration.ofHours(1);', "TokenBucketTest.startsFullWithTheLimit"),
    ("rate_limit.bucket.takes_one", "core/feature/addons/rate_limit/logic/usecase/TokenBucket.java",
     "tokens -= 1;", "", "TokenBucketTest.startsFullWithTheLimit"),
    ("rate_limit.bucket.refills", "core/feature/addons/rate_limit/logic/usecase/TokenBucket.java",
     "tokens + Math.max(0, now - last) * perNano", "tokens", "TokenBucketTest.fillsBackWithTimeUpToItsSize"),
    ("rate_limit.bucket.up_to_capacity", "core/feature/addons/rate_limit/logic/usecase/TokenBucket.java",
     "tokens = Math.min(capacity, tokens + Math.max(0, now - last) * perNano);",
     "tokens = tokens + Math.max(0, now - last) * perNano;", "TokenBucketTest.fillsBackWithTimeUpToItsSize"),
    ("rate_limit.bucket.wait", "core/feature/addons/rate_limit/logic/usecase/TokenBucket.java",
     "return (long) Math.ceil((1 - tokens) / perNano);", "return 1;", "TokenBucketTest.startsFullWithTheLimit"),
    ("rate_limit.retry_after_rounded_up", RL,
     "Math.max(1, (wait + 999_999_999) / 1_000_000_000)", "Math.max(1, wait / 1_000_000_000)", "RateLimitIT.burstAndRefill"),
    ("rate_limit.gateway", RL,
     "        long wait = take(current, current.gateway(), GATEWAY, clientIp, now);\n", "        long wait = 0;\n",
     "RateLimitIT.gatewayRateLimit"),
    ("rate_limit.route", RL,
     "            wait = take(current, current.routes().get(routeId), routeId, clientIp, now);\n", "",
     "RateLimitIT.routeRateLimit"),
    ("rate_limit.route_stop_gives_back", RL,
     "            if (wait > 0) giveBack(current, clientIp);\n", "", "RateLimitIT.gatewayRateLimit"),
    ("rate_limit.bounded", RL,
     "            map.clear();\n", "", "TokenBucketTest.bucketsAreBounded"),
    ("rate_limit.per_ip", RL,
     'scope + " " + clientIp', "scope", "RateLimitIT.routeRateLimit"),
    ("rate_limit.gateway_all_routes", RL,
     "take(current, current.gateway(), GATEWAY, clientIp, now)", "take(current, current.gateway(), routeId, clientIp, now)",
     "RateLimitIT.gatewayRateLimit"),
    ("rate_limit.only_on", RL,
     "if (config == null || !config.on()) return 0;", "if (config == null) return 0;", "RateLimitIT.routeRateLimit"),
    ("rate_limit.change_counts_from_zero", RL,
     "state = new State(gateway, Map.copyOf(routes), new ConcurrentHashMap<>());",
     "state = new State(gateway, Map.copyOf(routes), state.buckets());", "RateLimitIT.burstAndRefill"),
    ("rate_limit.filter", "core/feature/addons/rate_limit/filter/RateLimitFilter.java",
     "        if (seconds == 0) {\n            return chain.filter(exchange);\n        }\n", "        if (true) {\n            return chain.filter(exchange);\n        }\n",
     "RateLimitIT.routeRateLimit"),
    ("rate_limit.retry_after", "core/feature/addons/rate_limit/filter/RateLimitFilter.java",
     "        exchange.getResponse().getHeaders().set(HttpHeaders.RETRY_AFTER, String.valueOf(seconds));\n", "",
     "RateLimitIT.routeRateLimit"),
    ("rate_limit.gateway_right_away", RL,
     "                .flatMap(addon -> write(addon, rateLimit))\n                .then(reload())",
     "                .flatMap(addon -> write(addon, rateLimit))", "RateLimitIT.gatewayRateLimit"),
    ("rate_limit.route_right_away", RL,
     "                .flatMap(route -> save(route.getRouteId(), rateLimit))\n                .then(reload())",
     "                .flatMap(route -> save(route.getRouteId(), rateLimit))", "RateLimitIT.routeRateLimit"),
    ("rate_limit.enable_keeps_the_rest", RL,
     "new RateLimit(enabled, current.limit(), current.period(), current.burst())", 'new RateLimit(enabled, 1000, "hour", null)',
     "RateLimitIT.routeRateLimit"),
    ("rate_limit.enable_route_not_configured", RL,
     '                .switchIfEmpty(Mono.error(Errors.notFound("rate_limit.route.not_found", routeId)))\n', "",
     "RateLimitIT.routeRateLimit"),
    ("rate_limit.enable_gateway_not_configured", RL,
     '                .switchIfEmpty(Mono.error(Errors.notFound("rate_limit.gateway.not_found")))\n', "",
     "RateLimitIT.gatewayRateLimit"),
    ("rate_limit.delete", RL,
     ".flatMap(route -> save(route.getRouteId(), null))", ".flatMap(route -> Mono.<Void>empty())", "RateLimitIT.routeRateLimit"),
    ("rate_limit.skip_unreadable", RL,
     "                        if (!valid(config)) {", "                        if (config == null) {", "RateLimitIT.unreadableRowsAreSkipped"),
    ("rate_limit.read_tolerant", RL,
     "        } catch (RuntimeException e) {\n            return null;", "        } catch (RuntimeException e) {\n            throw e;",
     "RateLimitIT.unreadableRowsAreSkipped"),
    ("rate_limit.rule.limit_min", "core/feature/addons/rate_limit/logic/model/RateLimit.java",
     "@NotNull @Min(1) @Max(1_000_000) Integer limit", "@NotNull @Max(1_000_000) Integer limit", "RateLimitIT.invalidRateLimit"),
    ("rate_limit.rule.limit_max", "core/feature/addons/rate_limit/logic/model/RateLimit.java",
     "@NotNull @Min(1) @Max(1_000_000) Integer limit", "@NotNull @Min(1) Integer limit", "RateLimitIT.invalidRateLimit"),
    ("rate_limit.rule.period", "core/feature/addons/rate_limit/logic/model/RateLimit.java",
     '@Pattern(regexp = "second|minute|hour", message = "{rate_limit.period.invalid}") ', "", "RateLimitIT.invalidRateLimit"),
    ("rate_limit.rule.burst", "core/feature/addons/rate_limit/logic/model/RateLimit.java",
     "@Min(1) @Max(1_000_000) Integer burst", "Integer burst", "RateLimitIT.invalidRateLimit"),
    ("rate_limit.gateway.validate", "core/feature/addons/rate_limit/rest/RateLimitController.java",
     "setGateway(@Valid @RequestBody", "setGateway(@RequestBody", "RateLimitIT.invalidRateLimit"),
    ("rate_limit.route.validate", "core/feature/addons/rate_limit/rest/RateLimitController.java",
     'String routeId, @Valid @RequestBody RateLimit', 'String routeId, @RequestBody RateLimit', "RateLimitIT.invalidRateLimit"),
    ("rate_limit.restore.validate", "core/feature/addons/base/logic/model/AddonsRequest.java",
     "    @Valid\n    private RateLimit rateLimit;", "    private RateLimit rateLimit;", "RateLimitIT.invalidRateLimit"),
    ("rate_limit.in_routes", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     "rateLimitUseCase.ofRoute(routeId)", "null", "RateLimitIT.routeRateLimit"),
    ("rate_limit.in_gateway", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     "rateLimitUseCase.ofGateway()", "null", "RateLimitIT.gatewayRateLimit"),
    ("rate_limit.restore", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     "addons.sent(RateLimit.TYPE) ?", "true ?", "RateLimitIT.restore"),
    ("rate_limit.restore_reload", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     ".then(rateLimitUseCase.reload())", "", "RateLimitIT.restore"),
    ("rate_limit.delete_gateway", RL,
     "findByRouteIdIsNullAndType(RateLimit.TYPE)\n                .flatMap(addonRepo::delete)\n                .then(reload());",
     "findByRouteIdIsNullAndType(RateLimit.TYPE)\n                .then(reload());", "RateLimitIT.gatewayRateLimit"),
    ("rate_limit.delete_gateway_right_away", RL,
     "findByRouteIdIsNullAndType(RateLimit.TYPE)\n                .flatMap(addonRepo::delete)\n                .then(reload());",
     "findByRouteIdIsNullAndType(RateLimit.TYPE)\n                .flatMap(addonRepo::delete);", "RateLimitIT.gatewayRateLimit"),
    # --- add-ons: every type together
    ("addons.in_routes", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     "addonsUseCase.ofRoute(entity.getRouteId().toString(), locale)", "null", "MaintenanceIT.routeMaintenance"),
    ("addons.restore", "core/feature/routes/logic/usecase/RouteUseCase_Impl.java",
     ".flatMap(saved -> restoreAddons(saved, requests).thenReturn(saved))", "", "MaintenanceIT.restore"),
    ("addons.restore.keeps_not_sent", "core/feature/addons/base/logic/usecase/AddonsUseCase_Impl.java",
     "addons.sent(Maintenance.TYPE) ?", "true ?",
     "MaintenanceIT.restore"),
    ("addons.restore.null_deletes", "core/feature/addons/base/logic/model/AddonsRequest.java",
     "        sent.add(Maintenance.TYPE);\n", "", "MaintenanceIT.restore"),
    ("addons.restore.validate", "core/feature/routes/logic/model/RouteRequest.java",
     "    @Valid\n    private AddonsRequest addons;", "    private AddonsRequest addons;", "MaintenanceIT.invalidMaintenance"),
    ("addons.restore.validate_each", "core/feature/addons/base/logic/model/AddonsRequest.java",
     "    @Valid\n    private Maintenance maintenance;", "    private Maintenance maintenance;", "MaintenanceIT.invalidMaintenance"),

    # --- proxy and errors
    ("proxy.upstream_cors_dropped", "config/CorsConfig.java",
     "if (!name.regionMatches(true, 0, \"Access-Control-\", 0, \"Access-Control-\".length())) {", "if (true) {",
     "GatewayProxyIT.proxiedResponsesGetTheGatewayCors"),
    ("cors.gateway_no_credentials", "core/feature/addons/cors/logic/usecase/CorsUseCase_Impl.java",
     "if (cors.credentials()) return Mono.error(", "if (false) return Mono.error(", "CorsIT.invalidCors"),
    ("cors.credentials_any_origin", "core/feature/addons/cors/logic/usecase/CorsUseCase_Impl.java",
     "if (cors.credentials() && cors.allowsAnyOrigin()) {", "if (false) {", "CorsIT.invalidCors"),
    ("cors.credentials_wildcard_host", "core/feature/addons/cors/logic/model/Cors.java",
     "&& !host.matches(", "&& host.matches(", "CorsUseCase_ImplTest.anyOrigin"),
]


def git_diff_hash():
    out = subprocess.run(["git", "diff", "--", "src/main"], cwd=GATEWAY, capture_output=True, check=True).stdout
    return hashlib.sha256(out).hexdigest()


def run_test(test):
    task = "integrationTest" if test.split(".")[0].endswith("IT") else "test"
    proc = subprocess.run([GRADLEW, task, "--tests", "*." + test, "--console=plain"],
                          cwd=GATEWAY, capture_output=True, text=True, encoding="utf-8", errors="replace")
    out = proc.stdout + proc.stderr
    if "compileJava FAILED" in out or "Compilation failed" in out:
        return "COMPILE ERROR"
    if "No tests found" in out:
        return "NO TESTS"
    return "SURVIVED" if proc.returncode == 0 else "KILLED"


def main(args):
    if "--list" in args:
        for m in MUTATIONS:
            print(f"{m[0]:40} {m[4]}")
        return 0
    selected = [m for m in MUTATIONS if not args or any(m[0].startswith(a) for a in args)]
    before = git_diff_hash()
    results = []
    for i, (mid, rel, old, new, test) in enumerate(selected, 1):
        path = SRC / rel
        original = path.read_bytes()
        text = original.decode("utf-8")
        if "\r\n" in text:
            old, new = old.replace("\n", "\r\n"), new.replace("\n", "\r\n")
        start = time.time()
        if text.count(old) != 1:
            verdict = "BAD PATTERN"
        else:
            try:
                path.write_bytes(text.replace(old, new).encode("utf-8"))
                verdict = run_test(test)
            finally:
                path.write_bytes(original)
        results.append((mid, verdict, test))
        print(f"[{i}/{len(selected)}] {verdict:13} {mid}  ({test}, {time.time() - start:.0f}s)", flush=True)

    if git_diff_hash() != before:
        print("!! src/main differs from before the run: check `git diff -- src/main`")
        return 2
    bad = [r for r in results if r[1] != "KILLED"]
    print(f"\n{len(results) - len(bad)}/{len(results)} killed")
    for mid, verdict, test in bad:
        print(f"  {verdict:13} {mid}  ({test})")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
