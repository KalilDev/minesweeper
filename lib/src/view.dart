import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minesweeper/src/tile.dart';

import 'actions.dart';
import 'board.dart';
import 'game.dart';

class MinesweeperView extends StatefulWidget {
  _MinesweeperViewState createState() => _MinesweeperViewState();
}

class _MinesweeperViewState extends State<MinesweeperView> {
  bool isMarking = false;
  Board? board;
  int difficulty = 0;
  double get tileWidgetSide => const [
        TileWidget.side,
        TileWidget.side,
        TileWidget.side,
        TileWidget.side * 0.8,
        TileWidget.side * 0.8,
        TileWidget.side * 0.8,
      ][difficulty];
  Board _genBoard(BuildContext context) {
    final size = MediaQuery.of(context).size / tileWidgetSide;
    return Board.generate(
        size.width.ceil(),
        size.height.ceil(),
        const [
          1 / 10,
          1 / 8,
          1 / 6,
          1 / 5,
          1 / 4,
          1 / 3,
        ][difficulty]);
  }

  void didChangeDependencies() {
    board ??= _genBoard(context);
    super.didChangeDependencies();
  }

  void _onLost() async {
    final restart = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Você perdeu!'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Reiniciar')),
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Ok')),
              ],
            ));
    if (restart == true) {
      _onRestart();
    }
  }

  void _onWon() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('Você ganhou!'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Reiniciar')),
            ],
          )).then((_) => _onRestart());

  void _onRestart() {
    setState(() => board = _genBoard(context));
  }

  late final _actions = <Type, Action>{
    ToggleModeIntent:
        ToggleModeAction(toggle: () => setState(() => isMarking = !isMarking)),
    TilePressedIntent: RevealOrMarkTileAction(
      board: () => board!,
      isMarking: () => isMarking,
      setState: setState,
      onLost: _onLost,
      onWon: _onWon,
    )
  };
  static final _shortcuts = <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.enter):
        ToggleModeIntent(),
  };

  Widget _action({required Widget child}) => Actions(
        actions: _actions,
        child: child,
      );
  Widget _shortcut({required Widget child}) => Shortcuts(
        shortcuts: _shortcuts,
        child: child,
      );
  Widget _appbar(BuildContext context) => SliverAppBar(
          title: Text('Minesweeper'),
          leading: Container(
            color: Theme.of(context).colorScheme.error,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Center(
                  child: Text(
                    '${board!.userBombCount}',
                    style: Theme.of(context).textTheme.headline4!.copyWith(
                          color: Theme.of(context).colorScheme.onError,
                        ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<int>(
              itemBuilder: (context) => List.generate(
                  6,
                  (i) => PopupMenuItem(
                        child: Text(
                          'Dificuldade ${i + 1}',
                        ),
                        value: i,
                      )),
              onSelected: (i) {
                if (difficulty == i) {
                  return;
                }
                difficulty = i;
                _onRestart();
              },
              initialValue: difficulty,
              child: Center(child: Text('Dificuldade ${difficulty + 1}')),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _onRestart,
            ),
          ]);
  Widget _body(BuildContext context) => SizedBox.fromSize(
        size: MediaQuery.of(context).size,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              height: board!.height * tileWidgetSide,
              width: board!.width * tileWidgetSide,
              child: BoardGrid(
                board: board!,
              ),
            ),
          ),
        ),
      );

  Widget _fab(BuildContext context) => FloatingActionButton.extended(
        icon: Icon(isMarking ? Icons.edit : Icons.dangerous),
        label: Text(isMarking ? 'MARCAR' : 'DETONAR'),
        shape: isMarking
            ? StadiumBorder()
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        elevation: isMarking ? 4.0 : 16.0,
        backgroundColor: isMarking ? Colors.orange : Colors.red,
        onPressed: () => setState(
          () => isMarking = !isMarking,
        ),
      );
  List<Widget> _slivers(BuildContext context) => [
        _appbar(context),
        SliverFillRemaining(
          child: _body(context),
          hasScrollBody: false,
        )
      ];
  Widget _notificationListener({required Widget child}) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: child,
      );
  bool _onNotification(ScrollNotification notification) {
    final frac = notification.metrics.pixels / _kAppBarHeight;
    final showFab = frac.round() == 0;
    if (this.showFab != showFab) {
      setState(() => this.showFab = showFab);
    }
    return false;
  }

  static const _kAppBarHeight = kToolbarHeight + 8.0;

  bool showFab = true;
  Widget build(BuildContext context) => _action(
        child: _shortcut(
          child: Scaffold(
            body: _notificationListener(
              child: CustomScrollView(
                slivers: _slivers(context),
                physics:
                    SnappingScrollPhysics(snapPoints: const [_kAppBarHeight]),
              ),
            ),
            floatingActionButton: showFab ? _fab(context) : null,
          ),
        ),
      );
}

/// Scroll physics used by a [PageView].
///
/// These physics cause the page view to snap to page boundaries.
///
/// See also:
///
///  * [ScrollPhysics], the base class which defines the API for scrolling
///    physics.
///  * [PageView.physics], which can override the physics used by a page view.
class SnappingScrollPhysics extends ScrollPhysics {
  final List<double> snapPoints;

  /// Creates physics for a [PageView].
  const SnappingScrollPhysics({
    ScrollPhysics? parent,
    required this.snapPoints,
  }) : super(parent: parent);

  @override
  SnappingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappingScrollPhysics(
      parent: buildParent(ancestor),
      snapPoints: snapPoints,
    );
  }

  double _getTargetPixels(
      ScrollMetrics position, Tolerance tolerance, double velocity) {
    final toPrevious = velocity < -tolerance.velocity;
    double target = 0;
    for (final snap in snapPoints) {
      if (snap >= position.pixels) {
        return toPrevious ? target : snap;
      }
      target = snap;
    }
    return target;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
      return super.createBallisticSimulation(position, velocity);
    final Tolerance tolerance = this.tolerance;
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels)
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: tolerance);
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
