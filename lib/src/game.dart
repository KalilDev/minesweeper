import 'dart:math';

import 'package:flutter/material.dart';

class Board {
// List of columns [x][y]
  final List<List<Tile>> grid;
  final int height;
  final int width;
  final int bombCount;

  Board._(this.grid, this.height, this.width, this.bombCount);
  int markedCount = 0;
  int get userBombCount => bombCount - markedCount;
  factory Board.generate(int width, int height, double bombChance) {
    final rand = Random();
    var bombCount = 0;
    final grid = List<List<Tile>>.generate(
      width,
      (x) => List<Tile>.generate(
        height,
        (y) {
          var isBomb = false;
          if (rand.nextDouble() <= bombChance) {
            bombCount++;
            isBomb = true;
          }

          return Tile(
            isBomb,
            Position(x, y),
          );
        },
      ),
    );
    final board = Board._(grid, height, width, bombCount);
    for (var x = 0; x < width; x++)
      for (var y = 0; y < height; y++)
        board.grid[x][y].neighboringBombs =
            board.neighborsOf(x, y).where((n) => n.isBomb).length;
    return board;
  }
  Iterable<Tile> neighborsOf(int x, int y) {
    final startX = (x - 1).clamp(0, width), startY = (y - 1).clamp(0, height);
    final endX = (x + 2).clamp(0, width), endY = (y + 2).clamp(0, height);
    return grid
        .skip(startX)
        .take(endX - startX)
        .expand((e) => e.skip(startY).take(endY - startY))
        .where((p) => !(p.position.x == x && p.position.y == y));
  }

  Iterable<Tile> immediateNeighborsOf(int x, int y) =>
      neighborsOf(x, y).where((n) => n.position.x == x || n.position.y == y);
  Iterable<Tile> get tiles => grid.expand((e) => e);
  void revealFullBoard() => tiles.forEach((e) {
        if (e.display == TileDisplay.cone) {
          e.display = e.isBomb ? TileDisplay.cone : TileDisplay.wrongCone;
          return;
        }
        e.display = TileDisplay.revealed;
        return;
      });

  void toggleMark(int x, int y) {
    final tile = grid[x][y];
    if (tile.display == TileDisplay.revealed) {
      return;
    }
    final wasNone = tile.display == TileDisplay.none;
    tile.display = wasNone ? TileDisplay.cone : TileDisplay.none;
    markedCount += wasNone ? 1 : -1;
  }

  void reveal(Tile t, [Set<Position>? visited]) {
    visited ??= {};
    if (visited.contains(t.position)) {
      return;
    }
    visited.add(t.position);
    if (t.display != TileDisplay.none || t.isBomb) {
      return;
    }
    t.display = TileDisplay.revealed;
    if (t.neighboringBombs != 0) {
      return;
    }

    neighborsOf(t.position.x, t.position.y).forEach((n) => reveal(n, visited));
  }

  bool tryReveal(int x, int y) {
    if (grid[x][y].isBomb) {
      revealFullBoard();
      return true;
    }
    reveal(grid[x][y]);
    return false;
  }

  static bool _tileIsWinning(Tile t) {
    if (t.isBomb) {
      return t.display == TileDisplay.cone;
    }
    return t.display == TileDisplay.revealed;
  }

  bool get didWin => grid
      .expand((row) => row)
      .fold(true, (isWinning, tile) => isWinning && _tileIsWinning(tile));
}

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);
  int get hashCode => hashValues(x, y);
  bool operator ==(other) =>
      other is Position ? other.x == x && other.y == y : false;
}

enum TileDisplay {
  none,
  cone,
  wrongCone,
  revealed,
}

class Tile {
  TileDisplay display = TileDisplay.none;
  final bool isBomb;
  final Position position;
  late int neighboringBombs;

  Tile(this.isBomb, this.position);
}
