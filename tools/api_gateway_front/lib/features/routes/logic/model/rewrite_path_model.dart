class RewritePathModel {
  final String replaceFrom;
  final String replaceTo;

  RewritePathModel({required this.replaceFrom, required this.replaceTo});

  factory RewritePathModel.fromJson(Map<String, dynamic> json) {
    return RewritePathModel(
      replaceFrom: json['replace_from'],
      replaceTo: json['replace_to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'replace_from': replaceFrom, 'replace_to': replaceTo};
  }
}
