import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/camera/hand_image_normalizer.dart';
import '../../core/camera/image_layout_mapper.dart';
import '../../core/camera/nail_shape_catalog.dart';
import '../../core/camera/nail_shape_fitter.dart';
import '../../core/camera/nail_polygon_painter.dart';
import '../../core/config/nail_detect_config.dart';
import '../../core/config/roboflow_config.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../models/detected_nail.dart';
import '../../models/nail_beauty_shape.dart';
import '../../services/http_nail_detection_service.dart';
import '../../services/nail_detection_exception.dart';
import '../../services/nail_finger_matcher_service.dart';
import '../../services/roboflow_nail_detection_service.dart';
import '../../widgets/camera_bottom_panel.dart';
import '../../widgets/nail_shape_picker.dart';

/// Upload or snap a hand photo → detect nail polygons → tap to paint color.
class HandUploadTryOnScreen extends StatefulWidget {
  const HandUploadTryOnScreen({super.key});

  @override
  State<HandUploadTryOnScreen> createState() => _HandUploadTryOnScreenState();
}

class _HandUploadTryOnScreenState extends State<HandUploadTryOnScreen> {
  final _picker = ImagePicker();
  final _fingerMatcher = NailFingerMatcherService();
  static const _httpDetector = HttpNailDetectionService();
  static const _roboflowDetector = RoboflowNailDetectionService();

  bool get _detectionReady =>
      NailDetectConfig.isConfigured || RoboflowConfig.isConfigured;

  Uint8List? _imageBytes;
  ui.Image? _decodedImage;
  List<DetectedNail> _nails = const [];
  final Set<String> _selectedIds = {};
  final Map<String, Color> _nailColors = {};
  Color _activeColor = plainNailColors.first;
  NailBeautyShape _activeShape = NailBeautyShape.natural;

