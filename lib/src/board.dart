import 'package:flutter/material.dart';
import 'game.dart';
import 'tile.dart';

class BoardGrid extends StatelessWidget {
  final Board board;

  const BoardGrid({Key? key, required this.board}) : super(key: key);

  static Widget _expanded(Widget child) => Expanded(child: child);
  Widget _buildTile(BuildContext context, Tile tile) => TileWidget(tile: tile);
  Widget _buildCol(BuildContext context, List<Tile> col) => Column(
      children: col.map((e) => _buildTile(context, e)).map(_expanded).toList());
  Widget _buildRow(BuildContext context) => Row(
      children:
          board.grid.map((e) => _buildCol(context, e)).map(_expanded).toList());
  @override
  Widget build(BuildContext context) {
    return _buildRow(context);
  }
}
