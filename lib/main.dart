import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

import 'bootstrap_app.dart';
import 'app_dependencies.dart';

const _demoMode = bool.fromEnvironment('AXIOS_DEMO_MODE');

Future<AppDependencies> _bootstrapDemo() async => AppDependencies.demo();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  runApp(AxiosBootstrapApp(bootstrap: _demoMode ? _bootstrapDemo : null));
}
