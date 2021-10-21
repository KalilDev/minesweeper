import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'game.dart';

class _TileColors {
  final Color contentBackground;
  final Color contentBorder;
  final Color contentDetail;
  final Color shadow;

  const _TileColors({
    required this.contentBackground,
    required this.contentBorder,
    required this.contentDetail,
    required this.shadow,
  });

  static final _TileColors standard = _TileColors(
    shadow: Colors.grey[800]!,
    contentBackground: Colors.grey[400]!,
    contentBorder: Colors.grey[600]!,
    contentDetail: Colors.grey[600]!,
  );
  static final _TileColors standardDark = _TileColors(
    shadow: Colors.grey[500]!,
    contentBackground: Colors.grey[700]!,
    contentBorder: Colors.grey[800]!,
    contentDetail: Colors.grey[800]!,
  );

  _TileColors copyWith({
    Color? contentBackground,
    Color? contentBorder,
    Color? contentDetail,
    Color? shadowLight,
    Color? shadow,
  }) =>
      _TileColors(
        contentBackground: contentBackground ?? this.contentBackground,
        contentBorder: contentBorder ?? this.contentBorder,
        contentDetail: contentDetail ?? this.contentDetail,
        shadow: shadow ?? this.shadow,
      );
}

class _TileDecoration extends Decoration {
  final double borderWidth;
  final _TileColors colors;
  final BorderRadius? borderRadius;

  _TileDecoration(
      {this.borderWidth = 4.0, required this.colors, this.borderRadius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _TileDecorationPainter(
        borderWidth,
        colors,
        borderRadius ?? BorderRadius.circular(4.0),
      );
}

class _TileDecorationPainter extends BoxPainter {
  final double borderWidth;
  final _TileColors colors;
  final BorderRadius borderRadius;

  _TileDecorationPainter(this.borderWidth, this.colors, this.borderRadius);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    var rect = offset & size;

    rect = rect.deflate(borderWidth + 3 / 2);
    final contentPaint = Paint()..color = colors.contentBackground;
    final borderRRect = borderRadius.toRRect(rect);

    canvas.drawShadow(
        Path()..addRRect(borderRadius.toRRect(rect.inflate(3 / 2))),
        colors.shadow,
        2.0,
        false);
    canvas.drawRRect(borderRRect, contentPaint);

    contentPaint
      ..color = colors.contentBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(borderRRect, contentPaint);

    final padding = rect.height / 4;
    contentPaint..color = colors.contentDetail;
    rect = rect.deflate(padding);
    canvas.drawLine(rect.topLeft, rect.topRight, contentPaint);
    canvas.drawLine(rect.centerLeft, rect.centerRight, contentPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, contentPaint);
  }
}

class TileWidget extends StatelessWidget {
  final Tile tile;
  const TileWidget({Key? key, required this.tile}) : super(key: key);
  static const side = 48.0;

  Widget _ink(BuildContext context, {required Widget child}) => InkWell(
        onTap: () => Actions.invoke(context, TilePressedIntent(tile.position)),
        onLongPress: () =>
            Actions.invoke(context, TilePressedIntent(tile.position, true)),
        child: child,
      );
  Widget _buildHidden(BuildContext context) => Container(
      decoration: _TileDecoration(
        colors: (Theme.of(context).brightness == Brightness.dark
                ? _TileColors.standardDark
                : _TileColors.standard)
            .copyWith(
          contentBackground: () {
            switch (tile.display) {
              case TileDisplay.none:
              case TileDisplay.revealed:
                return null;
              case TileDisplay.cone:
                return Colors.orange;
              case TileDisplay.wrongCone:
                return Colors.red;
            }
          }(),
          contentDetail: tile.display == TileDisplay.cone ||
                  tile.display == TileDisplay.wrongCone
              ? Colors.transparent
              : null,
        ),
      ),
      child: Center(
        child: () {
          switch (tile.display) {
            case TileDisplay.revealed:
            case TileDisplay.none:
              return SizedBox.expand();
            case TileDisplay.cone:
              return Icon(Icons.warning);
            case TileDisplay.wrongCone:
              return Icon(Icons.error);
          }
        }(),
      ));

  TextStyle _styleForCount(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color _c(MaterialColor color) => isDark ? color[200]! : color;
    Color _dc(MaterialColor color) => isDark ? color[400]! : color[900]!;
    return Theme.of(context).textTheme.headline4!.copyWith(
          color: [
            Colors.transparent,
            _c(Colors.blue),
            _c(Colors.green),
            _c(Colors.red),
            _dc(Colors.indigo),
            _dc(Colors.green),
            _dc(Colors.red),
          ][count],
          fontWeight: [
            FontWeight.normal,
            FontWeight.w500,
            FontWeight.w600,
            FontWeight.w700,
            FontWeight.w900,
            FontWeight.w900,
            FontWeight.w900,
          ][count],
        );
  }

  Widget _buildRevealed(BuildContext context) => Center(
      child: tile.isBomb
          ? FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                Icons.dangerous,
                color: Theme.of(context).colorScheme.error,
                size: side,
              ),
            )
          : Text(
              tile.neighboringBombs > 0 ? tile.neighboringBombs.toString() : '',
              style: _styleForCount(context, tile.neighboringBombs),
            ));
  Widget _shortcut({required Widget child}) => Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
              TilePressedIntent(tile.position, true),
        },
        child: child,
      );

  Widget build(BuildContext context) => _shortcut(
        child: _ink(
          context,
          child: () {
            switch (tile.display) {
              case TileDisplay.none:
              case TileDisplay.cone:
              case TileDisplay.wrongCone:
                return _buildHidden(context);
              case TileDisplay.revealed:
                return _buildRevealed(context);
            }
          }(),
        ),
      );
}
