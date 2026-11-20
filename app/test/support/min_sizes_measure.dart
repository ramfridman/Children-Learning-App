// What a child's screen draws, read off the live widget tree for the minimum-sizes test (docs/design/m11/min-sizes.md): every piece of text
// (as drawn: font size x text scale x any FittedBox shrink), every picture (its ink, not its box), every answer tile, draggable and icon,
// with the keys of the widgets above it. Nothing here judges; `min_sizes_rules.dart` does.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/layout.dart' show SizeClass, sizeClassFor;
import 'package:nitznutz/design/stage_spec.dart';
import 'package:nitznutz/play/hint_hand.dart' show HintHand, PointingHand;
import 'package:nitznutz/play/hints/tap_plans.dart' show inkBoxOf;

/// What kind of characters a piece of text is made of.
enum TextKind { nikud, hebrew, numeral, latin, other }

class TextPiece {
  TextPiece({
    required this.text,
    required this.drawn,
    required this.base,
    required this.weight,
    required this.height,
    required this.rect,
    required this.keys,
    required this.kind,
    required this.maxLines,
    required this.family,
  });

  final String text;

  /// The size as drawn on the screen: font size x the system's text scale x the shrink of any FittedBox above it.
  final double drawn;

  /// The font size in the style (before the text scale).
  final double base;
  final int weight;
  final double? height;
  final Rect rect;
  final List<String> keys;
  final TextKind kind;
  final int? maxLines;
  final String? family;

  bool under(String key) => keys.contains(key);
  bool underAny(Iterable<String> ks) => ks.any(keys.contains);
  @override
  String toString() => 'text "$text" ${drawn.toStringAsFixed(1)}pt w$weight h$height $rect';
}

class PicturePiece {
  PicturePiece({
    required this.svg,
    required this.rect,
    required this.keys,
    required this.inkW,
    required this.inkH,
    required this.strip,
    required this.fit,
  });

  /// The SVG text, for telling two pictures apart.
  final String svg;

  /// The box as drawn (after any transform).
  final Rect rect;
  final List<String> keys;

  /// The ink as drawn, in points (the box less the empty margin of the drawing).
  final double inkW;
  final double inkH;

  /// A pattern strip (a viewBox of 120 by 48): its animals are the detail.
  final bool strip;
  final BoxFit fit;

  /// The side of a square of the same area as the ink: a long rectangle is as visible as its area says, not as its thin side; a line (no area) counts
  /// as half its length.
  double get ink => math.max(math.sqrt(inkW * inkH), 0.5 * math.max(inkW, inkH));

  /// The smallest feature a child must tell apart: the ink; for a strip one animal (0.143 of its width).
  double get detail => strip ? 0.143 * inkW : ink;
  bool under(String key) => keys.contains(key);
  bool underAny(Iterable<String> ks) => ks.any(keys.contains);
  @override
  String toString() =>
      'picture box ${rect.width.toStringAsFixed(1)}x${rect.height.toStringAsFixed(1)} ink ${inkW.toStringAsFixed(1)}x${inkH.toStringAsFixed(1)} $rect';
}

class TilePiece {
  TilePiece({required this.rect, required this.hit, required this.keys, required this.width});
  final Rect rect;
  final Rect hit;
  final List<String> keys;
  final double width;
}

class DragPiece {
  DragPiece({required this.rect, required this.keys});
  final Rect rect;
  final List<String> keys;
}

class IconPiece {
  IconPiece({required this.drawn, required this.rect, required this.keys, required this.code});
  final double drawn;
  final Rect rect;
  final List<String> keys;
  final int code;
  bool under(String key) => keys.contains(key);
}

/// Everything one screen drew at one moment.
class Screen {
  Screen({required this.board, required this.look, required this.sizeClass, required this.textScale});

  final Size board;
  final StageSpec? look;
  final SizeClass sizeClass;
  final double textScale;
  final List<TextPiece> texts = <TextPiece>[];
  final List<PicturePiece> pictures = <PicturePiece>[];
  final List<TilePiece> tiles = <TilePiece>[];
  final List<DragPiece> drags = <DragPiece>[];
  final List<IconPiece> icons = <IconPiece>[];

  /// The hint hand (and the pointing hand), as drawn.
  final List<Rect> hands = <Rect>[];

  /// Every widget with a string key, by key (a key that repeats keeps every rect).
  final Map<String, List<Rect>> keyed = <String, List<Rect>>{};

  bool get tablet => sizeClass == SizeClass.tablet;
  Rect? rectOf(String key) => keyed[key]?.first;
}

final RegExp _nikud = RegExp('[ְ-ׇ]');
final RegExp _hebrew = RegExp('[א-ת]');
final RegExp _digit = RegExp(r'\d');
final RegExp _letters = RegExp(r'[A-Za-zЀ-ӿא-ת]');

TextKind kindOf(String s) {
  if (_nikud.hasMatch(s)) return TextKind.nikud;
  if (_hebrew.hasMatch(s)) return TextKind.hebrew;
  if (_digit.hasMatch(s) && !_letters.hasMatch(s)) return TextKind.numeral;
  if (RegExp(r'[A-Za-zЀ-ӿ]').hasMatch(s)) return TextKind.latin;
  return TextKind.other;
}

double _scaleOf(Matrix4 m) {
  final double a = math.sqrt(m.storage[0] * m.storage[0] + m.storage[1] * m.storage[1]);
  final double b = math.sqrt(m.storage[4] * m.storage[4] + m.storage[5] * m.storage[5]);
  return math.sqrt(a * b);
}

