import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../constants/try_on_strings.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../models/captured_nail_session.dart';
import '../../models/nail_bed_geometry.dart';
import '../../core/camera/nail_warp_painter.dart';
import '../../models/nail_finger.dart';
import '../../models/nail_look.dart';
import '../../services/capture_hand_analysis_service.dart';
import '../../services/nail_look_image_cache.dart';

/// YouCam-style: snap photo → nails placed on your fingers → drag to fine-tune.
class CaptureFineTuneScreen extends StatefulWidget {
  const CaptureFineTuneScreen({
    super.key,
    required this.photoBytes,
    required this.look,
    this.brownHand = false,
  });

  final List<int> photoBytes;
  final NailLook look;
  final bool brownHand;

  @override
  State<CaptureFineTuneScreen> createState() => _CaptureFineTuneScreenState();
}

class _CaptureFineTuneScreenState extends State<CaptureFineTuneScreen> {
  final _analysis = CaptureHandAnalysisService();

  bool _loading = true;
  bool _analyzeStarted = false;
  String? _error;
  CapturedNailSession? _session;
  Map<NailFinger, ui.Image> _fingerNails = {};
  NailFinger _selectedFinger = NailFinger.indexFinger;
  Offset? _dragStart;
  NailBedGeometry? _dragStartGeometry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _analysis.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final nails = await NailLookImageCache.instance.loadFingerNails(
      widget.look,
      brownHand: widget.brownHand,
    );

    if (!mounted) {
      return;
    }

