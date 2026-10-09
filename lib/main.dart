import 'package:flutter/widgets.dart';

import 'bootstrap_app.dart';
import 'app_dependencies.dart';

const _demoMode = bool.fromEnvironment('AXIOS_DEMO_MODE');

Future<AppDependencies> _bootstrapDemo() async => AppDependencies.demo();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AxiosBootstrapApp(bootstrap: _demoMode ? _bootstrapDemo : null));
}
