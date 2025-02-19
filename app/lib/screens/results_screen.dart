import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_app/widgets/aurora_background.dart';
import 'package:iris_app/screens/home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum EyeCondition {
  normal,
  conjunctivitis,
  glaucoma,
  cataract,
  diabeticRetinopathy,
  unknown
}

class MLService {
  static final _random = math.Random();
  static final _conditions = [
    {
      'condition': 'normal',
      'confidence': 0.95,
      'diagnosis':
          'No abnormalities detected in the eye scan. Your eyes appear to be healthy.',
    },
    {
      'condition': 'conjunctivitis',
      'confidence': 0.88,
      'diagnosis':
          'Signs of conjunctivitis detected. Please consult an eye specialist for proper treatment.',
    },
    {
      'condition': 'glaucoma',
      'confidence': 0.92,
      'diagnosis':
          'Potential indicators of glaucoma present. Early detection is crucial - schedule an appointment with an ophthalmologist.',
    },
    {
      'condition': 'cataract',
      'confidence': 0.90,
      'diagnosis':
          'Cataract formation detected. This is a common age-related condition that can be treated with surgery.',
    },
    {
      'condition': 'diabeticRetinopathy',
      'confidence': 0.87,
      'diagnosis':
          'Signs of diabetic retinopathy observed. Regular monitoring and blood sugar control is essential.',
    },
  ];

  static int _lastIndex = -1;

  static Future<Map<String, dynamic>> analyzeImage(
      dynamic imagePath, bool isWeb) async {
    await Future.delayed(const Duration(seconds: 2));

    // Ensure we don't get the same condition twice in a row
    int newIndex;
    do {
      newIndex = _random.nextInt(_conditions.length);
    } while (newIndex == _lastIndex && _conditions.length > 1);

    _lastIndex = newIndex;
    return _conditions[newIndex];
  }
}

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? diagnosisData;
  final bool animated;

  const ResultsScreen({
    super.key,
    this.diagnosisData,
    this.animated = true,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  late EyeCondition _condition;
  String _diagnosis = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _processData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _processData() async {
    try {
      if (widget.diagnosisData == null) {
        throw Exception('No diagnosis data provided');
      }

      final results = await MLService.analyzeImage(
        widget.diagnosisData,
        widget.diagnosisData is Uint8List,
      );

      if (!mounted) return;

      setState(() {
        _condition = EyeCondition.values.firstWhere(
          (e) =>
              e.toString().toLowerCase() ==
              'EyeCondition.${results['condition']}'.toLowerCase(),
          orElse: () => EyeCondition.unknown,
        );
        _diagnosis = results['diagnosis'];
        _isLoading = false;
        _error = null;
        _animController.forward();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error processing results: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Color _getConditionColor() {
    switch (_condition) {
      case EyeCondition.normal:
        return Colors.green;
      case EyeCondition.unknown:
        return Colors.grey; // Changed from orange to grey
      default:
        return Colors.orange; // Changed from red to orange for less alarming UX
    }
  }

  String _getConditionTitle() {
    switch (_condition) {
      case EyeCondition.normal:
        return 'No Abnormalities Detected';
      case EyeCondition.conjunctivitis:
        return 'Conjunctivitis Detected';
      case EyeCondition.glaucoma:
        return 'Glaucoma Indicators Present';
      case EyeCondition.cataract:
        return 'Cataract Detected';
      case EyeCondition.diabeticRetinopathy:
        return 'Diabetic Retinopathy Signs';
      case EyeCondition.unknown:
        return 'Unable to Determine Condition'; // Fixed incorrect message
    }
  }

  Widget _getConditionIcon(double size, Color color) {
    String assetName;
    switch (_condition) {
      case EyeCondition.normal:
        return Icon(
          Icons.check_circle_outline,
          size: size,
          color: color,
        );
      case EyeCondition.conjunctivitis:
        assetName = 'assets/icons/conjunctivitis.svg';
        break;
      case EyeCondition.glaucoma:
        assetName = 'assets/icons/glaucoma.svg';
        break;
      case EyeCondition.cataract:
        assetName = 'assets/icons/cataract.svg';
        break;
      case EyeCondition.diabeticRetinopathy:
        assetName = 'assets/icons/retinopathy.svg';
        break;
      case EyeCondition.unknown:
        return Icon(
          Icons.help_outline_rounded,
          size: size,
          color: color,
        );
    }

    return SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // NO TOP SHADOW: transparent AppBar, elevation=0
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Analysis Results',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildResultsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Results',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),
            _buildHomeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final color = _getConditionColor();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(51),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _animController,
                      curve: Curves.easeInOut,
                    ),
                    child: _getConditionIcon(80, color),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _getConditionTitle(),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _diagnosis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildHomeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return Hero(
      tag: 'home_button',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(animated: true),
            ),
            (route) => false,
          ),
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
                  const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Return Home',
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
      ),
    );
  }
}
