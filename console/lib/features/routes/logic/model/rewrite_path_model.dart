///final url of a route: the uri + the (rewritten) path, joined by exactly one slash
String routeRedirectUrl({
  required String uri,
  required String path,
  RewritePathModel? rewrite,
}) {
  final target = rewrite?.apply(path) ?? path;
  return '${uri.replaceFirst(RegExp(r'/+$'), '')}/${target.replaceFirst(RegExp(r'^/+'), '')}';
}

class RewritePathModel {
  final String replaceFrom;
  final String replaceTo;

  RewritePathModel({required this.replaceFrom, required this.replaceTo});

  ///api contract: send both values or no rewrite at all (null), never empty strings; an empty "to" means `/`
  static RewritePathModel? fromFields({
    required String from,
    required String to,
  }) => from.isEmpty
      ? null
      : RewritePathModel(replaceFrom: from, replaceTo: to.isEmpty ? '/' : to);

  ///same as the gateway's RewritePath filter: Java `path.replaceAll(regex, to)` with `$\{` accepted as `${`
  String apply(String path) {
    final RegExp regex;
    try {
      regex = RegExp(replaceFrom);
    } on FormatException {
      return path; //invalid regex: the gateway would reject it too, show the path untouched
    }
    final replacement = replaceTo.replaceAll(r'$\', r'$');
    return path.replaceAllMapped(
      regex,
      (m) => replacement.replaceAllMapped(
        RegExp(r'\$\{(\w+)\}|\$(\d+)'),
        (r) => r[1] != null
            ? (_namedGroup(m, r[1]!) ?? '')
            : (int.parse(r[2]!) <= m.groupCount
                  ? m[int.parse(r[2]!)] ?? ''
                  : ''),
      ),
    );
  }

  static String? _namedGroup(Match m, String name) {
    try {
      return (m as RegExpMatch).namedGroup(name);
    } on ArgumentError {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {'replace_from': replaceFrom, 'replace_to': replaceTo};
  }
}
