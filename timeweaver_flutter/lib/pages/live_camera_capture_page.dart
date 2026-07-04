import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/permission_service.dart';

class LiveCameraCapturePage extends StatefulWidget {
  const LiveCameraCapturePage({super.key});

  @override
  State<LiveCameraCapturePage> createState() => _LiveCameraCapturePageState();
}

class _LiveCameraCapturePageState extends State<LiveCameraCapturePage>
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _activeCameraIndex = 0;
  bool _cameraAvailable = true;
  bool _initializing = true;
  bool _isCapturing = false;
  bool _torchEnabled = false;
  String _statusText = '实时取景已就绪';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(controller.dispose());
      _cameraController = null;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_bindCamera(_activeCameraIndex));
    }
  }

  Future<void> _initializeCamera() async {
    setState(() => _initializing = true);
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _cameras = const [];
          _cameraAvailable = false;
          _initializing = false;
          _statusText = '当前设备暂时没有可用摄像头';
        });
        return;
      }
      _cameras = cameras;
      final backIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _activeCameraIndex = backIndex >= 0 ? backIndex : 0;
      await _bindCamera(_activeCameraIndex);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraAvailable = false;
        _initializing = false;
        _statusText = '相机预览不可用';
      });
    }
  }

  Future<void> _bindCamera(int index) async {
    if (_cameras.isEmpty) return;
    final oldController = _cameraController;
    if (oldController != null) {
      await oldController.dispose();
    }

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _cameraController = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) return;
      setState(() {
        _activeCameraIndex = index;
        _initializing = false;
        _cameraAvailable = true;
        _torchEnabled = false;
        _statusText = '实时取景已就绪';
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _cameraAvailable = false;
        _initializing = false;
        _statusText = '相机预览不可用';
      });
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final enableTorch = !_torchEnabled;
    try {
      await controller.setFlashMode(
        enableTorch ? FlashMode.torch : FlashMode.off,
      );
      if (!mounted) return;
      setState(() => _torchEnabled = enableTorch);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前镜头暂不支持闪光灯控制')));
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1 || _isCapturing) return;
    final nextIndex = (_activeCameraIndex + 1) % _cameras.length;
    setState(() {
      _initializing = true;
      _statusText = '正在切换摄像头…';
    });
    await _bindCamera(nextIndex);
  }

  Future<void> _pickFromAlbum() async {
    final granted = await _permissionService.requestPhotos();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要图片读取权限才能导入相册或分享图片，请先授权。')),
      );
      return;
    }
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null || !mounted) return;
    Navigator.of(context).pop(picked.path);
  }

  Future<void> _capture() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      setState(() => _statusText = '相机尚未准备完成，请稍等一秒后重试。');
      return;
    }
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _statusText = '正在截取当前画面…';
    });
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _statusText = '拍照失败，请重新对准目标后再试一次。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewReady =
        _cameraAvailable &&
        !_initializing &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (previewReady)
            CameraPreview(_cameraController!)
          else
            Container(color: Colors.black),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.38),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: '返回',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      Row(
                        children: [
                          _GlassIconButton(
                            icon: _torchEnabled
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            tooltip: '闪光灯',
                            onTap: _toggleTorch,
                          ),
                          const SizedBox(width: 10),
                          _GlassIconButton(
                            icon: Icons.cameraswitch_rounded,
                            tooltip: '切换摄像头',
                            onTap: _cameras.length > 1 ? _switchCamera : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cameraAvailable
                              ? '把海报、课表或群通知放进取景框'
                              : '相机预览不可用',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _cameraAvailable
                              ? '确认画面清晰后点击下方快门，织时会截取这一帧进行解析。'
                              : '当前设备没有可用相机预览，请改用相册、分享或粘贴文本继续导入。',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SideActionButton(
                        icon: Icons.photo_library_rounded,
                        label: '相册',
                        enabled: !_isCapturing,
                        onTap: _pickFromAlbum,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isCapturing
                                ? '正在截取当前画面…'
                                : (_statusText.isEmpty
                                      ? '实时取景已就绪'
                                      : _statusText),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _cameraAvailable && !_isCapturing
                                ? _capture
                                : null,
                            child: Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.42),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 66,
                                height: 66,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF003528),
                                ),
                                child: const Icon(
                                  Icons.photo_camera_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 64, height: 64),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.24),
        fixedSize: const Size(48, 48),
      ),
      icon: Icon(icon, color: Colors.white),
    );
  }
}

class _SideActionButton extends StatelessWidget {
  const _SideActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
