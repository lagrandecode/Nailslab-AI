import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_detection/hand_detection.dart';

import '../../constants/try_on_strings.dart';
import '../../core/camera/hand_guide_layout.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../models/nail_finger.dart';
import '../../models/nail_look.dart';
import '../../models/plain_nail_paint.dart';
import '../../services/hand_tracking_service.dart';
import '../../services/language_service.dart';
import '../../services/nail_look_image_cache.dart';
import '../../services/nail_look_repository.dart';
import '../../widgets/camera_bottom_panel.dart';
import '../../widgets/hand_trace_overlay.dart';
import '../../widgets/live_nail_overlay.dart';
import '../../widgets/plain_hand_look_view.dart';

enum LookViewMode { plain, camera }

class HandCameraScreen extends StatefulWidget {
  const HandCameraScreen({super.key});

  @override
  State<HandCameraScreen> createState() => _HandCameraScreenState();
}

class _HandCameraScreenState extends State<HandCameraScreen> {
  final _lookRepository = NailLookRepository.instance;
  final _handTracking = HandTrackingService();

  CameraController? _controller;
  bool _ready = false;
  bool _looksLoaded = false;
  bool _showGuide = true;
  bool _isLeftHand = true;
  bool _brownHand = false;
  bool _capturing = false;
  bool _processingFrame = false;
  bool _imageStreamActive = false;
  bool _cameraInitStarted = false;
  String? _errorMessage;
  CameraPanelTab _activeTab = CameraPanelTab.looks;
  LookViewMode _viewMode = LookViewMode.plain;
  NailLook? _selectedLook;
  TrackedHandFrame? _trackedHand;
  Size _previewLayoutSize = Size.zero;
  PlainNailPaintState _plainPaint = const PlainNailPaintState();
  Map<NailFinger, ui.Image> _fingerNailImages = {};