/// Reads the screen the tester shows: the lesson on [board].
Screen readScreen(WidgetTester t, Size board, double textScale) {
  StageSpec? look;
  final Finder scope = find.byType(StageScope);
  if (scope.evaluate().isNotEmpty) look = (scope.evaluate().first.widget as StageScope).stage;
  final Screen s = Screen(board: board, look: look, sizeClass: sizeClassFor(board), textScale: textScale);
  final List<String> keys = <String>[];

  void visit(Element e) {
    final Widget w = e.widget;
    if (w is Offstage && w.offstage) return;
    if (w is Opacity && w.opacity == 0) return;
    if (w is AnimatedOpacity && w.opacity == 0) return;
    if (w is FadeTransition && w.opacity.value == 0) return;
    if (w is Visibility && !w.visible) return;
    final Key? k = w.key;
    final bool pushed = k is ValueKey<String>;
    final bool hand = w is HintHand || w is PointingHand;
    if (hand) {
      keys.add('hint-hand');
      final RenderObject? hro = e.renderObject;
      if (hro is RenderBox && hro.hasSize) s.hands.add(_rectOf(hro));
    }
    if (pushed) {
      keys.add(k.value);
      final RenderObject? ro = e.renderObject;
      if (ro is RenderBox && ro.hasSize && ro.attached) {
        s.keyed.putIfAbsent(k.value, () => <Rect>[]).add(_rectOf(ro));
      }
    }
    final RenderObject? ro = e.renderObject;
    if (w is RichText && ro is RenderParagraph && ro.hasSize) {
      final InlineSpan span = w.text;
      final TextStyle? st = span.style;
      final String plain = span.toPlainText();
      final bool isIcon = st?.fontFamily == 'MaterialIcons' || (st?.fontFamily?.contains('Icons') ?? false);
      if (plain.trim().isNotEmpty && !isIcon && st?.fontSize != null) {
        final double m = _scaleOf(ro.getTransformTo(null));
        final double base = st!.fontSize!;
        final double tscale = ro.textScaler.scale(base) / base;
        s.texts.add(
          TextPiece(
            text: plain,
            drawn: base * tscale * m,
            base: base,
            weight: (st.fontWeight ?? FontWeight.w400).value,
            height: st.height,
            rect: _rectOf(ro),
            keys: List<String>.of(keys),
            kind: kindOf(plain),
            maxLines: w.maxLines,
            family: st.fontFamily,
          ),
        );
      }
    } else if (w is SvgPicture && ro is RenderBox && ro.hasSize) {
      final String? svg = _svgOf(w);
      if (svg != null) {
        final Rect r = _rectOf(ro);
        final RenderBox box = ro;
        final double m = _scaleOf(box.getTransformTo(null));
        final RegExpMatch? vb = RegExp(r'viewBox="\s*([-\d.]+)[\s,]+([-\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)')
            .firstMatch(svg);
        double vw = 1, vh = 1;
        if (vb != null) {
          vw = double.tryParse(vb[3]!) ?? 1;
          vh = double.tryParse(vb[4]!) ?? 1;
        }
        final Rect ink = inkBoxOf(svg);
        final double bw = box.size.width, bh = box.size.height;
        // the drawing's own box inside ours: as the fit puts it
        final double sx = bw / vw, sy = bh / vh;
        final double sc = switch (w.fit) {
          BoxFit.fill => -1,
          BoxFit.cover => math.max(sx, sy),
          BoxFit.fitWidth => sx,
          BoxFit.fitHeight => sy,
          _ => math.min(sx, sy),
        };
        final double dw = sc < 0 ? bw : vw * sc, dh = sc < 0 ? bh : vh * sc;
        s.pictures.add(
          PicturePiece(
            svg: svg,
            rect: r,
            keys: List<String>.of(keys),
            inkW: ink.width * dw * m,
            inkH: ink.height * dh * m,
            strip: vb != null && (vw / vh - 2.5).abs() < 0.01,
            fit: w.fit,
          ),
        );
      }
    } else if (w is Icon && ro is RenderBox && ro.hasSize && w.icon != null) {
      final double m = _scaleOf(ro.getTransformTo(null));
      s.icons.add(
        IconPiece(
          drawn: (w.size ?? 24) * m,
          rect: _rectOf(ro),
          keys: List<String>.of(keys),
          code: w.icon!.codePoint,
        ),
      );
    } else if (w is Draggable && ro is RenderBox && ro.hasSize) {
      s.drags.add(DragPiece(rect: _rectOf(ro), keys: List<String>.of(keys)));
    } else if (w is LongPressDraggable && ro is RenderBox && ro.hasSize) {
      s.drags.add(DragPiece(rect: _rectOf(ro), keys: List<String>.of(keys)));
    }
    if (k is ValueKey<String> && k.value == 'answer-tile' && ro is RenderBox && ro.hasSize) {
      final Rect tile = _rectOf(ro);
      Rect hit = tile;
      e.visitAncestorElements((Element a) {
        if (a.widget is GestureDetector) {
          final RenderObject? r = a.renderObject;
          if (r is RenderBox && r.hasSize) hit = _rectOf(r);
          return false;
        }
        return true;
      });
      s.tiles.add(TilePiece(rect: tile, hit: hit, keys: List<String>.of(keys), width: tile.width));
    }
    e.visitChildElements(visit);
    if (pushed) keys.removeLast();
    if (hand) keys.removeLast();
  }

  t.binding.rootElement!.visitChildren(visit);
  return s;
}

Rect _rectOf(RenderBox ro) => MatrixUtils.transformRect(ro.getTransformTo(null), Offset.zero & ro.size);

String? _svgOf(SvgPicture w) {
  final Object loader = w.bytesLoader;
  if (loader is SvgStringLoader) return loader.provideSvg(null);
  return null;
}