  bool _detecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    NailShapeCatalog.instance.warmUp();
    _fingerMatcher.ensureInitialized();
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    _fingerMatcher.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 1920,
      );
      if (file == null || !mounted) {
        return;
      }
      final bytes = normalizeHandPhotoBytes(await file.readAsBytes());
      await _loadAndDetect(bytes);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Could not load photo.');
    }
  }

  Future<void> _loadAndDetect(Uint8List bytes) async {
    _decodedImage?.dispose();

    setState(() {
      _imageBytes = bytes;
      _decodedImage = null;
      _nails = const [];
      _detecting = true;
      _error = null;
      _selectedIds.clear();
      _nailColors.clear();
    });

    ui.Image? decoded;
    try {
      decoded = await _decodeImage(bytes);
      if (mounted) {
        setState(() => _decodedImage = decoded);
      }

      if (!NailDetectConfig.isConfigured && !RoboflowConfig.isConfigured) {
        throw NailDetectionException(
          'NAIL_DETECT_URL not loaded. Stop the app completely, then run flutter run again.',
        );
      }

      final nails = await _detectNails(bytes);
      if (!mounted) {
        return;
      }

      final labeled = await _fingerMatcher.labelNails(
        photoBytes: bytes,
        nails: nails,
      );
      if (!mounted) {
        return;
      }

      final shaped = await applyShapeToNails(labeled, _activeShape);
      if (!mounted) {
        return;
      }

      setState(() {
        _nails = shaped;
        _detecting = false;
        _selectedIds
          ..clear()
          ..addAll(shaped.map((n) => n.id));
      });
    } on NailDetectionException catch (e) {
      decoded?.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _detecting = false;
        _error = e.message;
        _decodedImage = null;
        _nails = const [];
      });
    } catch (e, stack) {
      decoded?.dispose();
      if (kDebugMode) {
        debugPrint('Nail detection error: $e\n$stack');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _detecting = false;
        _error = e is NailDetectionException
            ? e.message
            : 'Nail detection failed. Try again.';
        _decodedImage = null;
        _nails = const [];
      });
    }
  }

  Future<List<DetectedNail>> _detectNails(Uint8List bytes) {
    if (NailDetectConfig.isConfigured) {
      return _httpDetector.detectNails(imageBytes: bytes);
    }
    return _roboflowDetector.detectNails(imageBytes: bytes);
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _toggleSelection(String id) {
    AppHaptics.heavy();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _applyColorToSelection(Color color) {
    final targets = _selectedIds.isEmpty
        ? _nails.map((n) => n.id).toSet()
        : _selectedIds;
    if (targets.isEmpty) {
      return;
    }
    AppHaptics.heavy();
    setState(() {
      _activeColor = color;
      for (final id in targets) {
        _nailColors[id] = color;
      }
    });
  }

  Future<void> _applyShape(NailBeautyShape shape) async {
    if (_nails.isEmpty) {
      setState(() => _activeShape = shape);
      return;
    }
    setState(() => _activeShape = shape);
    final shaped = await applyShapeToNails(_nails, shape);
    if (!mounted) {
      return;
    }
    setState(() => _nails = shaped);
  }

  void _clearSelectedColors() {
    if (_selectedIds.isEmpty) {
      return;
    }
    setState(() {
      for (final id in _selectedIds) {
        _nailColors.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Try nail color'),
        actions: [
          if (_imageBytes != null)
            IconButton(
              onPressed: _detecting
                  ? null
                  : () => _showPickSheet(context),
              icon: const Icon(Icons.refresh),
              tooltip: 'New photo',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _imageBytes == null
                ? _PickSourcePane(
                    onSnap: () => _pickImage(ImageSource.camera),
                    onUpload: () => _pickImage(ImageSource.gallery),
                    detectionReady: _detectionReady,
                  )
                : _HandPhotoEditor(
                    image: _decodedImage,
                    imageBytes: _imageBytes!,
                    nails: _nails,
                    selectedIds: _selectedIds,
                    nailColors: _nailColors,
                    detecting: _detecting,
                    error: _error,
                    onTapNail: _toggleSelection,
                  ),
          ),
          if (_nails.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _selectedIds.isEmpty
                    ? 'Tap a nail to select, or pick a color for all nails'
                    : _selectedIds.length == _nails.length
                        ? 'All nails selected — pick a color'
                        : '${_selectedIds.length} nail(s) selected',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            NailShapePicker(
              selectedShape: _activeShape,
              onShapeSelected: _applyShape,
            ),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: plainNailColors.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ColorDot(
                      color: Colors.transparent,
                      isClear: true,
                      selected: false,
                      onTap: _clearSelectedColors,
                    );
                  }
                  final color = plainNailColors[index - 1];
                  return _ColorDot(
                    color: color,
                    selected: color == _activeColor,
                    onTap: () => _applyColorToSelection(color),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: bottomInset + 8),
        ],
      ),
    );
  }

  Future<void> _showPickSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Snap hand'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PickSourcePane extends StatelessWidget {
  const _PickSourcePane({
    required this.onSnap,
    required this.onUpload,
    required this.detectionReady,
  });

  final VoidCallback onSnap;
  final VoidCallback onUpload;
  final bool detectionReady;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.back_hand_outlined,
              size: 72,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              'Snap or upload your hand.\nWe detect each nail automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            if (!detectionReady) ...[
              const SizedBox(height: 16),
              Text(
                'Add NAIL_DETECT_URL to .env, then stop the app\nand run flutter run again (hot reload is not enough).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange.shade200,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: onSnap,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Snap hand'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_outlined, color: Colors.white),
                label: const Text('Upload photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HandPhotoEditor extends StatelessWidget {
  const _HandPhotoEditor({
    required this.image,
    required this.imageBytes,
    required this.nails,
    required this.selectedIds,
    required this.nailColors,
    required this.detecting,
    required this.error,
    required this.onTapNail,
  });

  final ui.Image? image;
  final Uint8List imageBytes;
  final List<DetectedNail> nails;
  final Set<String> selectedIds;
  final Map<String, Color> nailColors;
  final bool detecting;
  final String? error;
  final ValueChanged<String> onTapNail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              CustomPaint(
                painter: _HandNailOverlayPainter(
                  image: image!,
                  viewSize: constraints.biggest,
                  nails: nails,
                  selectedIds: selectedIds,
                  nailColors: nailColors,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    if (nails.isEmpty) {
                      return;
                    }
                    final mapper = ImageLayoutMapper(
                      imageSize: Size(
                        image!.width.toDouble(),
                        image!.height.toDouble(),
                      ),
                      viewSize: constraints.biggest,
                    );
                    final screenPolys = nails
                        .map((n) => mapper.mapPolygon(n.polygon))
                        .toList();
                    final index = hitTestNailIndex(
                      details.localPosition,
                      screenPolys,
                    );
                    if (index != null) {
                      onTapNail(nails[index].id);
                    }
                  },
                ),
              )
            else
              Center(
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
            if (detecting)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 14),
                      Text(
                        'Detecting nails…',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            if (error != null && !detecting)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HandNailOverlayPainter extends CustomPainter {
  _HandNailOverlayPainter({
    required this.image,
    required this.viewSize,
    required this.nails,
    required this.selectedIds,
    required this.nailColors,
  });

  final ui.Image image;
  final Size viewSize;
  final List<DetectedNail> nails;
  final Set<String> selectedIds;
  final Map<String, Color> nailColors;

  @override
  void paint(Canvas canvas, Size size) {
    final mapper = ImageLayoutMapper(
      imageSize: Size(image.width.toDouble(), image.height.toDouble()),
      viewSize: viewSize,
    );
    final dst = mapper.displayedRect;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );

    for (final nail in nails) {
      final screenPoly = mapper.mapPolygon(nail.polygon);
      final selected = selectedIds.contains(nail.id);
      final color = nailColors[nail.id];

      if (color != null) {
        paintDetectedNailShader(
          canvas,
          screenPoly,
          color: color,
          selected: selected,
        );
      } else {
        paintDetectedNailOutline(
          canvas,
          nail.copyWith(polygon: screenPoly),
          selected: selected,
          hasColor: false,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HandNailOverlayPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.viewSize != viewSize ||
        oldDelegate.nails != nails ||
        oldDelegate.selectedIds != selectedIds ||
        oldDelegate.nailColors != nailColors;
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.onTap,
    this.isClear = false,
    this.selected = false,
  });

  final Color color;
  final VoidCallback onTap;
  final bool isClear;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isClear ? Colors.white24 : color,
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: isClear
            ? Icon(Icons.close, size: 18, color: Colors.white.withValues(alpha: 0.8))
            : null,
      ),
    );
  }
}