    setState(() => _fingerNails = nails);
  }

  Future<void> _analyze(Size viewSize) async {
    final session = await _analysis.analyze(
      photoBytes: Uint8List.fromList(widget.photoBytes),
      viewSize: viewSize,
      look: widget.look,
    );

    if (!mounted) {
      return;
    }

    if (session == null) {
      setState(() {
        _loading = false;
        _error = TryOnStrings.handNotFoundOnPhoto;
      });
      return;
    }

    final firstFinger = session.placements.keys.contains(_selectedFinger)
        ? _selectedFinger
        : session.placements.keys.first;

    setState(() {
      _session = session;
      _selectedFinger = firstFinger;
      _loading = false;
      _error = null;
    });
  }

  void _updateFingerGeometry(NailFinger finger, NailBedGeometry geometry) {
    final session = _session;
    if (session == null) {
      return;
    }
    setState(() {
      _session = session.copyWith(
        placements: {...session.placements, finger: geometry},
      );
    });
  }

  void _nudgeScale(double delta) {
    final session = _session;
    final current = session?.placements[_selectedFinger];
    if (session == null || current == null) {
      return;
    }
    AppHaptics.light();
    final factor = (1 + delta).clamp(0.7, 1.35);
    _updateFingerGeometry(
      _selectedFinger,
      NailBedGeometry(
        center: current.center,
        width: (current.width * factor).clamp(8.0, 160.0),
        height: (current.height * factor).clamp(8.0, 180.0),
        angle: current.angle,
      ),
    );
  }

  void _rotateSelected(double delta) {
    final current = _session?.placements[_selectedFinger];
    if (current == null) {
      return;
    }
    AppHaptics.light();
    _updateFingerGeometry(
      _selectedFinger,
      NailBedGeometry(
        center: current.center,
        width: current.width,
        height: current.height,
        angle: current.angle + delta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody()),
            if (_session != null) _buildFingerPicker(),
            if (_session != null) _buildAdjustTools(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              TryOnStrings.retakePhoto,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
          const Spacer(),
          if (_session != null)
            FilledButton(
              onPressed: () {
                AppHaptics.heavy();
                Navigator.of(context).pop(_session);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(TryOnStrings.done),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_fingerNails.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_loading && !_analyzeStarted && _error == null) {
          _analyzeStarted = true;
          _analyze(viewSize);
        }

        if (_loading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryLight),
                SizedBox(height: 16),
                Text(
                  'Finding your nails…',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.back_hand_outlined, size: 48, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(TryOnStrings.retakePhoto),
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onPanStart: (details) {
            final geom = _session?.placements[_selectedFinger];
            if (geom == null) {
              return;
            }
            _dragStart = details.localPosition;
            _dragStartGeometry = geom;
          },
          onPanUpdate: (details) {
            final start = _dragStart;
            final startGeom = _dragStartGeometry;
            if (start == null || startGeom == null) {
              return;
            }
            final delta = details.localPosition - start;
            _updateFingerGeometry(
              _selectedFinger,
              NailBedGeometry(
                center: startGeom.center + delta,
                width: startGeom.width,
                height: startGeom.height,
                angle: startGeom.angle,
              ),
            );
          },
          onPanEnd: (_) {
            _dragStart = null;
            _dragStartGeometry = null;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                Uint8List.fromList(widget.photoBytes),
                fit: BoxFit.cover,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
              CustomPaint(
                painter: _CapturedNailPainter(
                  placements: _session!.placements,
                  fingerNails: _fingerNails,
                  selectedFinger: _selectedFinger,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  TryOnStrings.fineTuneHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFingerPicker() {
    final session = _session!;
    final fingers = NailFingerPlacement.all
        .map((p) => p.finger)
        .where(session.placements.containsKey)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final finger in fingers)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_fingerLabel(finger)),
                selected: _selectedFinger == finger,
                onSelected: (_) {
                  AppHaptics.light();
                  setState(() => _selectedFinger = finger);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _selectedFinger == finger ? Colors.white : Colors.white70,
                ),
                backgroundColor: Colors.white12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdjustTools() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolButton(
            icon: Icons.remove,
            label: 'Smaller',
            onTap: () => _nudgeScale(-0.06),
          ),
          _ToolButton(
            icon: Icons.add,
            label: 'Bigger',
            onTap: () => _nudgeScale(0.06),
          ),
          _ToolButton(
            icon: Icons.rotate_left,
            label: 'Rotate',
            onTap: () => _rotateSelected(-0.08),
          ),
          _ToolButton(
            icon: Icons.rotate_right,
            label: 'Rotate',
            onTap: () => _rotateSelected(0.08),
          ),
        ],
      ),
    );
  }

  String _fingerLabel(NailFinger finger) {
    return switch (finger) {
      NailFinger.thumb => 'Thumb',
      NailFinger.indexFinger => 'Index',
      NailFinger.middle => 'Middle',
      NailFinger.ring => 'Ring',
      NailFinger.pinky => 'Pinky',
    };
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _CapturedNailPainter extends CustomPainter {
  _CapturedNailPainter({
    required this.placements,
    required this.fingerNails,
    required this.selectedFinger,
  });

  final Map<NailFinger, NailBedGeometry> placements;
  final Map<NailFinger, ui.Image> fingerNails;
  final NailFinger selectedFinger;

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in placements.entries) {
      final nailImage = fingerNails[entry.key];
      if (nailImage == null) {
        continue;
      }

      final geometry = entry.value;
      final isSelected = entry.key == selectedFinger;

      if (isSelected) {
        final highlight = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        final bounds = geometry.quad ?? _rectCorners(geometry);
        final path = Path()..addPolygon(bounds, true);
        canvas.drawPath(path, highlight);
      }

      paintNail(canvas, nailImage, geometry);
    }
  }

  List<Offset> _rectCorners(NailBedGeometry geometry) {
    final halfW = geometry.width / 2;
    final halfH = geometry.height / 2;
    final c = geometry.center;
    final cos = math.cos(geometry.angle);
    final sin = math.sin(geometry.angle);
    Offset rot(double x, double y) => Offset(
          c.dx + x * cos - y * sin,
          c.dy + x * sin + y * cos,
        );
    return [
      rot(-halfW, -halfH),
      rot(halfW, -halfH),
      rot(halfW, halfH),
      rot(-halfW, halfH),
    ];
  }

  @override
  bool shouldRepaint(covariant _CapturedNailPainter oldDelegate) {
    return oldDelegate.placements != placements ||
        oldDelegate.fingerNails != fingerNails ||
        oldDelegate.selectedFinger != selectedFinger;
  }
}