  bool get _isPlain => _viewMode == LookViewMode.plain;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _lookRepository.ensureLoaded();
    if (mounted) {
      setState(() => _looksLoaded = true);
    }
  }

  Future<void> _ensureCameraReady() async {
    if (_ready || _cameraInitStarted) {
      return;
    }
    _cameraInitStarted = true;
    await _handTracking.ensureInitialized();
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = TryOnStrings.cameraUnavailable);
        return;
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _ready = true;
      });

      if (_selectedLook != null && !_isPlain) {
        await _startTrackingStream();
      }
    } on CameraException catch (e) {
      setState(() => _errorMessage = e.description ?? TryOnStrings.cameraUnavailable);
    } catch (_) {
      setState(() => _errorMessage = TryOnStrings.cameraUnavailable);
    }
  }

  Future<void> _toggleViewMode() async {
    AppHaptics.heavy();
    if (_isPlain) {
      setState(() => _viewMode = LookViewMode.camera);
      await _ensureCameraReady();
      if (_selectedLook != null) {
        await _startTrackingStream();
      }
    } else {
      await _stopTrackingStream();
      if (mounted) {
        setState(() {
          _viewMode = LookViewMode.plain;
          _trackedHand = null;
        });
      }
    }
  }

  Future<void> _startTrackingStream() async {
    if (_isPlain) {
      return;
    }
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _imageStreamActive ||
        _selectedLook == null) {
      return;
    }

    try {
      await controller.startImageStream(_onCameraFrame);
      _imageStreamActive = true;
    } catch (_) {
      _imageStreamActive = false;
    }
  }

  Future<void> _stopTrackingStream() async {
    final controller = _controller;
    if (controller == null || !_imageStreamActive) {
      return;
    }

    try {
      await controller.stopImageStream();
    } catch (_) {
      // Stream may already be stopped.
    } finally {
      _imageStreamActive = false;
      if (mounted) {
        setState(() => _trackedHand = null);
      }
    }
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_processingFrame || _selectedLook == null || _previewLayoutSize == Size.zero) {
      return;
    }

    final controller = _controller;
    if (controller == null) {
      return;
    }

    _processingFrame = true;
    try {
      final frame = await _handTracking.detect(
        image: image,
        controller: controller,
        screenSize: _previewLayoutSize,
      );

      if (!mounted) {
        return;
      }

      if (frame == null) {
        if (_trackedHand != null) {
          setState(() => _trackedHand = null);
        }
        return;
      }

      setState(() {
        _trackedHand = frame;
        if (frame.handedness != null) {
          _isLeftHand = frame.handedness == Handedness.left;
        }
      });
    } finally {
      _processingFrame = false;
    }
  }

  @override
  void dispose() {
    _stopTrackingStream();
    _handTracking.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    AppHaptics.heavy();

    final wasStreaming = _imageStreamActive;
    if (wasStreaming) {
      await _stopTrackingStream();
    }

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(Uint8List.fromList(bytes));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _errorMessage = TryOnStrings.cameraCaptureFailed;
      });
      if (wasStreaming && _selectedLook != null) {
        await _startTrackingStream();
      }
    }
  }

  void _onTabChanged(CameraPanelTab tab) {
    setState(() => _activeTab = tab);

    if (!_isPlain && tab != CameraPanelTab.looks) {
      _stopTrackingStream();
    } else if (!_isPlain && tab == CameraPanelTab.looks && _selectedLook != null) {
      _startTrackingStream();
    }
  }

  Future<void> _reloadPlainNailImages() async {
    final images = <NailFinger, ui.Image>{};
    for (final finger in NailFinger.values) {
      final look = _plainPaint.paintFor(finger).look;
      if (look == null) {
        continue;
      }
      final nails = await NailLookImageCache.instance.loadFingerNails(
        look,
        brownHand: _brownHand,
      );
      final image = nails[finger];
      if (image != null) {
        images[finger] = image;
      }
    }
    if (mounted) {
      setState(() => _fingerNailImages = images);
    }
  }

  void _onPlainFingerTap(NailFinger finger) {
    AppHaptics.heavy();
    setState(() {
      _plainPaint = _plainPaint.copyWith(selectedFinger: finger);
      _activeTab = CameraPanelTab.color;
    });
  }

  void _onNailColorSelected(Color color) {
    setState(() {
      _plainPaint = _plainPaint.applyTint(
        color,
        finger: _plainPaint.selectedFinger,
      );
    });
  }

  void _onClearNailColor() {
    setState(() {
      _plainPaint = _plainPaint.applyTint(
        null,
        finger: _plainPaint.selectedFinger,
      );
    });
  }

  String? _plainSelectedFingerLabel() {
    return switch (_plainPaint.selectedFinger) {
      NailFinger.thumb => 'Painting thumb nail',
      NailFinger.indexFinger => 'Painting index nail',
      NailFinger.middle => 'Painting middle nail',
      NailFinger.ring => 'Painting ring nail',
      NailFinger.pinky => 'Painting pinky nail',
      null => 'Tap a finger to paint one nail',
    };
  }

  void _onLookSelected(NailLook look) {
    AppHaptics.heavy();
    setState(() {
      _activeTab = CameraPanelTab.looks;
      _selectedLook = look;
      _trackedHand = null;
      if (_isPlain) {
        final finger = _plainPaint.selectedFinger;
        _plainPaint = finger != null
            ? _plainPaint.applyLookToFinger(look, finger)
            : _plainPaint.applyLookToAll(look);
      }
    });
    if (_isPlain) {
      _reloadPlainNailImages();
    } else {
      NailLookImageCache.instance.loadFingerNails(look, brownHand: _brownHand);
      _startTrackingStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayStyle = _isPlain
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _isPlain ? Colors.white : Colors.black,
        body: _errorMessage != null ? _ErrorView(message: _errorMessage!) : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final guideHeight = screenHeight * HandGuideLayout.heightScreenFactor;
    final trackingActive =
        _isPlain ? _plainPaint.hasAnyLook : _selectedLook != null && _activeTab == CameraPanelTab.looks;
    final handDetected = _trackedHand != null;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _previewLayoutSize = Size(constraints.maxWidth, constraints.maxHeight);

              if (_isPlain) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    PlainHandLookView(
                      brownHand: _brownHand,
                      paintState: _plainPaint,
                      fingerNailImages: _fingerNailImages,
                      lookSheetAsset:
                          _plainPaint.hasAnyLook ? _selectedLook?.overlayAsset : null,
                      onFingerTap: _onPlainFingerTap,
                    ),
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          _TopBar(
                            plainMode: true,
                            showGuide: _showGuide,
                            isPlainView: true,
                            onClose: () => Navigator.of(context).pop(),
                            onToggleViewMode: _toggleViewMode,
                            onToggleGuide: () => setState(() => _showGuide = !_showGuide),
                          ),
                          const SizedBox(height: 12),
                          _HintBanner(
                            plainMode: true,
                            trackingActive: trackingActive,
                            handDetected: handDetected,
                            lookSelected: _isPlain ? _plainPaint.hasAnyLook : _selectedLook != null,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Row(
                        children: [
                          const Spacer(),
                          _SkinToneToggle(
                            brownHand: _brownHand,
                            onTap: () {
                              setState(() => _brownHand = !_brownHand);
                              _reloadPlainNailImages();
                            },
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final controller = _controller;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (_ready && controller != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.previewSize?.height ?? 1,
                        height: controller.value.previewSize?.width ?? 1,
                        child: CameraPreview(controller),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        _TopBar(
                          plainMode: false,
                          showGuide: _showGuide,
                          isPlainView: false,
                          onClose: () => Navigator.of(context).pop(),
                          onToggleViewMode: _toggleViewMode,
                          onToggleGuide: () => setState(() => _showGuide = !_showGuide),
                        ),
                        const SizedBox(height: 12),
                        _HintBanner(
                          plainMode: false,
                          trackingActive: trackingActive,
                          handDetected: handDetected,
                          lookSelected: _selectedLook != null,
                        ),
                      ],
                    ),
                  ),
                  if (trackingActive && handDetected)
                    LiveNailOverlay(
                      look: _selectedLook!,
                      hand: _trackedHand!,
                      brownHand: _brownHand,
                    ),
                  if (_showGuide && !handDetected)
                    Center(
                      child: HandTraceOverlay(
                        isLeftHand: _isLeftHand,
                        height: guideHeight,
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Row(
                      children: [
                        const SizedBox(width: 72),
                        Expanded(
                          child: Center(
                            child: _ShutterButton(
                              enabled: _ready && !_capturing,
                              onPressed: _capture,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: _HandToggle(
                            isLeftHand: _isLeftHand,
                            onTap: () => setState(() => _isLeftHand = !_isLeftHand),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_looksLoaded)
          CameraBottomPanel(
            activeTab: _activeTab,
            looks: _lookRepository.all,
            selectedLookId: _selectedLook?.id,
            onTabChanged: _onTabChanged,
            onLookSelected: _onLookSelected,
            plainMode: _isPlain,
            selectedFingerLabel: _isPlain ? _plainSelectedFingerLabel() : null,
            onColorSelected: _isPlain ? _onNailColorSelected : null,
            onClearColor: _isPlain ? _onClearNailColor : null,
          )
        else
          const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
        SizedBox(height: bottomInset),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.plainMode,
    required this.showGuide,
    required this.isPlainView,
    required this.onClose,
    required this.onToggleViewMode,
    required this.onToggleGuide,
  });

  final bool plainMode;
  final bool showGuide;
  final bool isPlainView;
  final VoidCallback onClose;
  final VoidCallback onToggleViewMode;
  final VoidCallback onToggleGuide;

  Color get _iconColor =>
      plainMode ? AppColors.title.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85);

  Color get _activeColor => plainMode ? AppColors.primary : AppColors.primaryLight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: _iconColor, size: 28),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onToggleViewMode,
            child: Column(
              children: [
                Icon(Icons.panorama_outlined, color: _iconColor, size: 24),
                const SizedBox(height: 2),
                ListenableBuilder(
                  listenable: LanguageService.instance,
                  builder: (context, _) => Text(
                    isPlainView ? TryOnStrings.tapToCamera : TryOnStrings.tapToPlain,
                    style: TextStyle(color: _iconColor, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!plainMode)
            GestureDetector(
              onTap: onToggleGuide,
              child: Column(
                children: [
                  Icon(
                    Icons.back_hand_outlined,
                    color: showGuide ? _activeColor : _iconColor,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  ListenableBuilder(
                    listenable: LanguageService.instance,
                    builder: (context, _) => Text(
                      showGuide ? TryOnStrings.guideOn : TryOnStrings.guideOff,
                      style: TextStyle(
                        color: showGuide ? _activeColor : _iconColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({
    required this.plainMode,
    required this.trackingActive,
    required this.handDetected,
    required this.lookSelected,
  });

  final bool plainMode;
  final bool trackingActive;
  final bool handDetected;
  final bool lookSelected;

  @override
  Widget build(BuildContext context) {
    if (plainMode && !lookSelected) {
      return const SizedBox.shrink();
    }

    final String text;
    if (plainMode) {
      text = TryOnStrings.plainLookAppliedHint;
    } else if (trackingActive && handDetected) {
      text = TryOnStrings.holdHandHint;
    } else if (trackingActive) {
      text = TryOnStrings.detectingHandHint;
    } else {
      text = TryOnStrings.whiteBackgroundHint;
    }

    final bannerColor = plainMode
        ? AppColors.title.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.45);
    final textColor = plainMode
        ? AppColors.title.withValues(alpha: 0.72)
        : (handDetected ? Colors.greenAccent.shade100 : AppColors.primaryLight);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) => Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 5),
        ),
        child: Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _HandToggle extends StatelessWidget {
  const _HandToggle({
    required this.isLeftHand,
    required this.onTap,
  });

  final bool isLeftHand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(isLeftHand ? 1.0 : -1.0, 1.0, 1.0),
            child: const Icon(Icons.back_hand_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          ListenableBuilder(
            listenable: LanguageService.instance,
            builder: (context, _) => Text(
              isLeftHand ? TryOnStrings.leftHand : TryOnStrings.rightHand,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinToneToggle extends StatelessWidget {
  const _SkinToneToggle({
    required this.brownHand,
    required this.onTap,
  });

  final bool brownHand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brownHand ? const Color(0xFF6B4423) : const Color(0xFFF1D3C7),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
          ),
          const SizedBox(height: 4),
          ListenableBuilder(
            listenable: LanguageService.instance,
            builder: (context, _) => Text(
              brownHand ? TryOnStrings.brownHand : TryOnStrings.lightHand,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.title.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: ListenableBuilder(
                listenable: LanguageService.instance,
                builder: (context, _) => Text(TryOnStrings.closeCamera),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
