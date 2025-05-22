import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Padding used for text containers like bottom sheets and screens with mostly
/// text like the help page.
const double padding = 15.0;

dynamic addHaptic(Function function) {
  HapticFeedback.lightImpact();
  return function();
}

Widget menuWarning(BuildContext context) {
  final errorColor = Theme.of(context).colorScheme.error;
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.warning, color: errorColor),
      const SizedBox(width: 15.0),
      Flexible(
        child: Text(
          'Many settings cannot be changed while the OSD menu is active.',
          style: TextStyle(fontWeight: FontWeight.bold, color: errorColor),
        ),
      ),
    ],
  );
}

/// Returns a Future that won't complete until the given [duration] has passed.
///
/// This is distinct from adding a delay before executing a Future. With this
/// function, if [future] takes the same time or more to complete as [duration],
/// the returned Future will complete without adding any delay. If [future]
/// completes before [duration], the return Future will complete ~exactly when
/// [duration] has completed.
///
/// This is particularly useful when using FutureBuilder and waiting for an
/// operation to complete that could be very quick or could take long enough
/// that you're displaying a loading indicator. Using this function prevents the
/// loading indicator from flashing on the screen very briefly, which can look
/// like jank to a user.
Future<T> waitAtLeast<T>(
    {required Future<T> future, required Duration duration}) async {
  final results = await Future.wait([future, Future.delayed(duration)]);
  return Future<T>.value(results[0]);
}

bool isApple(BuildContext context) {
  final p = Theme.of(context).platform;
  return p == TargetPlatform.iOS || p == TargetPlatform.macOS;
}
