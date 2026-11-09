import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRoutesRepo implements RoutesRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

///serves [totalElements] logs in pages; records every requested page
class FakeLogsRepo implements LogsRepo {
  final int totalElements;
  final List<int> requestedPages = [];
  final List<({DateTime? from, DateTime? to})> requestedDates = [];
  bool failNext = false;

  FakeLogsRepo(this.totalElements);

  @override
  Future<HttpLogSearchModel> findAll({
    required int page,
    int? size,
    int? responseCode,
    String? method,
    String? query,
    String? routeId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (failNext) {
      failNext = false;
      throw GlobalException(type: GlobalExceptionType.general, message: 'boom');
    }
    requestedPages.add(page);
    requestedDates.add((from: fromDate, to: toDate));
    final pageSize = size ?? totalElements;
    final start = page * pageSize;
    final count = (totalElements - start).clamp(0, pageSize);
    return HttpLogSearchModel(
      page: page,
      size: pageSize,
      totalPages: pageSize == 0 ? 0 : (totalElements / pageSize).ceil(),
      totalElements: totalElements,
      pageContent: List.generate(count, (i) => log('${start + i}')),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HttpLogModel log(String id) => HttpLogModel(
  id: id,
  sourceIp: '1.1.1.1',
  requestedAt: DateTime.utc(2026, 1, 1),
  userAgent: 'ua',
  httpMethod: 'GET',
  path: '/x',
  responseCode: 200,
  requestDuration: 1,
);

LogsCubit cubitWith(FakeLogsRepo repo) =>
    LogsCubit(repo: repo, routesRepo: FakeRoutesRepo());

void main() {
  group('LogsCubit pagination', () {
    test('hasMorePages follows total_pages, not a short page', () async {
      final repo = FakeLogsRepo(
        LogsCubit.defaultPageSize * 2,
      ); //exactly 2 full pages
      final cubit = cubitWith(repo);

      await cubit.applySearch(query: '');
      expect(cubit.hasMorePages, isTrue);

      await cubit.fetchNextPage();
      expect(
        cubit.hasMorePages,
        isFalse,
      ); //old "length < pageSize" check would ask for an empty 3rd page
      expect(repo.requestedPages, [0, 1]);
      expect(cubit.items.length, LogsCubit.defaultPageSize * 2);
    });

    test(
      'a failed page is not skipped: retry asks for the same page',
      () async {
        final repo = FakeLogsRepo(LogsCubit.defaultPageSize * 3);
        final cubit = cubitWith(repo);
        await cubit.applySearch(query: '');

        repo.failNext = true;
        await expectLater(
          cubit.fetchNextPage(),
          throwsA(isA<GlobalException>()),
        );
        await cubit.fetchNextPage();
        expect(repo.requestedPages, [0, 1]);
      },
    );

    test(
      'a new search restarts from page 0 without duplicating items',
      () async {
        final repo = FakeLogsRepo(LogsCubit.defaultPageSize * 3);
        final cubit = cubitWith(repo);
        await cubit.applySearch(query: '');
        await cubit.fetchNextPage();

        await cubit.applySearch(query: 'x');
        expect(repo.requestedPages.last, 0);
        expect(cubit.items.length, LogsCubit.defaultPageSize);
      },
    );

    test('reset clears items, page and filters', () async {
      final repo = FakeLogsRepo(LogsCubit.defaultPageSize * 3);
      final cubit = cubitWith(repo);
      await cubit.applyFilter(responseCode: 500, httpMethod: 'GET');
      await cubit.fetchNextPage();

      cubit.reset();
      expect(cubit.items, isEmpty);
      expect(cubit.currentPage, LogsCubit.defaultPage);
      expect(cubit.hasMorePages, isTrue);
      expect(cubit.filters.filterCount, 0);
      expect(cubit.state, isA<LogsInitialState>());
    });
  });

  group('LogsCubit date filters', () {
    test('clicking a timestamp filters the whole local day', () async {
      final repo = FakeLogsRepo(1);
      final cubit = cubitWith(repo);
      //what the screen passes now: requestedAtLocal
      final local = DateTime.utc(2026, 3, 10, 23, 30).toLocal();

      await cubit.updateFilter(requestedAt: local);

      final dates = repo.requestedDates.last;
      expect(dates.from, DateTime(local.year, local.month, local.day));
      expect(
        dates.to,
        DateTime(local.year, local.month, local.day, 23, 59, 59, 999, 999),
      );
      expect(dates.from!.isUtc, isFalse);
    });

    test('from/to are swapped when reversed', () async {
      final repo = FakeLogsRepo(1);
      final cubit = cubitWith(repo);
      await cubit.applyFilter(
        fromDate: DateTime(2026, 5, 20),
        toDate: DateTime(2026, 5, 1),
      );
      final dates = repo.requestedDates.last;
      expect(dates.from, DateTime(2026, 5, 1));
      expect(dates.to!.day, 20);
    });

    test('request sends local day bounds as UTC instants', () {
      final from = DateTime(2026, 5, 1);
      final json = HttpLogSearchRequest(page: 0, fromDate: from).toJson();
      expect(json['from_date'], from.toUtc().toIso8601String());
    });
  });

  group('HttpLogResponse parsing', () {
    test('all fields null does not crash', () {
      final r = HttpLogResponse.fromJson({
        'id': null,
        'source_ip': null,
        'requested_at': null,
        'user_agent': null,
        'http_method': null,
        'path': null,
        'response_code': null,
        'request_duration': null,
        'route': null,
      });
      expect(r.id, '');
      expect(r.responseCode, 0);
      expect(r.route, isNull);
    });

    test('route with null fields does not crash', () {
      final r = HttpLogResponse.fromJson({
        'id': '1',
        'response_code': 200,
        'route': {'route_id': null, 'route_name': null, 'route_path': null},
      });
      expect(r.route?.routeName, '');
    });

    test('search response without page_content', () {
      final r = HttpLogSearchResponse.fromJson({'page': 0});
      expect(r.pageContent, isEmpty);
      expect(r.totalPages, 0);
    });
  });
}
