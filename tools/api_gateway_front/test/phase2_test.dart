import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

RewritePathModel rw(String from, String to) =>
    RewritePathModel(replaceFrom: from, replaceTo: to);

void main() {
  group('RewritePathModel.apply (Spring RewritePath semantics)', () {
    test('plain prefix', () {
      expect(rw('/a/', '/').apply('/a/users'), '/users');
    });

    test('regex with escaped named group, as in the Spring docs', () {
      expect(
        rw(r'/red/?(?<segment>.*)', r'/$\{segment}').apply('/red/blue/x'),
        '/blue/x',
      );
    });

    test(r'unescaped ${name} and numbered $1 groups', () {
      expect(rw(r'/v1/(?<rest>.*)', r'/${rest}').apply('/v1/a'), '/a');
      expect(rw(r'/v1/(.*)', r'/api/$1').apply('/v1/a'), '/api/a');
    });

    test('invalid regex leaves the path untouched', () {
      expect(rw('/a/(', '/').apply('/a/x'), '/a/x');
    });

    test('redirectTo only rewrites the path, not the uri', () {
      final model = RouteFormModel(
        name: 'a',
        path: '/api/**',
        uri: 'http://api.host',
        description: '',
        rewritePath: rw('/api', ''),
      );
      expect(model.redirectTo, 'http://api.host/**');
    });
  });

  group('GET /routes/{id} raw entity shape', () {
    test('route_id and flat rewrite fields are parsed', () {
      final r = RouteResponse.fromJson({
        'route_id': '1',
        'created_at': '2026-01-01T00:00:00Z',
        'name': 'a',
        'path': '/a/**',
        'uri': 'http://a',
        'rewrite_path_from': '/a/',
        'rewrite_path_to': '/',
        'description': null,
      });
      expect(r.id, '1');
      expect(r.rewritePath?.replaceFrom, '/a/');
      expect(r.rewritePath?.replaceTo, '/');
    });

    test('flat rewrite fields null means no rewrite', () {
      final r = RouteResponse.fromJson({
        'route_id': '1',
        'created_at': '2026-01-01T00:00:00Z',
        'name': 'a',
        'path': '/a/**',
        'uri': 'http://a',
        'rewrite_path_from': null,
        'rewrite_path_to': null,
      });
      expect(r.rewritePath, isNull);
    });
  });
}
