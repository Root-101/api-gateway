import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException badResponse(int status, dynamic data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  group('ApiExceptionConverter', () {
    test('404 with ProblemDetail json does not crash and uses detail', () {
      final e = ApiExceptionConverter.parse(
        badResponse(404, {'title': 'Not Found', 'detail': 'No route abc'}),
      );
      expect(e.type, GlobalExceptionType.general);
      expect(e.message, 'No route abc');
    });

    test('409 with plain string body keeps the message', () {
      final e = ApiExceptionConverter.parse(badResponse(409, 'Name in use'));
      expect(e.message, 'Name in use');
    });

    test('400 with empty body falls back to status', () {
      expect(ApiExceptionConverter.parse(badResponse(400, null)).message,
          'Error 400');
    });

    test('422 tolerates null/non-string invalid_value', () {
      final e = ApiExceptionConverter.parse(
        badResponse(422, [
          {'source': 'name', 'invalid_value': null, 'message': 'required'},
          {'source': 'size', 'invalid_value': 5, 'message': 'too small'},
        ]),
      );
      expect(e.type, GlobalExceptionType.validation);
      final errors = e.data as List<ValidationError>;
      expect(errors.asFailedValidations(),
          {'name': 'required', 'size': 'too small'});
      expect(errors[1].invalidValue, '5');
    });

    test('422 with non-list body is a general error, not a crash', () {
      final e = ApiExceptionConverter.parse(badResponse(422, 'bad'));
      expect(e.type, GlobalExceptionType.general);
    });

    test('connection error is general, not auth (must not log out)', () {
      final e = ApiExceptionConverter.parse(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(e.type, GlobalExceptionType.general);
    });

    test('429 lockout is general (no logout) and shows the detail', () {
      final e = ApiExceptionConverter.parse(
        badResponse(429, {'detail': 'Too many failed attempts, try again later'}),
      );
      expect(e.type, GlobalExceptionType.general);
      expect(e.message, 'Too many failed attempts, try again later');
    });

    test('401 and 403 are auth', () {
      expect(ApiExceptionConverter.parse(badResponse(401, null)).type,
          GlobalExceptionType.auth);
      expect(ApiExceptionConverter.parse(badResponse(403, null)).type,
          GlobalExceptionType.auth);
    });
  });

  group('rewrite_path optional', () {
    final base = {
      'id': '1',
      'created_at': '2026-01-01T00:00:00Z',
      'name': 'a',
      'path': '/a/**',
      'uri': 'http://a',
    };

    test('route without rewrite_path parses', () {
      final r = RouteResponse.fromJson({...base, 'rewrite_path': null});
      expect(r.rewritePath, isNull);
      expect(r.description, '');
      final model = r.toModel(gatewayUrl: 'https://gw');
      expect(model.redirectTo, 'http://a/a/**');
    });

    test('request sends null rewrite when both fields are empty', () {
      final form = RouteFormModel(
        name: 'a',
        path: '/a/**',
        uri: 'http://a',
        description: 'keep me',
        rewritePath: RewritePathModel.fromFields(from: '', to: ''),
      );
      final json = form.toRequest().toJson();
      expect(json['rewrite_path'], isNull);
      expect(json['description'], 'keep me');
    });

    test('request sends both rewrite values when set', () {
      final json = RouteFormModel(
        name: 'a',
        path: '/a/**',
        uri: 'http://a',
        description: '',
        rewritePath: RewritePathModel.fromFields(from: '/a/', to: '/'),
      ).toRequest().toJson();
      expect(json['rewrite_path'], {'replace_from': '/a/', 'replace_to': '/'});
    });
  });
}
