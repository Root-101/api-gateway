import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

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
    String? key = await repo.loadKey();
    currentSelectedLanguage = _resolve(key: key);

    emit(
      LanguageChangedState(
        current: currentSelectedLanguage,
        allLanguages: languages,
      ),
    );
  }

  void changeLanguageKey({required String languageKey}) {
    LanguageModel? language = languages.firstWhereOrNull(
      (element) => element.key == languageKey,
    );
    changeLanguage(language: language);
  }

  void changeLanguage({LanguageModel? language}) {
    if (language == null) {
      return;
    }
    currentSelectedLanguage = language;
    repo.save(model: currentSelectedLanguage);

    emit(
      LanguageChangedState(
        current: currentSelectedLanguage,
        allLanguages: languages,
      ),
    );

    ///this is the trick that updates the widget tree without rebuilding every class
    WidgetsBinding.instance.reassembleApplication();
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

class LanguageInitialState extends LanguageState {
  const LanguageInitialState({
    required super.current,
    required super.allLanguages,
  });
}

class LanguageChangedState extends LanguageState {
  const LanguageChangedState({
    required super.current,
    required super.allLanguages,
  });
}
