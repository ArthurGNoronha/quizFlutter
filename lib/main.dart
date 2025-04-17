import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCHUGteKQwvyASX0wy_yxSmFQNUFV9v7Zg",
        authDomain: "quizflutter-a1d47.firebaseapp.com",
        databaseURL: "https://quizflutter-a1d47-default-rtdb.firebaseio.com",
        projectId: "quizflutter-a1d47",
        storageBucket: "quizflutter-a1d47.firebasestorage.app",
        messagingSenderId: "220759118762",
        appId: "1:220759118762:web:75b6a2cec715ae4b1191d3",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  runApp(MyApp());
}

class Question {
  final String pergunta;
  final String url;
  final List<String> alternativas;
  final int correta;

  Question({
    required this.pergunta,
    required this.url,
    required this.alternativas,
    required this.correta,
  });

  factory Question.fromMap(Map<dynamic, dynamic> data) {
    return Question(
      pergunta: data['pergunta'] ?? '',
      url: data['url'] ?? '',
      alternativas: List<String>.from(data['alternativas'] ?? []),
      correta: data['correta'] ?? 0,
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Personalizado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 87, 107, 255),
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      home: QuizPage(),
    );
  }
}

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Question> questions = [];
  int score = 0;
  int? selectedAnswer;
  int currentQuestionIndex = 0;

  bool showFeedback = false;

  bool isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    _resetScore();
    _getQuestions();
  }

  Future<void> _resetScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = 0;
      currentQuestionIndex = 0;
    });
    await prefs.setInt('score', 0);
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', score);
  }

  Future<void> _getQuestions() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref('questions');
      DatabaseEvent event = await ref.once();
      List<Question> loadedQuestions = [];
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          loadedQuestions.add(Question.fromMap(value));
        });
      }
      setState(() {
        questions = loadedQuestions;
      });
    } catch (error, stackTrace) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
      print("Erro ao carregar as perguntas: $error");
    }
  }

  void _onAnswerSelected(int index) {
    if (!showFeedback) {
      setState(() {
        selectedAnswer = index;
      });
    }
  }

  void _validateAnswer() {
    if (selectedAnswer != null) {
      setState(() {
        showFeedback = true;
        isButtonDisabled = true;
        if (selectedAnswer == questions[currentQuestionIndex].correta) {
          score++;
        }
      });
      Future.delayed(Duration(seconds: 2), () {
        _advanceQuestion();
        setState(() {
          isButtonDisabled = false;
        });
      });
    }
  }

  void _advanceQuestion() {
    _saveScore();
    setState(() {
      showFeedback = false;
      selectedAnswer = null;
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FinalPage(score: score, total: questions.length),
          ),
        );
      }
    });
  }

  Color _getOptionColor(int index, Question currentQuestion) {
    if (!showFeedback) {
      return Theme.of(context).cardTheme.color ?? Colors.white.withOpacity(0.2);
    } else {
      if (index == currentQuestion.correta) {
        return Colors.green.withOpacity(0.8);
      }
      if (index == selectedAnswer &&
          selectedAnswer != currentQuestion.correta) {
        return Colors.red.withOpacity(0.8);
      }
    }
    return Theme.of(context).cardTheme.color ?? Colors.white.withOpacity(0.2);
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz Personalizado')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Question currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Quiz - Placar: $score')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 127, 161, 255),
              Color(0xFF5C6BC0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Card(
              color: Theme.of(context).cardTheme.color,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  currentQuestion.pergunta,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SizedBox(height: 10),
            Image.network(
              currentQuestion.url,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Text(
                    'Erro ao carregar imagem.',
                    style: TextStyle(color: Colors.black),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Column(
              children: List.generate(currentQuestion.alternativas.length, (
                index,
              ) {
                return Card(
                  color: _getOptionColor(index, currentQuestion),
                  child: InkWell(
                    onTap: () => _onAnswerSelected(index),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      title: Text(
                        currentQuestion.alternativas[index],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      leading: Radio<int>(
                        activeColor: Colors.indigo,
                        value: index,
                        groupValue: selectedAnswer,
                        onChanged: (int? value) {
                          if (value != null) {
                            _onAnswerSelected(value);
                          }
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: !isButtonDisabled && selectedAnswer != null
                    ? _validateAnswer
                    : null,
                child: Text('Próxima Pergunta', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinalPage extends StatelessWidget {
  final int score;
  final int total;

  const FinalPage({Key? key, required this.score, required this.total})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Resultado do Quiz'), centerTitle: true),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 146, 124, 255),
              Color.fromARGB(255, 79, 105, 255),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Parabéns, você acertou $score de $total questões!',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => QuizPage()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Reiniciar Quiz',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
