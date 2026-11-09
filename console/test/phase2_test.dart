import 'package:api_gateway_front/app_exporter.dart';
import 'package:api_gateway_front/features/routes/view/form/routes_advanced_section.dart';
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

  group('GET /routes/{id} shape', () {
    test('id and nested rewrite_path are parsed', () {
      final r = RouteResponse.fromJson({
        'id': '1',
        'created_at': '2026-01-01T00:00:00Z',
        'name': 'a',
        'path': '/a/**',
        'uri': 'http://a',
        'rewrite_path': {'replace_from': '/a/', 'replace_to': '/'},
        'description': null,
      });
      expect(r.id, '1');
      expect(r.rewritePath?.replaceFrom, '/a/');
      expect(r.rewritePath?.replaceTo, '/');
    });

    test('null rewrite_path means no rewrite', () {
      final r = RouteResponse.fromJson({
        'id': '1',
        'created_at': '2026-01-01T00:00:00Z',
        'name': 'a',
        'path': '/a/**',
        'uri': 'http://a',
        'rewrite_path': null,
      });
      expect(r.rewritePath, isNull);
    });
  });

  group('advanced route fields are never lost', () {
    const advanced = {
      'order': -1,
      'methods': ['GET'],
      'hosts': ['**.example.com'],
      'headers': [
        {'name': 'X-Tenant', 'regexp': null},
      ],
      'filters': [
        {
          'name': 'RemoveRequestHeader',
          'args': ['X-A'],
        },
      ],
    };
    final response = {
      'id': '1',
      'created_at': '2026-01-01T00:00:00Z',
      'name': 'a',
      'path': '/a/**',
      'uri': 'http://a',
      'rewrite_path': null,
      ...advanced,
    };

    test('from the api response to the PUT body', () {
      final model = RouteResponse.fromJson(response).toModel();
      final body = RouteFormModel(
        name: model.name,
        path: model.path,
        uri: model.uri,
        description: model.description,
        advanced: model.advanced,
      ).toRequest().toJson();
      expect(body, containsPair('order', -1));
      expect(body, containsPair('filters', advanced['filters']));
      expect(body, containsPair('headers', advanced['headers']));
      expect(body, containsPair('hosts', advanced['hosts']));
      expect(body, containsPair('methods', advanced['methods']));
    });

    test('through a backup file', () {
      final backup = RouteResponse.fromJson(response).toModel().toJson();
      final body = RouteRequest.fromJson(backup).toJson();
      expect(body, containsPair('order', -1));
      expect(body, containsPair('methods', advanced['methods']));
    });

    test('a backup from an older version gets the defaults', () {
      final body = RouteRequest.fromJson({
        'name': 'a',
        'path': '/a/**',
        'uri': 'http://a',
      }).toJson();
      expect(body, containsPair('order', 0));
      expect(body, containsPair('methods', isEmpty));
    });

    test('a wrong type in a backup fails while parsing', () {
      expect(
        () => RouteAdvancedModel.fromJson({
          'methods': [1],
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('advanced section', () {
    test('order accepts empty, negatives and only 32-bit integers', () {
      for (final valid in ['', '0', '-5', '2147483647', '-2147483648']) {
        expect(RouteAdvancedModel.isValidOrder(valid), isTrue, reason: valid);
      }
      for (final invalid in ['-', '2147483648', '-2147483649']) {
        expect(RouteAdvancedModel.isValidOrder(invalid), isFalse, reason: invalid);
      }
    });

    test('the form controller gives back what it loaded', () {
      const model = RouteAdvancedModel(
        order: -1,
        methods: ['POST', 'GET'],
        hosts: ['a.com', 'b.com'],
        headers: [
          RouteHeaderCondition(name: 'X-A'),
          RouteHeaderCondition(name: 'X-B', regexp: 'b.*'),
        ],
        filters: [
          RouteFilterModel(name: 'AddRequestHeader', args: ['X-C', 'c']),
          RouteFilterModel(name: 'RemoveResponseHeader', args: ['X-D']),
        ],
      );
      final json = (RouteAdvancedFormController()..load(model)).toModel().toJson();
      //methods are sent in the fixed order of the chips
      expect(json, {
        ...model.toJson(),
        'methods': ['GET', 'POST'],
      });
    });

    test('a filter only sends the args it takes', () {
      final controller = RouteAdvancedFormController()
        ..load(
          const RouteAdvancedModel(
            filters: [
              RouteFilterModel(name: 'AddRequestHeader', args: ['X-C', 'c']),
            ],
          ),
        );
      controller.filters.single.name = 'RemoveRequestHeader';
      expect(controller.toModel().filters.single.args, ['X-C']);
    });

    test('api errors of the section are recognized', () {
      for (final source in [
        'order',
        'methods[0].<list element>',
        'hosts[1].<list element>',
        'headers[0].validRegexp',
        'filters[2].supported',
      ]) {
        expect(isAdvancedRouteError(source), isTrue, reason: source);
      }
      for (final source in ['name', 'rewrite_path.replace_from', 'orders']) {
        expect(isAdvancedRouteError(source), isFalse, reason: source);
      }
    });
  });
}
