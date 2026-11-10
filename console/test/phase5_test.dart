import 'package:console/app_exporter.dart';
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
    String? responseCode,
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
    test('goToPage asks for that page and replaces the rows', () async {
      final repo = FakeLogsRepo(25);
      final cubit = cubitWith(repo);

      await cubit.applySearch(query: '');
      await cubit.goToPage(2);

      expect(repo.requestedPages, [0, 2]);
      expect(cubit.totalPages, 3);
      expect(cubit.items.map((l) => l.id), ['20', '21', '22', '23', '24']);
    });

    test('searching, filtering or resizing goes back to page 1', () async {
      final repo = FakeLogsRepo(100);
      final cubit = cubitWith(repo);

      await cubit.goToPage(3);
      await cubit.applySearch(query: 'x');
      expect(repo.requestedPages.last, 0);

      await cubit.goToPage(3);
      await cubit.applyFilter(responseCode: '4');
      expect(repo.requestedPages.last, 0);

      await cubit.goToPage(3);
      await cubit.setPageSize(25);
      expect(repo.requestedPages.last, 0);
      expect(cubit.items, hasLength(25));
    });

    test('a failed page keeps the last rows and page to retry', () async {
      final repo = FakeLogsRepo(30);
      final cubit = cubitWith(repo);
      await cubit.applySearch(query: '');

      repo.failNext = true;
      await cubit.goToPage(1);

      expect(cubit.state, isA<LogsSearchErrorState>());
      expect(cubit.loaded, isTrue);
      expect(cubit.items.first.id, '0');
      await cubit.search();
      expect(repo.requestedPages.last, 1);
    });

    test('reset clears items, page and filters', () async {
      final repo = FakeLogsRepo(30);
      final cubit = cubitWith(repo);
      await cubit.applyFilter(responseCode: '500', httpMethod: 'GET');
      await cubit.goToPage(1);

      cubit.reset();
      expect(cubit.items, isEmpty);
      expect(cubit.currentPage, LogsCubit.defaultPage);
      expect(cubit.loaded, isFalse);
      expect(cubit.filters.filterCount, 0);
      expect(cubit.state, isA<LogsInitialState>());
    });

    test('export filters are JSON encodable with a date range', () {
      final filters = LogsSearchFilters(
        date: (fromDate: DateTime.utc(2026, 1, 1), toDate: null),
      );
      expect(filters.toJson()['date'], {
        'fromDate': '2026-01-01T00:00:00.000Z',
        'toDate': null,
      });
    });
  });

  group('LogsCubit date filters', () {
    test('a range covers its whole local days', () async {
      final repo = FakeLogsRepo(1);
      final cubit = cubitWith(repo);

      await cubit.applyFilter(
        fromDate: DateTime(2026, 3, 10, 9),
        toDate: DateTime(2026, 3, 10, 9),
      );

      final dates = repo.requestedDates.last;
      expect(dates.from, DateTime(2026, 3, 10));
      expect(dates.to, DateTime(2026, 3, 10, 23, 59, 59, 999, 999));
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
