import 'package:go_router/go_router.dart';
import '../../design_system/platform/app_page_transitions.dart';
import '../../design_system/platform/app_deferred_section.dart';

/// Explicit SDK Material pages: do not depend on go_router's app detection.
/// Animation is owned by the shared AppTheme, not individual feature routes.
GoRoute appRoute({
  required String path,
  required GoRouterWidgetBuilder builder,
  List<RouteBase> routes = const [],
  AppPageMotion motion = AppPageMotion.standard,
  int? sectionIndex,
}) => GoRoute(
  path: path,
  routes: routes,
  pageBuilder: (context, state) => AppMotionPage<void>(
    motion: motion,
    sectionIndex: sectionIndex,
    key: state.pageKey,
    name: state.name ?? state.path,
    restorationId: state.pageKey.value,
    arguments: <String, String>{
      ...state.pathParameters,
      ...state.uri.queryParameters,
    },
    child: motion == AppPageMotion.section && sectionIndex != null
        ? AppDeferredSection(
            identity: (state.matchedLocation, state.uri.query),
            sectionIndex: sectionIndex,
            builder: (context) => builder(context, state),
          )
        : builder(context, state),
  ),
);
