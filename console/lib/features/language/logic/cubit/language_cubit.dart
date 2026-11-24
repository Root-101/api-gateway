import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageCubit extends Cubit<LanguageState>
    with GlobalEventBusCommunication<LanguageState> {
  final LanguageRepo repo;

  static final LanguageModel defaultLanguage = LanguageModel(
    icon: app.assets.icons.language.en,
    key: 'en',
    name: 'English',
  );

  List<LanguageModel> languages = [
    defaultLanguage,
    LanguageModel(
      icon: app.assets.icons.language.es,
      key: 'es',
      name: 'Español',
    ),
  ];

  LanguageModel currentSelectedLanguage = defaultLanguage;

  LanguageCubit({required this.repo})
    : super(LanguageInitialState(current: defaultLanguage, allLanguages: []));

  Future init() async {
    //nothing saved yet: the browser's language (main.dart already set it in AppIntl)
    String? key = await repo.loadKey() ?? AppIntl.current.languageCode;
    currentSelectedLanguage = _resolve(key: key);
    AppIntl.current = AppIntl.resolve(currentSelectedLanguage.key);
    await app.dateFormatter.setLocale(currentSelectedLanguage.key);

    emit(
      LanguageChangedState(
        current: currentSelectedLanguage,
        allLanguages: languages,
      ),
    );
  }

  void changeLanguageKey({required String languageKey}) {
    LanguageModel? language = languages
        .where((element) => element.key == languageKey)
        .firstOrNull;
    changeLanguage(language: language);
  }

  Future<void> changeLanguage({LanguageModel? language}) async {
    if (language == null) {
      return;
    }
    currentSelectedLanguage = language;
    repo.save(model: currentSelectedLanguage);
    AppIntl.current = AppIntl.resolve(language.key);
    await app.dateFormatter.setLocale(language.key);

    emit(
      LanguageChangedState(
        current: currentSelectedLanguage,
        allLanguages: languages,
      ),
    );
  }

  LanguageModel _resolve({required String? key}) {
    if (key == null) {
      return defaultLanguage;
    }
    return languages.firstWhere(
      (element) => element.key == key,
      orElse: () => defaultLanguage,
    );
  }

  Locale get locale => Locale(currentSelectedLanguage.key);
}

//states
abstract class LanguageState {
  final LanguageModel current;
  final List<LanguageModel> allLanguages;

  const LanguageState({required this.current, required this.allLanguages});
}

final class LanguageInitialState extends LanguageState {
  const LanguageInitialState({
    required super.current,
    required super.allLanguages,
  });
}

final class LanguageChangedState extends LanguageState {
  const LanguageChangedState({
    required super.current,
    required super.allLanguages,
  });
}
