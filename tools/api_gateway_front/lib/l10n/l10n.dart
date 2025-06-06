// Copyright (c) 2021, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/widgets.dart';

//fvm flutter pub run build_runner build --delete-conflicting-outputs
extension AppLocalizationsX on BuildContext {
  AppLocalizations get intl => AppLocalizations.of(this);
}
