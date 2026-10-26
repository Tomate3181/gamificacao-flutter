import 'dart:async';

import 'package:flutter/foundation.dart';

/// Converte um stream em [Listenable] para o `refreshListenable` do GoRouter.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<void> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<void> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
