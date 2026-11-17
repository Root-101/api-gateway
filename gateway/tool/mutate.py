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
MUTATIONS = [
    # --- route rules
    ("routes.rule.leading_slash", "features/routes/utils/RouteRules.java",
     '&& !route.getPath().startsWith("/")) {', "&& false) {", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.path_pattern", "features/routes/utils/RouteRules.java",
     "PathPatternParser.defaultInstance.parse(route.getPath());", "route.getPath();", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.uri_without_path", "features/routes/utils/RouteRules.java",
     'if (uriPath != null && !uriPath.isEmpty() && !uriPath.equals("/")) {', "if (false) {", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.uri_trailing_slash_ok", "features/routes/utils/RouteRules.java",
     ' && !uriPath.equals("/")', "", "ValidationIT.edgeValuesAreValid"),
    ("routes.rule.replace_from_regex", "features/routes/utils/RouteRules.java",
     "Pattern.compile(route.getRewritePath().getReplaceFrom());", "route.getRewritePath().getReplaceFrom();", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.list_index", "config/GlobalExceptionHandler.java",
     '"[%d].".formatted(errors.getContainerIndex())', '""', "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.on_the_route", "features/routes/logic/model/RouteConfigRequest.java",
     "@ValidRoute\npublic class RouteConfigRequest {", "public class RouteConfigRequest {", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.rule.rewrite_path_cascade", "features/routes/logic/model/RouteConfigRequest.java",
     "    @Valid\n    private RewritePathModel rewritePath;", "    private RewritePathModel rewritePath;", "ValidationIT.invalidRouteFieldIs422"),

    # --- every write endpoint validates the body (bean validation and route rules: `@Valid`)
    ("routes.post.validate", "features/routes/rest/RoutesController.java",
     "addRoute(@Valid @RequestBody", "addRoute(@RequestBody", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.batch.validate", "features/routes/rest/RoutesController.java",
     "addAllRoutes(@RequestBody List<@Valid RouteConfigRequest>", "addAllRoutes(@RequestBody List<RouteConfigRequest>", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.replace.validate", "features/routes/rest/RoutesController.java",
     "replaceAllRoutes(@RequestBody List<@Valid RouteConfigRequest>", "replaceAllRoutes(@RequestBody List<RouteConfigRequest>", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.edit.validate", "features/routes/rest/RoutesController.java",
     "String routeId, @Valid @RequestBody RouteConfigRequest", "String routeId, @RequestBody RouteConfigRequest", "ValidationIT.invalidRouteFieldIs422"),
    ("routes.validate.validate", "features/routes/rest/RoutesController.java",
     "validateRoute(@Valid @RequestBody", "validateRoute(@RequestBody", "ValidationIT.invalidRouteFieldIs422"),
    ("auth.login.validate", "features/auth/rest/AuthController.java",
     "login(@Valid @RequestBody", "login(@RequestBody", "ValidationIT.invalidLoginFieldIs422"),

    # --- routes use case
    ("routes.duplicated_in_list", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "entry.getValue().size() > 1", "entry.getValue().size() > 2", "RoutesIT.duplicatedNamesAre409"),
    ("routes.duplicated_in_db", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "request -> routeRepo.findByName(request.getName())", 'request -> routeRepo.findByName("-never-a-name-")', "RoutesIT.duplicatedNamesAre409"),
    ("routes.batch.transaction", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "entities -> routeRepo.saveAll(entities).collectList().as(tx::transactional)", "entities -> routeRepo.saveAll(entities).collectList()",
     "RoutesIT.batchFailingHalfwayRollsBack"),
    ("routes.replace.transaction", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "\n                                            .as(tx::transactional)", "",
     "RoutesIT.replaceFailingHalfwayRollsBack"),
    ("routes.replace.keeps_id", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "entity.setRouteId(old.getRouteId());", "", "RoutesIT.replaceSwapsAllTheRoutes"),
    ("routes.replace.keeps_created_at", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "entity.setCreatedAt(old.getCreatedAt());", "", "RoutesIT.replaceSwapsAllTheRoutes"),
    ("routes.replace.unloads_removed", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "return Flux.fromIterable(removed)", "return Flux.<RouteEntity>empty()", "RoutesIT.replaceSwapsAllTheRoutes"),
    ("routes.edit.own_name_ok", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     ".filter(existing -> !existing.getRouteId().equals(oldRoute.getRouteId()))", ".filter(existing -> true)",
     "RoutesIT.editRouteWithDuplicatedName"),
    ("routes.edit.name_taken", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     ".filter(existing -> !existing.getRouteId().equals(oldRoute.getRouteId()))", ".filter(existing -> false)",
     "RoutesIT.editRouteWithDuplicatedName"),
    ("routes.edit.keeps_created_at", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "entityToEdit.setCreatedAt(oldRoute.getCreatedAt());", "", "RoutesIT.editChangesTheRouting"),
    ("routes.edit.refreshes_gateway", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     ".flatMap(saved -> apply(List.of(saved), List.of()))", ".map(saved -> List.of(buildResponse(saved)))", "RoutesIT.editChangesTheRouting"),
    ("routes.delete.normalized_id", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "String id = route.getRouteId().toString();", "String id = routeId;", "RoutesIT.deleteRouteWithUppercaseId"),
    ("routes.not_found", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "HttpStatus.NOT_FOUND, \"route.not_found\"", "HttpStatus.BAD_REQUEST, \"route.not_found\"", "RoutesIT.unknownIdIs404"),
    # the bug it pins: routes loaded async, after the server already takes traffic
    ("routes.loaded_before_traffic", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     ".count()\n                .block(Duration.ofSeconds(60));",
     ".count()\n                .delaySubscription(Duration.ofSeconds(5)).subscribe() == null ? 0L : 0L;",
     "RoutesIT.routesLoadedBeforeTraffic"),
    ("routes.rewrite_filter", "features/routes/utils/RouteDefinitionMapper.java",
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
    ("logs.skip_admin_get", "features/http_logs/filter/HttpLogsWebFilter.java",
     "&& httpMethod == HttpMethod.GET)", "&& httpMethod == HttpMethod.DELETE)", "HttpLogsIT.whatIsAndIsNotLogged"),
    ("logs.skip_validate", "features/http_logs/filter/HttpLogsWebFilter.java",
     '|| requestedPath.equals("/%s/routes/validate".formatted(adminBasePath))', "", "HttpLogsIT.whatIsAndIsNotLogged"),
    ("logs.skip_preflight", "features/http_logs/filter/HttpLogsWebFilter.java",
     "|| CorsUtils.isPreFlightRequest(exchange.getRequest())", "", "HttpLogsIT.whatIsAndIsNotLogged"),
    ("logs.skip_health", "features/http_logs/filter/HttpLogsWebFilter.java",
     '|| requestedPath.equals("/%s/health".formatted(adminBasePath))', "", "HttpLogsIT.whatIsAndIsNotLogged"),
    # --- client ip and TRUSTED_PROXIES
    ("ip.first_forwarded_ip", "features/http_logs/filter/HttpLogsWebFilter.java",
     "if (!trustedProxies.isTrusted(tempClientIp)) break;", "break;",
     "HttpLogsIT.logRouteWithoutRewriteAndLongForwardedFor"),
    ("ip.only_from_trusted_proxy", "features/http_logs/filter/HttpLogsWebFilter.java",
     "if (forwardedFor != null && isTrustedProxy(tempClientIp, trustedProxies)) {", "if (forwardedFor != null) {",
     "UntrustedProxyIT.spoofedForwardedForIsIgnored"),
    ("ip.rightmost_untrusted", "features/http_logs/filter/HttpLogsWebFilter.java",
     "if (!trustedProxies.isTrusted(tempClientIp)) break;", "",
     "HttpLogsWebFilterTest.clientIpTrustingSomeProxies"),
    ("ip.server_from_trusted_proxy", "features/http_logs/filter/HttpLogsWebFilter.java",
     "boolean fromProxy = isTrustedProxy(connectionIp(exchange), trustedProxies);", "boolean fromProxy = true;",
     "HttpLogsWebFilterTest.serverIp"),
    ("ip.empty_trusts_none", "config/ServiceConfig.java",
     "return regex.isBlank() ? ip -> false : TrustedProxies.from(regex);", "return TrustedProxies.from(regex.isBlank() ? \".*\" : regex);",
     "ServiceConfigTest.trustedProxies"),
    ("logs.admin_route", "features/http_logs/logic/usecase/HttpLogUseCaseImpl.java",
     "} else if (isAdminPath(request.getRequestedPath())) {", "} else if (false) {", "HttpLogsIT.whatIsAndIsNotLogged"),
    ("logs.final_route_rewrite", "features/http_logs/logic/usecase/HttpLogUseCaseImpl.java",
     "if (route.getRewritePathFrom() != null && route.getRewritePathTo() != null) {", "if (false) {", "HttpLogsIT.logRouteWithRewrite"),

    # --- log search
    ("logs.search.size_cap", "features/http_logs/logic/usecase/HttpLogUseCaseImpl.java",
     "Math.min(request.getSize() != null ? request.getSize() : DEFAULT_PAGE_SIZE, maxSearchSize)",
     "(request.getSize() != null ? request.getSize() : DEFAULT_PAGE_SIZE)", "HttpLogsIT.searchLogs"),
    ("logs.search.page_min", "features/http_logs/rest/HttpLogController.java",
     "if (page < 0) {", "if (page < -1) {", "HttpLogsIT.searchWithInvalidParamIs400"),
    ("logs.search.size_min", "features/http_logs/rest/HttpLogController.java",
     "size != null && size < 1", "size != null && size < 0", "HttpLogsIT.searchWithInvalidParamIs400"),
    ("logs.search.status_prefix", "features/http_logs/data/repo/HttpLogSearchRepo.java",
     "(int) Math.pow(10, 3 - code.length())", "10", "HttpLogsIT.searchLogs"),
    ("logs.search.query_path", "features/http_logs/data/repo/HttpLogSearchRepo.java",
     '.or(Criteria.where("path").like(likeQuery).ignoreCase(true))', "", "HttpLogsIT.searchLogs"),
    ("logs.search.method_ignore_case", "features/http_logs/data/repo/HttpLogSearchRepo.java",
     'Criteria.where("httpMethod").like(contains(request.getMethod())).ignoreCase(true)',
     'Criteria.where("httpMethod").like(contains(request.getMethod())).ignoreCase(false)', "HttpLogsIT.searchIsCaseInsensitive"),
    ("logs.search.no_route", "features/http_logs/data/repo/HttpLogSearchRepo.java",
     'criteria = criteria.and("routeId").isNull();', 'criteria = criteria.and("routeId").isNotNull();', "HttpLogsIT.searchLogs"),
    ("logs.search.from", "features/http_logs/data/repo/HttpLogSearchRepo.java",
     'criteria.and("requestedAt").greaterThanOrEquals(request.getFrom())', 'criteria.and("requestedAt").lessThanOrEquals(request.getFrom())',
     "HttpLogsIT.searchLogs"),
    ("logs.search.to", "features/http_logs/data/repo/HttpLogSearchRepo.java",
     'criteria.and("requestedAt").lessThanOrEquals(request.getTo())', 'criteria.and("requestedAt").greaterThanOrEquals(request.getTo())',
     "HttpLogsIT.searchLogs"),
    ("logs.search.escape_underscore", "features/http_logs/data/repo/HttpLogSearchRepo.java",
     '.replace("_", "\\\\_")', "", "HttpLogsIT.searchLogs"),
    ("logs.search.newest_first", "features/http_logs/data/repo/HttpLogSearchRepo.java",
     'Sort.Direction.DESC, "requestedAt"', 'Sort.Direction.ASC, "requestedAt"', "HttpLogsIT.searchLogs"),
    ("logs.cleanup.days", "features/http_logs/task/CleanUpOldLogs.java",
     "OffsetDateTime.now().minusDays(maintainLogsFor)", "OffsetDateTime.now().minusDays(maintainLogsFor + 1)", "HttpLogsIT.cleanUpOldLogs"),

    # --- maintenance
    ("maintenance.enabled", "features/maintenance/logic/model/Maintenance.java",
     "return Boolean.TRUE.equals(enabled);", "return enabled != null;", "MaintenanceIT.routeInMaintenance"),
    ("maintenance.route", "features/maintenance/logic/usecase/MaintenanceUseCaseImpl.java",
     "if (route != null && route.on()) return route;", "", "MaintenanceIT.routeInMaintenance"),
    ("maintenance.route_wins", "features/maintenance/logic/usecase/MaintenanceUseCaseImpl.java",
     "if (route != null && route.on()) return route;",
     "if (current.global() != null && current.global().on()) return current.global();\n        if (route != null && route.on()) return route;",
     "MaintenanceIT.globalMaintenance"),
    ("maintenance.global", "features/maintenance/logic/usecase/MaintenanceUseCaseImpl.java",
     "return current.global() != null && current.global().on() ? current.global() : null;", "return null;", "MaintenanceIT.globalMaintenance"),
    ("maintenance.global_right_away", "features/maintenance/logic/usecase/MaintenanceUseCaseImpl.java",
     "                .then(reload())\n                .thenReturn(maintenance);", "                .thenReturn(maintenance);", "MaintenanceIT.globalMaintenance"),
    ("maintenance.route_right_away", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     "                .then(maintenanceUseCase.reload())\n                .thenReturn(maintenance);", "                .thenReturn(maintenance);",
     "MaintenanceIT.routeInMaintenance"),
    ("maintenance.default_message", "features/maintenance/filter/MaintenanceFilter.java",
     "maintenance.message() != null && !maintenance.message().isBlank()", "maintenance.message() != null", "MaintenanceIT.defaultMessageAndRetryAfter"),
    ("maintenance.retry_after_ahead", "features/maintenance/filter/MaintenanceFilter.java",
     "if (millis > 0) {", "if (true) {", "MaintenanceIT.defaultMessageAndRetryAfter"),
    ("maintenance.restore", "features/routes/logic/usecase/RouteUseCaseImpl.java",
     ".flatMap(saved -> saveMaintenance(saved, requests).thenReturn(saved))", "", "MaintenanceIT.routeWritesAndRestore"),
    ("maintenance.global.validate", "features/maintenance/rest/MaintenanceController.java",
     "setMaintenance(@Valid @RequestBody", "setMaintenance(@RequestBody", "MaintenanceIT.invalidMaintenance"),
    ("maintenance.route.validate", "features/routes/rest/RoutesController.java",
     "setMaintenance(@PathVariable(\"route-id\") String routeId, @Valid @RequestBody", "setMaintenance(@PathVariable(\"route-id\") String routeId, @RequestBody",
     "MaintenanceIT.invalidMaintenance"),
    ("maintenance.restore.validate", "features/routes/logic/model/RouteConfigRequest.java",
     "    @Valid\n    private Maintenance maintenance;", "    private Maintenance maintenance;", "MaintenanceIT.invalidMaintenance"),

    # --- proxy and errors
    ("proxy.upstream_cors_dropped", "config/CorsConfig.java",
     "if (!name.regionMatches(true, 0, \"Access-Control-\", 0, \"Access-Control-\".length())) {", "if (true) {",
     "GatewayProxyIT.proxiedResponsesGetTheGatewayCors"),
    ("proxy.no_credentials", "config/CorsConfig.java",
     "corsConfiguration.setAllowCredentials(false);", "corsConfiguration.setAllowCredentials(true);", "SecurityIT.preflightWithoutAuth"),
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
