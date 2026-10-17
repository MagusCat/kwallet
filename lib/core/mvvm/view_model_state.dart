import 'package:flutter/widgets.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_scope.dart';
import 'view_model.dart';

abstract class ViewModelState<W extends StatefulWidget, V extends ViewModel>
    extends State<W> {
  late final V model = createViewModel(AppScope.read(context));
  V createViewModel(AppDependencies dependencies);
  @override
  void initState() {
    super.initState();
    model.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    onViewModelChanged();
  }

  void onViewModelChanged() {}
  @override
  void dispose() {
    model.removeListener(_changed);
    model.dispose();
    super.dispose();
  }
}
