import 'package:console/app_exporter.dart';

class AuthInit {
  static Future<void> init() async {
    AuthClient client = AuthClient(app.di.find());
    app.di.put(client);

    AuthRepo repo = AuthRepo(client: client, storage: app.di.find());
    app.di.put(repo);

    AuthCubit cubit = AuthCubit(repo: repo);
    app.di.put(cubit);

    await cubit.init();
  }
}
