import 'package:flutter/material.dart';
import '../services/debug_service.dart';

// 全局路由观察者，用于跟踪当前路由名称
class GlobalRouteObserver extends NavigatorObserver {
  final ValueNotifier<String?> currentRouteNameNotifier = ValueNotifier<String?>(null);
  final DebugService _debugService = DebugService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    currentRouteNameNotifier.value = route.settings.name;
    _debugService.recordRoute('Push: ${route.settings.name ?? 'Unknown'}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      currentRouteNameNotifier.value = previousRoute.settings.name;
      _debugService.recordRoute('Pop to: ${previousRoute.settings.name ?? 'Unknown'}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      currentRouteNameNotifier.value = newRoute.settings.name;
      _debugService.recordRoute('Replace: ${newRoute.settings.name ?? 'Unknown'}');
    }
  }
}

final GlobalRouteObserver globalRouteObserver = GlobalRouteObserver();
