import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Lays out the shell branches, keeping the inactive ones alive but offstage.
///
/// A branch with [ExtendedShellBranch.saveState] turned off is built only while
/// it is the active one, so leaving it tears it down.
class ExtendedShellBranchContainer extends StatelessWidget {
  const ExtendedShellBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: [
        for (int i = 0; i < children.length; i++)
          _buildRouteBranchContainer(
            context,
            currentIndex == i,
            children[i],
          ),
      ],
    );
  }

  Widget _buildRouteBranchContainer(
    BuildContext context,
    bool isActive,
    Widget child,
  ) {
    final branch = (child as dynamic).branch as ExtendedShellBranch;

    if (!branch.saveState) {
      // For branches that don't save state, only render when active
      return isActive ? child : const SizedBox.shrink();
    }

    return Offstage(
      offstage: !isActive,
      child: TickerMode(
        enabled: isActive,
        child: child,
      ),
    );
  }
}

/// An extended `StatefulShellBranch` that adds the option to not save state.
/// See https://github.com/flutter/flutter/issues/142258.
class ExtendedShellBranch extends StatefulShellBranch {
  ExtendedShellBranch({
    this.saveState = true,
    super.initialLocation,
    super.navigatorKey,
    super.observers,
    super.restorationScopeId,
    required super.routes,
  });

  /// Whether to save the state for this branch.
  final bool saveState;
}
