import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_app/screens/results_screen.dart';
import 'package:iris_app/widgets/pulsating_orb.dart';
import 'dart:async';

class ProcessingScreen extends StatefulWidget {
  final dynamic imagePath;
  final bool animated;

  const ProcessingScreen({
    super.key,
    required this.imagePath,
    this.animated = true,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  // Remove the old timer-based message index
  final List<String> _messages = [
    'Analyzing your eye image in detail',
    'Detecting patterns and anomalies',
    'Processing the diagnostic results',
    'Preparing your analysis report',
  ];
  final bool _imageError = false;
  bool _isProcessing = true;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _startProcessingSequence();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _isProcessing = false;
    super.dispose();
  }

  void _startProcessingSequence() {
    // Start a timer to navigate to ResultsScreen after 10 seconds
    _navigationTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isProcessing) {
        _isProcessing = false;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return ResultsScreen(
                animated: widget.animated,
                diagnosisData: {
                  'diagnosis':
                      'Your eye scan analysis is complete. No significant abnormalities detected.',
                  'isNormal': true,
                },
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (!_imageError) ...[
                    Hero(
                      tag: 'selected_image',
                      child: PulsatingOrb(
                        imagePath: widget.imagePath,
                        size: MediaQuery.of(context).size.width * 0.4,
                        animate: widget.animated,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Replace the static text container with AnimatedFillerText
                    AnimatedFillerText(
                      sentences: _messages,
                      textStyle: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ] else
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
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

/// AnimatedFillerText cycles through the provided sentences.
/// 1. Each sentence's words fade in one-by-one, wrapping to multiple lines as needed.
/// 2. Once all words are visible, an ellipsis is animated for ~3s.
/// 3. Finally, the entire text (words + ellipsis) slides left *within the white box* (in 400ms),
///    disappearing smoothly before the next sentence appears.
class AnimatedFillerText extends StatefulWidget {
  final List<String> sentences;
  final TextStyle textStyle;
  final Duration wordDelay;
  final Duration stayDuration;
  final Duration exitDuration;

  const AnimatedFillerText({
    Key? key,
    required this.sentences,
    required this.textStyle,
    this.wordDelay = const Duration(milliseconds: 300), // delay between words
    this.stayDuration =
        const Duration(seconds: 3), // time sentence stays visible w/ ellipsis
    this.exitDuration = const Duration(milliseconds: 400), // flush-left speed
  }) : super(key: key);

  @override
  _AnimatedFillerTextState createState() => _AnimatedFillerTextState();
}

class _AnimatedFillerTextState extends State<AnimatedFillerText> {
  int _currentSentenceIndex = 0;
  List<bool> _wordVisible = [];
  bool _isExiting = false;
  String _ellipsis = "";
  final List<Timer> _timers = [];
  Timer? _ellipsisTimer;

  @override
  void initState() {
    super.initState();
    _startAnimationCycle();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _ellipsisTimer?.cancel();
    super.dispose();
  }

  void _startAnimationCycle() {
    _resetAnimation();
    final sentence = widget.sentences[_currentSentenceIndex];
    final words = sentence.split(' ');

    // Use a growable list for word visibility
    _wordVisible = List<bool>.filled(words.length, false, growable: true);

    // 1) Fade in each word sequentially
    for (int i = 0; i < words.length; i++) {
      Timer timer = Timer(widget.wordDelay * i, () {
        if (mounted) {
          setState(() {
            _wordVisible[i] = true;
          });
        }
      });
      _timers.add(timer);
    }

    // 2) Once all words are visible, start the ellipsis animation
    Timer ellipsisStartTimer = Timer(widget.wordDelay * words.length, () {
      int dotCount = 0;
      _ellipsisTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
        if (mounted) {
          setState(() {
            dotCount =
                (dotCount + 1) % 4; // cycles through "", ".", "..", "..."
            _ellipsis = '.' * dotCount;
          });
        }
      });
    });
    _timers.add(ellipsisStartTimer);

    // 3) After the stayDuration, flush left (slide out) the entire sentence
    Timer exitTimer = Timer(
      widget.wordDelay * words.length + widget.stayDuration,
      () {
        if (mounted) {
          setState(() {
            _isExiting = true;
          });
          _ellipsisTimer?.cancel();

          // After the slide-out animation finishes, move to the next sentence
          Timer nextTimer = Timer(widget.exitDuration, () {
            if (mounted) {
              setState(() {
                _currentSentenceIndex =
                    (_currentSentenceIndex + 1) % widget.sentences.length;
                _resetAnimation();
                _startAnimationCycle();
              });
            }
          });
          _timers.add(nextTimer);
        }
      },
    );
    _timers.add(exitTimer);
  }

  void _resetAnimation() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    _ellipsisTimer?.cancel();
    _ellipsis = "";
    _wordVisible = [];
    _isExiting = false;
  }

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentences[_currentSentenceIndex];
    final words = sentence.split(' ');

    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!.withAlpha(100),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ClipRect ensures the sliding text is only visible within this container.
      child: ClipRect(
        child: AnimatedSlide(
          duration: widget.exitDuration,
          offset: _isExiting ? const Offset(-1, 0) : Offset.zero,
          child: Wrap(
            // Using Wrap ensures long text can break onto multiple lines
            spacing: 4,
            runSpacing: 4,
            children: [
              for (int i = 0; i < words.length; i++)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity:
                      _wordVisible.length > i && _wordVisible[i] ? 1.0 : 0.0,
                  child: Text(
                    words[i],
                    style: widget.textStyle,
                  ),
                ),
              // Show ellipsis only once all words are visible
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _wordVisible.every((element) => element) ? 1.0 : 0.0,
                child: Text(
                  _ellipsis,
                  style: widget.textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
