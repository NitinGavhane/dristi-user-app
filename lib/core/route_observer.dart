import 'package:flutter/widgets.dart';

/// Lets a widget find out that another screen has been pushed over the one it
/// lives on.
///
/// Pushing a route does not dispose the screen underneath — it stays alive in
/// the navigator stack, so a `StatefulWidget` there gets no callback at all. A
/// playing video would happily carry on with its sound while the shopper reads
/// a different page. Widgets that own something worth stopping mix in
/// `RouteAware`, subscribe to this observer, and pause on `didPushNext`.
///
/// Registered once, on the root [MaterialApp]'s `navigatorObservers`.
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();
