import 'package:flutter/material.dart';

import 'game.dart';

class ToggleModeAction extends Action<ToggleModeIntent> {
  final VoidCallback toggle;

  ToggleModeAction({required this.toggle});
  @override
  Object? invoke(ToggleModeIntent intent) {
    toggle();
  }
}

class RevealOrMarkTileAction extends Action<TilePressedIntent> {
  final ValueGetter<Board> board;
  final ValueGetter<bool> isMarking;
  final VoidCallback onLost;
  final VoidCallback onWon;
  final ValueChanged<VoidCallback> setState;
  RevealOrMarkTileAction({
    required this.board,
    required this.isMarking,
    required this.setState,
    required this.onLost,
    required this.onWon,
  });
  @override
  Object? invoke(TilePressedIntent intent) {
    final board = this.board();
    final tile = board.grid[intent.position.x][intent.position.y];
    if (tile.display == TileDisplay.revealed) {
      return null;
    }
    var isMarking = this.isMarking();
    isMarking = intent.isAlternate ? !isMarking : isMarking;
    if (isMarking) {
      board.toggleMark(tile.position.x, tile.position.y);
      setState(() => null);
      return null;
    }
    if (tile.display == TileDisplay.cone ||
        tile.display == TileDisplay.wrongCone) {
      return null;
    }
    if (board.tryReveal(tile.position.x, tile.position.y)) {
      onLost();
    }
    if (board.didWin) {
      onWon();
    }

    setState(() => null);
  }
}

class ToggleModeIntent extends Intent {
  const ToggleModeIntent();
}

class TilePressedIntent extends Intent {
  final Position position;
  final bool isAlternate;

  const TilePressedIntent(this.position, [this.isAlternate = false]);
}
