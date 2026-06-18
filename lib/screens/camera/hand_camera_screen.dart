import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/try_on_strings.dart';
import '../../core/camera/hand_guide_layout.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../models/nail_look.dart';
import '../../services/language_service.dart';
import '../../services/nail_look_repository.dart';
import '../../widgets/camera_bottom_panel.dart';
import '../../widgets/hand_trace_overlay.dart';
import '../../widgets/nail_look_overlay.dart';

class HandCameraScreen extends StatefulWidget {
  const HandCameraScreen({super.key});

  @override
  State<HandCameraScreen> createState() => _HandCameraScreenState();
}

class _HandCameraScreenState extends State<HandCameraScreen> {
  final _lookRepository = NailLookRepository.instance;

  CameraController? _controller;
  bool _ready = false;
  bool _looksLoaded = false;
  bool _showGuide = true;
  bool _isLeftHand = true;
  bool _capturing = false;
  double _guideScale = 1.0;
  String? _errorMessage;
  CameraPanelTab _activeTab = CameraPanelTab.looks;
  NailLook? _selectedLook;

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
        imageFormatGroup: ImageFormatGroup.jpeg,
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
    } on CameraException catch (e) {
      setState(() => _errorMessage = e.description ?? TryOnStrings.cameraUnavailable);
    } catch (_) {
      setState(() => _errorMessage = TryOnStrings.cameraUnavailable);
    }
  }

  @override
  void dispose() {
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
    }
  }

  void _onTabChanged(CameraPanelTab tab) {
    setState(() {
      _activeTab = tab;
      if (tab != CameraPanelTab.looks) {
        _selectedLook = null;
      }
    });
  }

  void _onLookSelected(NailLook look) {
    setState(() {
      _activeTab = CameraPanelTab.looks;
      _selectedLook = look;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _errorMessage != null ? _ErrorView(message: _errorMessage!) : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final controller = _controller;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final guideHeight = screenHeight * HandGuideLayout.heightScreenFactor;

    return Column(
      children: [
        Expanded(
          child: Stack(
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
                      showGuide: _showGuide,
                      onClose: () => Navigator.of(context).pop(),
                      onToggleGuide: () => setState(() => _showGuide = !_showGuide),
                    ),
                    const SizedBox(height: 12),
                    _HintBanner(),
                  ],
                ),
              ),
              if (_selectedLook != null && _activeTab == CameraPanelTab.looks)
                Center(
                  child: NailLookOverlay(
                    look: _selectedLook!,
                    isLeftHand: _isLeftHand,
                    height: guideHeight,
                    scale: _guideScale,
                  ),
                ),
              if (_showGuide)
                Center(
                  child: HandTraceOverlay(
                    isLeftHand: _isLeftHand,
                    height: guideHeight,
                    scale: _guideScale,
                  ),
                ),
              if (_showGuide)
                Positioned(
                  left: 48,
                  right: 48,
                  bottom: 16,
                  child: _GuideScaleSlider(
                    value: _guideScale,
                    onChanged: (value) => setState(() => _guideScale = value),
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
          ),
        ),
        if (_looksLoaded)
          CameraBottomPanel(
            activeTab: _activeTab,
            looks: _lookRepository.all,
            selectedLookId: _selectedLook?.id,
            onTabChanged: _onTabChanged,
            onLookSelected: _onLookSelected,
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
    required this.showGuide,
    required this.onClose,
    required this.onToggleGuide,
  });

  final bool showGuide;
  final VoidCallback onClose;
  final VoidCallback onToggleGuide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
          const Spacer(),
          Column(
            children: [
              Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.85), size: 24),
              const SizedBox(height: 2),
              ListenableBuilder(
                listenable: LanguageService.instance,
                builder: (context, _) => Text(
                  TryOnStrings.timerOff,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onToggleGuide,
            child: Column(
              children: [
                Icon(
                  Icons.back_hand_outlined,
                  color: showGuide ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.85),
                  size: 24,
                ),
                const SizedBox(height: 2),
                ListenableBuilder(
                  listenable: LanguageService.instance,
                  builder: (context, _) => Text(
                    showGuide ? TryOnStrings.guideOn : TryOnStrings.guideOff,
                    style: TextStyle(
                      color: showGuide ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) => Text(
          TryOnStrings.whiteBackgroundHint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GuideScaleSlider extends StatelessWidget {
  const _GuideScaleSlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: Colors.white.withValues(alpha: 0.35),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.35),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: SliderComponentShape.noOverlay,
        thumbColor: AppColors.primary,
      ),
      child: Slider(
        value: value,
        min: 0.75,
        max: 1.35,
        onChanged: onChanged,
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
