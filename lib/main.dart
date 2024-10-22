import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:arabic_numbers/arabic_numbers.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arabic Speech Recognition Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: SpeechRecognitionPage(),
    );
  }
}

class SpeechRecognitionPage extends StatefulWidget {
  @override
  _SpeechRecognitionPageState createState() => _SpeechRecognitionPageState();
}

class _SpeechRecognitionPageState extends State<SpeechRecognitionPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  Timer? _timer;
  int _start = 30;
  double _grade = 0.0;
  bool _isPassed = false;
  final String _quranicText = 'قُلْ هُوَ اللَّهُ أَحَدٌ';

  @override
  void initState() {
    super.initState();
    _initSpeechRecognizer();
  }

  void _initSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onError: (error) => print('Error: $error'),
      debugLogging: true,
    );
    if (available) {
      setState(() {});
    } else {
      print("The user has denied the use of speech recognition.");
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _start = 30;
          _grade = 0.0;
          _isPassed = false;
          _text = 'Listening...';
        });
        _startTimer();
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
          },
          localeId: 'ar-SA', // Set language to Arabic (Saudi Arabia)
          listenMode: stt.ListenMode.confirmation,
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
      _timer?.cancel();
      _gradeRecitation();
    }
  }

  void _startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _isListening = false;
            _speech.stop();
            _gradeRecitation();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  void _gradeRecitation() {
    double similarity = compareQuranicArabic(_text, _quranicText);
    setState(() {
      _grade = similarity * 100;
      _isPassed = _grade >= 70;
    });
  }

  double compareQuranicArabic(String recited, String reference) {
    // Normalize texts
    recited = normalizeArabicText(recited);
    reference = normalizeArabicText(reference);

    // Split into words
    List<String> recitedWords = recited.split(' ');
    List<String> referenceWords = reference.split(' ');

    int matchedWords = 0;
    int totalWords = referenceWords.length;

    for (int i = 0; i < referenceWords.length; i++) {
      if (i < recitedWords.length) {
        double wordSimilarity =
            compareWords(recitedWords[i], referenceWords[i]);
        if (wordSimilarity > 0.8) {
          // Threshold for considering a word as correct
          matchedWords++;
        }
      }
    }

    return matchedWords / totalWords;
  }

  String normalizeArabicText(String text) {
    // Remove diacritics (harakat)
    text = text.replaceAll(RegExp(r'[\u064B-\u0652]'), '');

    // Normalize alifs
    text = text.replaceAll(RegExp(r'[أإآا]'), 'ا');

    // Normalize yaas and alif maqsura
    text = text.replaceAll(RegExp(r'[يى]'), 'ي');

    // Normalize taas
    text = text.replaceAll(RegExp(r'[ةت]'), 'ت');

    // Remove non-Arabic characters
    text = text.replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '');

    // Convert Arabic numbers to Hindi numbers
    ArabicNumbers arabicNumber = ArabicNumbers();
    text = arabicNumber.convert(text);

    return text.trim().toLowerCase();
  }

  double compareWords(String word1, String word2) {
    int maxLength = word1.length > word2.length ? word1.length : word2.length;
    int distance = levenshteinDistance(word1, word2);
    return 1 - (distance / maxLength);
  }

  int levenshteinDistance(String s1, String s2) {
    int m = s1.length;
    int n = s2.length;
    List<List<int>> d = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      d[i][0] = i;
    }

    for (int j = 1; j <= n; j++) {
      d[0][j] = j;
    }

    for (int j = 1; j <= n; j++) {
      for (int i = 1; i <= m; i++) {
        if (s1[i - 1] == s2[j - 1]) {
          d[i][j] = d[i - 1][j - 1];
        } else {
          d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + 1]
              .reduce((curr, next) => curr < next ? curr : next);
        }
      }
    }

    return d[m][n];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quranic Arabic Speech Recognition Test'),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: Column(
            children: <Widget>[
              Text(
                _quranicText,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 20),
              Text(
                'Time remaining: $_start seconds',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              Text(
                _text,
                style: TextStyle(fontSize: 18),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 20),
              Text(
                'Grade: ${_grade.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _isPassed ? 'Passed' : 'Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isPassed ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
