// Draws the MASARAT app icon with Flutter's own canvas and writes the PNGs in assets/icon/.
//   flutter test tool/icon_gen_test.dart && dart run flutter_launcher_icons && dart run flutter_native_splash:create
//
// The idea: «مسارات» = paths. Three roads rise from the bottom and meet at a gold goal; the middle road is
// gold, the student's own path. Navy and cream are the login page colours.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const navy = Color(0xFF0B1F3A);
const navy2 = Color(0xFF143766);
const blue = Color(0xFF1D4E89);
const cream = Color(0xFFF7F4EF);
const gold = Color(0xFFE3A72F);
const goldLight = Color(0xFFF5C95C);

const goal = Offset(512, 300);

Offset _bez(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final u = 1 - t;
  return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t);
}

/// A road: a filled ribbon along a cubic curve, wide at the bottom and narrow at the goal (perspective).
Path _road(Offset p0, Offset p1, Offset p2, Offset p3, double w0, double w1) {
  const n = 64;
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    final p = _bez(p0, p1, p2, p3, t);
    final q = _bez(p0, p1, p2, p3, math.min(1, t + 1e-3)) - _bez(p0, p1, p2, p3, math.max(0, t - 1e-3));
    final len = q.distance == 0 ? 1 : q.distance;
    final normal = Offset(-q.dy / len, q.dx / len);
    final w = (w0 + (w1 - w0) * math.pow(t, 0.85)) / 2;
    left.add(p + normal * w);
    right.add(p - normal * w);
  }
  final path = Path()..moveTo(left.first.dx, left.first.dy);
  for (final o in left.skip(1)) {
    path.lineTo(o.dx, o.dy);
  }
  for (final o in right.reversed) {
    path.lineTo(o.dx, o.dy);
  }
  return path..close();
}

void _mark(Canvas c, {bool admin = false}) {
  final road = admin ? navy : cream;
  // Glow and halo of the goal behind the roads.
  c.drawCircle(goal, 150, Paint()..shader = ui.Gradient.radial(goal, 150, [gold.withValues(alpha: 0.35), gold.withValues(alpha: 0)]));
  c.drawCircle(goal, 92, Paint()..color = road.withValues(alpha: admin ? 0.35 : 0.55)..style = PaintingStyle.stroke..strokeWidth = 10);
  // Side roads (cream), then the middle road (gold) on top.
  final side = Paint()..color = road..isAntiAlias = true;
  c.drawPath(_road(const Offset(120, 1060), const Offset(170, 700), const Offset(470, 560), goal, 120, 14), side);
  c.drawPath(_road(const Offset(904, 1060), const Offset(854, 700), const Offset(554, 560), goal, 120, 14), side);
  final mid = Paint()
    ..shader = ui.Gradient.linear(const Offset(512, 904), goal, [gold, goldLight]);
  c.drawPath(_road(const Offset(512, 1060), const Offset(512, 760), const Offset(512, 520), goal, 170, 16), mid);
  // The goal: a gold sun where the roads meet.
  c.drawCircle(goal, 62, Paint()..shader = ui.Gradient.radial(goal - const Offset(16, 16), 80, [goldLight, gold]));
}

void _background(Canvas c, {double radius = 0, bool admin = false}) {
  final rect = const Rect.fromLTWH(0, 0, 1024, 1024);
  final colors = admin ? const [Color(0xFFFFFDF8), cream, Color(0xFFE6DCC8)] : const [blue, navy2, navy];
  final bg = Paint()..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(1024, 1024), colors, [0, 0.45, 1]);
  c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), bg);
}

Future<void> _write(String name, int size, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.scale(size / 1024);
  draw(c);
  final img = await rec.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File('assets/icon/$name').writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('generate icons', (tester) async {
    await tester.runAsync(() async {
      for (final admin in [false, true]) {
        final dir = admin ? 'admin/' : '';
        Directory('assets/icon/$dir').createSync(recursive: true);
        // iOS / store: full-bleed square (the systems round the corners).
        await _write('${dir}icon.png', 1024, (c) {
          _background(c, admin: admin);
          c.clipRect(const Rect.fromLTWH(0, 0, 1024, 1024));
          _mark(c, admin: admin);
        });
        // Android adaptive icon: background and foreground layers. The mark is large enough that the launcher
        // mask (inner ~66%) cuts the roads at its edge, like the iOS icon.
        await _write('${dir}icon_background.png', 1024, (c) => _background(c, admin: admin));
        await _write('${dir}icon_foreground.png', 1024, (c) {
          c.translate(512, 512);
          c.scale(0.8);
          c.translate(-512, -470);
          _mark(c, admin: admin);
        });
        // In-app splash and preview: rounded square.
        await _write('${dir}splash.png', 512, (c) {
          _background(c, radius: 228, admin: admin);
          c.clipRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 1024, 1024), const Radius.circular(228)));
          _mark(c, admin: admin);
        });
      }
    });
  });
}
