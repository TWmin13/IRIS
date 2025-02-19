import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iris_app/screens/processing_screen.dart';

class CameraScreen extends StatefulWidget {
  final bool animated;

  const CameraScreen({
    super.key,
    this.animated = true,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late List<CameraDescription> _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  bool _cameraError = false;
  bool _isCapturing = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndSetupCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndSetupCamera();
    }
  }

  Future<void> _checkPermissionsAndSetupCamera() async {
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) {
      if (mounted) setState(() => _isPermissionGranted = true);
      _setupCamera();
    } else {
      _requestCameraPermission();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white.withAlpha(230),
          title: Text(
            'Camera Permission Required',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Camera permission is required to capture eye images. Please enable it in settings.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Open Settings', style: GoogleFonts.inter()),
            ),
          ],
        ),
      );
      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    } else if (status.isGranted) {
      if (mounted) setState(() => _isPermissionGranted = true);
      _setupCamera();
    } else {
      if (mounted) setState(() => _isPermissionGranted = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera permission is required',
              style: GoogleFonts.inter(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras[_selectedCameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _cameraError = false;
          });
        }
      } else {
        setState(() => _cameraError = true);
        _showError('No cameras available');
      }
    } on CameraException catch (e) {
      setState(() => _cameraError = true);
      _showError('Camera error: ${e.description}');
    } catch (e) {
      setState(() => _cameraError = true);
      _showError('Error initializing camera: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;

    final newIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = newIndex;
    });

    await _cameraController?.dispose();

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = false;
        });
      }
    } catch (e) {
      setState(() => _cameraError = true);
      _showError('Error switching camera: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleCapture() async {
    if (!_isCameraInitialized || _cameraController == null || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      await _cameraController!.setFlashMode(FlashMode.off);
      final XFile image = await _cameraController!.takePicture();
      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return ProcessingScreen(
                imagePath: image.path,
                animated: widget.animated,
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      _showError('Error capturing image: $e');
      setState(() => _isCapturing = false);
    }
  }

  Widget _buildCameraPreview() {
    if (!_isPermissionGranted) {
      return _buildPlaceholder(
        icon: Icons.camera_alt_rounded,
        message: 'Camera permission required',
      );
    }

    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraError) {
      return _buildPlaceholder(
        icon: _cameraError
            ? Icons.error_outline_rounded
            : Icons.camera_alt_rounded,
        message: _cameraError ? 'Camera error' : 'Initializing camera...',
        isError: _cameraError,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withAlpha(128),
              width: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String message,
    bool isError = false,
  }) {
    return Container(
      color: Colors.black.withAlpha(25),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isError ? Colors.red : Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                color: isError ? Colors.red : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionButton() {
    return _GlassButton(
      onPressed: _requestCameraPermission,
      icon: Icons.camera_alt_rounded,
      label: 'Grant Camera Permission',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Take a Scan',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildCameraPreview(),
                ),
              ),
              const SizedBox(height: 30),
              if (!_isPermissionGranted)
                _buildPermissionButton()
              else if (!_cameraError)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GlassCaptureButton(
                      onPressed: _handleCapture,
                      isCapturing: _isCapturing,
                    ),
                    if (_cameras.length > 1) ...[
                      const SizedBox(width: 20),
                      _GlassIconButton(
                        onPressed: _flipCamera,
                        icon: Icons.flip_camera_ios_rounded,
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _GlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        splashColor: Colors.blue.withAlpha(25),
        highlightColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[600]!.withAlpha(179),
                Colors.blue[600]!.withAlpha(230),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCaptureButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCapturing;

  const _GlassCaptureButton({
    required this.onPressed,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: Colors.white.withAlpha(25),
        highlightColor: Colors.transparent,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(179),
                Colors.white.withAlpha(230),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isCapturing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue,
                        width: 4,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const _GlassIconButton({
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: Colors.white.withAlpha(25),
        highlightColor: Colors.transparent,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(179),
                Colors.white.withAlpha(230),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 24,
          ),
        ),
      ),
    );
  }
}
