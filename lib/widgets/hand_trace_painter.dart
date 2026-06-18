import 'package:flutter/material.dart';

/// White outline hand guide overlaid on the camera preview.
class HandTracePainter extends CustomPainter {
  const HandTracePainter({
    required this.isLeftHand,
    this.strokeColor = Colors.white,
    this.strokeWidth = 2.5,
  });

  final bool isLeftHand;
  final Color strokeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _buildHandPath(size);

    if (isLeftHand) {
      canvas.drawPath(path, paint);
      return;
    }

    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  Path _buildHandPath(Size size) {
    final w = size.width;
    final h = size.height;

    final wristY = h * 0.94;
    final palmY = h * 0.54;
    final palmLeft = w * 0.18;
    final palmRight = w * 0.82;

    final fingers = <_Finger>[
      _Finger(cx: w * 0.30, width: w * 0.13, height: h * 0.34, tipRound: w * 0.065),
      _Finger(cx: w * 0.44, width: w * 0.13, height: h * 0.40, tipRound: w * 0.065),
      _Finger(cx: w * 0.58, width: w * 0.12, height: h * 0.36, tipRound: w * 0.06),
      _Finger(cx: w * 0.71, width: w * 0.10, height: h * 0.28, tipRound: w * 0.05),
    ];

    final path = Path();

    // Wrist center -> left palm edge.
    path.moveTo(w * 0.50, wristY);
    path.cubicTo(
      w * 0.38, wristY - h * 0.02,
      w * 0.24, h * 0.82,
      palmLeft, h * 0.72,
    );

    // Thumb loop on the left.
    path.cubicTo(
      w * 0.06, h * 0.64,
      w * 0.04, h * 0.44,
      w * 0.12, h * 0.30,
    );
    path.cubicTo(
      w * 0.18, h * 0.22,
      w * 0.24, h * 0.24,
      w * 0.26, h * 0.32,
    );
    path.cubicTo(
      w * 0.28, h * 0.38,
      w * 0.27, h * 0.44,
      w * 0.25, palmY,
    );

    // Index finger (outer edge up and over tip).
    _traceFinger(path, fingers[0], palmY);

    // Middle finger.
    _traceFinger(path, fingers[1], palmY);

    // Ring finger.
    _traceFinger(path, fingers[2], palmY);

    // Pinky finger.
    _traceFinger(path, fingers[3], palmY);

    // Right palm edge back to wrist.
    path.cubicTo(
      palmRight, h * 0.72,
      w * 0.76, h * 0.82,
      w * 0.62, wristY,
    );
    path.cubicTo(
      w * 0.56, wristY + h * 0.01,
      w * 0.53, wristY,
      w * 0.50, wristY,
    );

    return path;
  }

  void _traceFinger(Path path, _Finger finger, double palmY) {
    final left = finger.cx - finger.width / 2;
    final right = finger.cx + finger.width / 2;
    final top = palmY - finger.height;
    final tipY = top + finger.tipRound;

    path.cubicTo(
      left - finger.width * 0.05, palmY - finger.height * 0.15,
      left, tipY + finger.height * 0.18,
      left, tipY,
    );
    path.arcToPoint(
      Offset(right, tipY),
      radius: Radius.circular(finger.tipRound),
      clockwise: false,
    );
    path.cubicTo(
      right, tipY + finger.height * 0.18,
      right + finger.width * 0.05, palmY - finger.height * 0.12,
      right, palmY,
    );
  }

  @override
  bool shouldRepaint(covariant HandTracePainter oldDelegate) {
    return oldDelegate.isLeftHand != isLeftHand ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _Finger {
  const _Finger({
    required this.cx,
    required this.width,
    required this.height,
    required this.tipRound,
  });

  final double cx;
  final double width;
  final double height;
  final double tipRound;
}
