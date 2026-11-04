import 'package:flutter/widgets.dart';
import '../components/feedback/app_sound_scope.dart';
import 'app_interaction_gate.dart';

/// Observes successful system backs without replacing routing or PopScope guards.
class AppSystemBackSound {
  AppSystemBackSound() {
    dispatcher = _SystemSoundDispatcher(this);
  }
  late final RootBackButtonDispatcher dispatcher;
  int _systemRequests = 0;
  bool _requestPlayed = false;
  bool _gesturePlayed = false;
  final _observers = <_SystemSoundObserver>[];
  NavigatorObserver observer() {
    final observer = _SystemSoundObserver(this);
    _observers.add(observer);
    return observer;
  }

  bool get _blocked => _observers.any(
    (o) =>
        o.navigator?.mounted == true &&
        AppInteractionScope.maybeOf(o.navigator!.context)?.busy == true,
  );
}

class _SystemSoundDispatcher extends RootBackButtonDispatcher {
  _SystemSoundDispatcher(this.owner);
  final AppSystemBackSound owner;
  @override
  Future<bool> didPopRoute() async {
    if (owner._blocked) return true;
    if (owner._systemRequests == 0) owner._requestPlayed = false;
    owner._systemRequests++;
    try {
      return await super.didPopRoute();
    } finally {
      owner._systemRequests--;
    }
  }
}

class _SystemSoundObserver extends NavigatorObserver {
  _SystemSoundObserver(this.owner);
  final AppSystemBackSound owner;
  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    owner._gesturePlayed = false;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final host = navigator;
    if (host == null) return;
    if (owner._systemRequests > 0) {
      if (owner._requestPlayed) return;
      owner._requestPlayed = true;
      AppSoundScope.emit(host.context, UiSound.back);
    } else if (host.userGestureInProgress && !owner._gesturePlayed) {
      owner._gesturePlayed = true;
      AppSoundScope.emit(host.context, UiSound.back);
    }
  }
}
