import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    _cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '각도기',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const ProtractorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProtractorScreen extends StatefulWidget {
  const ProtractorScreen({super.key});

  @override
  State<ProtractorScreen> createState() => _ProtractorScreenState();
}

class _ProtractorScreenState extends State<ProtractorScreen> {
  CameraController? _controller;
  bool _initialized = false;
  String? _errorMessage;

  XFile? _backgroundImage;
  final ImagePicker _picker = ImagePicker();

  Offset _position = const Offset(200, 420);
  double _rotation = 0.0;
  double _scale = 1.0;

  late Offset _gestureStartOffset;
  late double _gestureStartScale;
  late double _gestureStartRotation;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (_cameras.isEmpty) {
      setState(() => _errorMessage = '카메라를 찾을 수 없어요.');
      return;
    }
    try {
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '카메라 오류: $e');
      }
    }
  }

  Future<void> _takeSnapshot() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final file = await _controller!.takePicture();
      setState(() {
        _backgroundImage = file;
      });
    } catch (e) {
      debugPrint('촬영 오류: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _backgroundImage = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('갤러리 오류: $e');
    }
  }

  void _resetToCamera() {
    setState(() {
      _backgroundImage = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartOffset = _position - details.localFocalPoint;
    _gestureStartScale = _scale;
    _gestureStartRotation = _rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _position = details.localFocalPoint + _gestureStartOffset;
      _scale = (_gestureStartScale * details.scale).clamp(0.2, 5.0);
      _rotation = _gestureStartRotation + details.rotation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_backgroundImage != null)
            SizedBox.expand(
              child: Image.file(
                File(_backgroundImage!.path),
                fit: BoxFit.cover,
              ),
            )
          else if (_errorMessage != null)
            Center(child: Text(_errorMessage!))
          else if (!_initialized)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

          GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            child: CustomPaint(
              painter: ProtractorPainter(
                position: _position,
                rotation: _rotation,
                scale: _scale,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_backgroundImage == null) ...[
                      _SmallButton(
                        icon: Icons.photo_library,
                        onTap: _pickFromGallery,
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: _takeSnapshot,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white.withAlpha(50),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(width: 30),
                      _SmallButton(
                        icon: Icons.refresh,
                        onTap: () => setState(() {
                          _position = MediaQuery.of(context).size.center(Offset.zero);
                          _rotation = 0.0;
                          _scale = 1.0;
                        }),
                      ),
                    ] else
                      GestureDetector(
                        onTap: _resetToCamera,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(150),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('카메라로 돌아가기', style: TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withAlpha(100),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class ProtractorPainter extends CustomPainter {
  final Offset position;
  final double rotation;
  final double scale;

  const ProtractorPainter({
    required this.position,
    required this.rotation,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);

    const double r = 160.0; // 반지름
    final Color mainColor = Colors.black.withAlpha(200);
    final Color tickColor = Colors.black;

    // 1. 투명한 반원 배경
    final fillPaint = Paint()
      ..color = Colors.white.withAlpha(160)
      ..style = PaintingStyle.fill;

    final fillPath = Path()
      ..moveTo(-r - 10, 0)
      ..lineTo(r + 10, 0)
      ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r + 10), 0, -pi, false)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    // 2. 테두리 및 기본선
    final linePaint = Paint()
      ..color = tickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), pi, -pi, false, linePaint);
    canvas.drawLine(Offset(-r, 0), Offset(r, 0), linePaint);

    // 3. 눈금 및 숫자 (이중 눈금 구현)
    for (int deg = 0; deg <= 180; deg++) {
      final rad = deg * pi / 180;
      final cosA = cos(rad);
      final sinA = sin(rad);

      // 바깥쪽 눈금 (0~180)
      double tickLen = (deg % 10 == 0) ? 15 : (deg % 5 == 0 ? 10 : 5);
      canvas.drawLine(
        Offset(r * cosA, -r * sinA),
        Offset((r - tickLen) * cosA, -(r - tickLen) * sinA),
        linePaint..strokeWidth = (deg % 10 == 0 ? 1.2 : 0.6),
      );

      // 10도마다 숫자 (바깥쪽: 0->180, 안쪽: 180->0)
      if (deg % 10 == 0) {
        // 바깥쪽 숫자
        _drawText(canvas, '${180 - deg}', (r - 28), rad, 11);
        // 안쪽 숫자
        _drawText(canvas, '$deg', (r - 45), rad, 11);
      }
      
      // 90도 중심선
      if (deg == 90) {
        canvas.drawLine(Offset.zero, Offset(0, -r), linePaint..strokeWidth = 1.0);
      }
    }

    // 4. 중앙 십자선 및 Oxford 로고 느낌의 텍스트
    _drawCenterMark(canvas, r);
    
    // 브랜드 텍스트 모사
    _drawBrandText(canvas, "OXFORD", Offset(-r * 0.6, -25), 14);
    _drawBrandText(canvas, "Helix", Offset(r * 0.6, -15), 12);

    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, double radius, double rad, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.black, fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    canvas.save();
    canvas.translate(radius * cos(rad), -radius * sin(rad));
    // 숫자가 읽기 편하게 살짝 회전 보정 (선택 사항)
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _drawBrandText(Canvas canvas, String text, Offset offset, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.black.withAlpha(180), fontSize: fontSize, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  void _drawCenterMark(Canvas canvas, double r) {
    final p = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // 중앙 반원 무늬
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: 25), pi, -pi, false, p);
    // 십자선
    canvas.drawLine(const Offset(-15, 0), const Offset(15, 0), p);
    canvas.drawLine(const Offset(0, -5), const Offset(0, 15), p);
  }

  @override
  bool shouldRepaint(ProtractorPainter old) => true;
}
