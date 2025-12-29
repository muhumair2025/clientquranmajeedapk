import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import '../widgets/app_text.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import '../services/qibla_service.dart';
import 'package:geolocator/geolocator.dart';

class QiblaFinderScreen extends StatefulWidget {
  const QiblaFinderScreen({super.key});

  @override
  State<QiblaFinderScreen> createState() => _QiblaFinderScreenState();
}

class _QiblaFinderScreenState extends State<QiblaFinderScreen>
    with TickerProviderStateMixin {
  // State
  bool _isLoading = true;
  bool _needsCalibration = true;
  bool _hasPermissions = false;
  String? _errorMessage;
  
  // Location
  Position? _currentPosition;
  double? _qiblaDirection;
  double? _distanceToKaaba;
  
  // Compass
  double _compassHeading = 0;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  
  // Calibration - improved tracking
  late AnimationController _figure8Controller;
  double _totalRotation = 0;
  double _lastHeading = 0;
  bool _firstReading = true;
  static const double _requiredRotation = 720; // 2 full rotations

  @override
  void initState() {
    super.initState();
    _figure8Controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkPermissions();
    if (_hasPermissions) {
      await _getLocation();
      await _initCamera();
      _startCompass();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.request();
    final cameraStatus = await Permission.camera.request();
    
    setState(() {
      _hasPermissions = locationStatus.isGranted && cameraStatus.isGranted;
      if (!_hasPermissions) {
        _errorMessage = 'Location and camera permissions are required';
      }
    });
  }

  Future<void> _getLocation() async {
    try {
      final position = await QiblaService.getCurrentLocation();
      if (position != null) {
        final qiblaDir = QiblaService.calculateQiblaDirection(
          position.latitude,
          position.longitude,
        );
        final distance = QiblaService.calculateDistanceToKaaba(
          position.latitude,
          position.longitude,
        );
        
        setState(() {
          _currentPosition = position;
          _qiblaDirection = qiblaDir;
          _distanceToKaaba = distance;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to get location');
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        final newHeading = event.heading!;
        
        if (_needsCalibration) {
          _updateCalibration(newHeading);
        }
        
        setState(() => _compassHeading = newHeading);
      }
    });
  }

  void _updateCalibration(double heading) {
    if (_firstReading) {
      _lastHeading = heading;
      _firstReading = false;
      return;
    }
    
    // Calculate delta with wrap-around handling
    double delta = heading - _lastHeading;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    
    _totalRotation += delta.abs();
    _lastHeading = heading;
    
    if (_totalRotation >= _requiredRotation) {
      setState(() => _needsCalibration = false);
    } else {
      setState(() {}); // Update progress
    }
  }

  void _skipCalibration() {
    setState(() => _needsCalibration = false);
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _cameraController?.dispose();
    _figure8Controller.dispose();
    super.dispose();
  }

  double get _calibrationProgress => 
      math.min(1.0, _totalRotation / _requiredRotation);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: AppText(context.l.qiblaFinder),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (!_hasPermissions) return _buildPermissionDenied();
    if (_errorMessage != null) return _buildError();
    if (_needsCalibration) return _buildCalibration();
    return _buildQiblaCompass();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          AppText(context.l.loading, style: context.textStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 80, color: Colors.white54),
            const SizedBox(height: 24),
            AppText(
              context.l.permissionsRequired,
              style: context.textStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AppText(
              context.l.enablePermissions,
              style: context.textStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          AppText(_errorMessage ?? 'Error', style: context.textStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() { _errorMessage = null; _isLoading = true; });
              _initialize();
            },
            child: AppText(context.l.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibration() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                context.l.calibrateCompass,
                style: context.textStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              AppText(
                context.l.movePhoneFigure8,
                style: context.textStyle(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 50),
              
              // Figure-8 animation
              SizedBox(
                width: 180,
                height: 280,
                child: AnimatedBuilder(
                  animation: _figure8Controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _Figure8Painter(
                        progress: _figure8Controller.value * 2 * math.pi,
                        progressFill: _calibrationProgress,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              
              // Progress
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _calibrationProgress,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppText(
                      '${(_calibrationProgress * 100).toInt()}%',
                      style: context.textStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              
              TextButton(
                onPressed: _skipCalibration,
                child: AppText(
                  context.l.skipCalibration,
                  style: context.textStyle(fontSize: 14, color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQiblaCompass() {
    final qiblaAngle = _qiblaDirection ?? 0;
    final compassAngle = _compassHeading;
    // Angle to rotate the needle to point at Qibla
    final needleAngle = (qiblaAngle - compassAngle) * (math.pi / 180);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera background
        if (_isCameraInitialized && _cameraController != null)
          CameraPreview(_cameraController!)
        else
          Container(color: const Color(0xFF1a1a1a)),
        
        // Overlay
        Container(color: Colors.black.withOpacity(0.4)),
        
        // Content
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80),
              
              // Distance badge
              if (_distanceToKaaba != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🕋', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      AppText(
                        '${_distanceToKaaba!.toStringAsFixed(0)} ${context.l.distanceToMakkah}',
                        style: context.textStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              
              const Spacer(),
              
              // Compass with Kaaba marker
              SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Compass ring (rotates with device)
                    Transform.rotate(
                      angle: -compassAngle * (math.pi / 180),
                      child: CustomPaint(
                        size: const Size(300, 300),
                        painter: _ModernCompassPainter(),
                      ),
                    ),
                    
                    // Kaaba emoji fixed at Qibla direction
                    Transform.rotate(
                      angle: needleAngle,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryGreen, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Text('🕋', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),
                    ),
                    
                    // Center needle (points to Qibla)
                    Transform.rotate(
                      angle: needleAngle,
                      child: CustomPaint(
                        size: const Size(300, 300),
                        painter: _NeedlePainter(),
                      ),
                    ),
                    
                    // Center dot
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Direction info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    AppText(
                      context.l.qiblaDirection,
                      style: context.textStyle(fontSize: 13, color: Colors.white60),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AppText(
                          '${qiblaAngle.toStringAsFixed(1)}',
                          style: context.textStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        AppText(
                          '°',
                          style: context.textStyle(fontSize: 24, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        AppText(
                          QiblaService.getDirectionName(qiblaAngle),
                          style: context.textStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.5), blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    context.l.compassActive,
                    style: context.textStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// Figure-8 painter
class _Figure8Painter extends CustomPainter {
  final double progress;
  final double progressFill;

  _Figure8Painter({required this.progress, required this.progressFill});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = size.width * 0.4;
    final radiusY = size.height * 0.23;

    // Background path
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (double t = 0; t <= 2 * math.pi; t += 0.02) {
      final x = centerX + radiusX * math.sin(t);
      final y = centerY + radiusY * math.sin(2 * t);
      if (t == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, bgPaint);

    // Progress fill
    final fillPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final fillPath = Path();
    final maxT = 2 * math.pi * progressFill;
    for (double t = 0; t <= maxT; t += 0.02) {
      final x = centerX + radiusX * math.sin(t);
      final y = centerY + radiusY * math.sin(2 * t);
      if (t == 0) fillPath.moveTo(x, y);
      else fillPath.lineTo(x, y);
    }
    canvas.drawPath(fillPath, fillPaint);

    // Moving dot
    final dotX = centerX + radiusX * math.sin(progress);
    final dotY = centerY + radiusY * math.sin(2 * progress);
    
    // Glow
    canvas.drawCircle(
      Offset(dotX, dotY),
      16,
      Paint()..color = AppTheme.primaryGreen.withOpacity(0.3),
    );
    // Dot
    canvas.drawCircle(
      Offset(dotX, dotY),
      8,
      Paint()..color = AppTheme.primaryGreen,
    );
  }

  @override
  bool shouldRepaint(covariant _Figure8Painter old) => true;
}

// Modern compass painter
class _ModernCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner ring
    canvas.drawCircle(
      center,
      radius - 25,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Direction letters
    final directions = ['N', 'E', 'S', 'W'];
    final colors = [Colors.red, Colors.white70, Colors.white70, Colors.white70];
    
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: colors[i],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      final x = center.dx + (radius - 45) * math.cos(angle) - textPainter.width / 2;
      final y = center.dy + (radius - 45) * math.sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(x, y));
    }

    // Tick marks
    for (int i = 0; i < 72; i++) {
      final angle = i * 5 * math.pi / 180 - math.pi / 2;
      final isMain = i % 18 == 0;
      final isMedium = i % 9 == 0;
      
      double len = 6;
      double width = 1;
      if (isMain) { len = 14; width = 2; }
      else if (isMedium) { len = 10; width = 1.5; }
      
      final start = Offset(
        center.dx + (radius - len) * math.cos(angle),
        center.dy + (radius - len) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      canvas.drawLine(
        start, end,
        Paint()
          ..color = isMain ? Colors.white54 : Colors.white24
          ..strokeWidth = width,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Needle painter
class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Needle pointing up (to Qibla)
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - 90); // Tip
    needlePath.lineTo(center.dx - 8, center.dy - 20);
    needlePath.lineTo(center.dx + 8, center.dy - 20);
    needlePath.close();
    
    // Shadow
    canvas.drawPath(
      needlePath.shift(const Offset(2, 2)),
      Paint()..color = Colors.black38,
    );
    
    // Needle gradient
    final needlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryGreen,
          AppTheme.primaryGreen.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCenter(center: center, width: 20, height: 100));
    
    canvas.drawPath(needlePath, needlePaint);
    
    // Outline
    canvas.drawPath(
      needlePath,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
