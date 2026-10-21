import 'package:go_router/go_router.dart';

/// Tab helpers for `StatefulShellRoute`.
///
/// Every tab keeps its own navigation stack, which is go_router's default.
/// These helpers add the two behaviours most apps want on top.
extension JugnuShell on StatefulNavigationShell {
  /// Switches to the tab at [index].
  ///
  /// Tapping the tab that is already open takes it back to its first page,
  /// like the bottom bars in most apps. Set [resetOnReselect] to false to
  /// keep the stack instead.
  ///
  /// ```dart
  /// NavigationBar(
  ///   selectedIndex: shell.currentIndex,
  ///   onDestinationSelected: shell.switchTab,
  ///   destinations: [...],
  /// )
  /// ```
  void switchTab(int index, {bool resetOnReselect = true}) => goBranch(
    index,
    initialLocation: resetOnReselect && index == currentIndex,
  );

  /// Takes a tab back to its first page. Defaults to the current tab.
  void resetTab([int? index]) =>
      goBranch(index ?? currentIndex, initialLocation: true);
}
