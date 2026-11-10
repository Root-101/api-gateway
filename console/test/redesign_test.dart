import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/routes_form_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FROM -> TO', () {
    test('rewrites the prefix and joins with one slash', () {
      expect(
        routeRedirectUrl(
          uri: 'https://auth.example.com/',
          path: '/auth-dev/**',
          rewrite: RewritePathModel(replaceFrom: '/auth-dev/', replaceTo: '/'),
        ),
        'https://auth.example.com/**',
      );
    });

    test('an empty rewrite target means /, no source means no rewrite', () {
      expect(RewritePathModel.fromFields(from: '/a/', to: '')?.replaceTo, '/');
      expect(RewritePathModel.fromFields(from: '', to: '/x'), isNull);
    });
  });

  test('duplicate name: -copy, then -copy-2 ignoring case', () {
    expect(duplicateRouteName('auth', ['auth']), 'auth-copy');
    expect(duplicateRouteName('auth', ['auth', 'AUTH-copy']), 'auth-copy-2');
    expect(
      duplicateRouteName('auth', ['auth-copy', 'auth-copy-2']),
      'auth-copy-3',
    );
  });

  group('backup validation', () {
    //parseBackup never calls the api
    final repo = RoutesRepo(client: RoutesClient(Dio()));

    test('accepts a list of complete routes', () {
      expect(
        repo.parseBackup('[{"name":"a","path":"/a","uri":"http://a"}]'),
        hasLength(1),
      );
    });

    for (final (label, raw) in [
      ('an empty list', '[]'),
      ('not a list', '{"name":"a"}'),
      ('invalid json', 'nope'),
      ('a missing uri', '[{"name":"a","path":"/a"}]'),
      ('a blank name', '[{"name":"","path":"/a","uri":"http://a"}]'),
    ]) {
      test('rejects $label', () {
        expect(() => repo.parseBackup(raw), throwsA(isA<GlobalException>()));
      });
    }
  });

  group('calendar range', () {
    final d1 = DateTime(2026, 1, 10);
    final d2 = DateTime(2026, 1, 20);
    final before = DateTime(2026, 1, 5);

    test('first click starts, second ends', () {
      final started = pickRangeDay((from: null, to: null), d1);
      expect(started, (from: d1, to: null));
      expect(pickRangeDay(started, d2), (from: d1, to: d2));
    });

    test('a day before the start becomes the new start', () {
      expect(pickRangeDay((from: d1, to: null), before), (
        from: before,
        to: null,
      ));
    });

    test('a click on a full range starts a new one', () {
      expect(pickRangeDay((from: d1, to: d2), before), (
        from: before,
        to: null,
      ));
    });
  });

  test('page buttons: at most 3, around the current page', () {
    expect(visiblePages(page: 1, pageCount: 1), [1]);
    expect(visiblePages(page: 1, pageCount: 10), [1, 2, 3]);
    expect(visiblePages(page: 5, pageCount: 10), [4, 5, 6]);
    expect(visiblePages(page: 10, pageCount: 10), [8, 9, 10]);
  });

  group('gateway status', () {
    test('offline until a retry reaches the gateway', () async {
      var up = false;
      final status = GatewayStatusCubit(ping: () async => up);
      status.markOffline();
      expect(status.state.offline, isTrue);

      await status.retry();
      expect(status.state.offline, isTrue);
      expect(status.state.retrying, isFalse);

      up = true;
      await status.retry();
      expect(status.state.offline, isFalse);
      expect(status.state.lastLoadedAt, isNotNull);
      await status.close();
    });
  });
}
