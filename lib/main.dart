import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
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

class LeaderboardEntry {
  final String name;
  final int score;
  final DateTime date;

  LeaderboardEntry({
    required this.name,
    required this.score,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'date': date.toIso8601String(),
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['name'] as String,
      score: json['score'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

const _kLeaderboardKey = 'leaderboard_entries';

Future<List<LeaderboardEntry>> loadLeaderboard() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_kLeaderboardKey);
  if (raw == null) return [];
  final list = raw
      .map((s) => LeaderboardEntry.fromJson(json.decode(s)))
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return list;
}

Future<void> addToLeaderboard(String name, int score) async {
  final prefs = await SharedPreferences.getInstance();
  final entries = await loadLeaderboard();
  entries.add(LeaderboardEntry(name: name, score: score, date: DateTime.now()));
  entries.sort((a, b) => b.score.compareTo(a.score));
  final top10 = entries.take(10).toList();
  final encoded = top10.map((e) => json.encode(e.toJson())).toList();
  await prefs.setStringList(_kLeaderboardKey, encoded);
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
  String playerName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPlayerName());
    _resetScore();
    _getQuestions();
  }

    Future<void> _askPlayerName() async {
    String tempName = '';
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Digite seu nome.'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: 'Digite aqui'),
          onChanged: (v) => tempName = v,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, tempName.trim()),
            child: Text('OK'),
          ),
        ],
      ),
    );

    if (name == null) {
      return _askPlayerName();
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Nome inválido'),
          content: Text('Por favor, informe um nome válido para continuar.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return _askPlayerName();
    }

    if (trimmed.toLowerCase() == 'seu nome') {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('SEU COMÉDIA!'),
          content: Text(
            'ESSE É UM QUIZ SÉRIO, E VOCÊ FICA BRINCANDO DIGITANDO "SEU NOME" NO CAMPO "SEU NOME"?',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return _askPlayerName();
    }

    setState(() {
      playerName = trimmed;
    });
  }
Future<void> _resetScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      score = 0;
      currentQuestionIndex = 0;
      selectedAnswer = null;
    });
    await prefs.setInt('score', 0);
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', score);
  }

  Future<void> _getQuestions() async {
    try {
      final ref = FirebaseDatabase.instance.ref('questions');
      final event = await ref.once();
      final loaded = <Question>[];
      if (event.snapshot.value != null) {
        final values = event.snapshot.value as Map<dynamic, dynamic>;
        values.forEach((_, v) => loaded.add(Question.fromMap(v)));
      }
      setState(() => questions = loaded);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      print('Erro ao carregar perguntas: \$e');
    }
  }

  void _onAnswerSelected(int index) {
    if (!showFeedback) setState(() => selectedAnswer = index);
  }

  void _validateAnswer() {
    if (selectedAnswer == null) return;
    setState(() {
      showFeedback = true;
      isButtonDisabled = true;
      if (selectedAnswer == questions[currentQuestionIndex].correta) score++;
    });
    Future.delayed(Duration(seconds: 2), () async {
      await _advanceQuestion();
      setState(() => isButtonDisabled = false);
    });
  }

  Future<void> _advanceQuestion() async {
    await _saveScore();
    if (currentQuestionIndex >= questions.length - 1) {
      await addToLeaderboard(playerName, score);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => FinalPage(score: score, total: questions.length)),
      );
      return;
    }
    setState(() {
      showFeedback = false;
      selectedAnswer = null;
      currentQuestionIndex++;  
    });
  }

  Color _getOptionColor(int i, Question q) {
    if (!showFeedback) return Theme.of(context).cardTheme.color!;
    if (i == q.correta) return Colors.green.withOpacity(0.8);
    if (i == selectedAnswer && selectedAnswer != q.correta) return Colors.red.withOpacity(0.8);
    return Theme.of(context).cardTheme.color!;
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz Personalizado')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final q = questions[currentQuestionIndex];
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Quiz - Placar: $score')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 127, 161, 255), Color(0xFF5C6BC0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).cardTheme.color,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(q.pergunta, style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SizedBox(height: 10),
            Image.network(q.url, height: 200, errorBuilder: (_, __, ___) {
              return Container(
                height: 200,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: Text('Erro ao carregar imagem.', style: TextStyle(color: Colors.black)),
              );
            }),
            SizedBox(height: 20),
            ...List.generate(q.alternativas.length, (i) {
              return Card(
                color: _getOptionColor(i, q),
                child: InkWell(
                  onTap: () => _onAnswerSelected(i),
                  child: ListTile(
                    leading: Radio<int>(
                      activeColor: Colors.indigo,
                      value: i,
                      groupValue: selectedAnswer,
                      onChanged: (_) => _onAnswerSelected(i),
                    ),
                    title: Text(q.alternativas[i], style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              );
            }),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: !isButtonDisabled && selectedAnswer != null ? _validateAnswer : null,
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
  const FinalPage({Key? key, required this.score, required this.total}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('Resultado do Quiz'), centerTitle: true),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 146, 124, 255), Color.fromARGB(255, 79, 105, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Card(
              color: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Parabéns, você acertou $score de $total!',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => QuizPage()),
                        );
                      },
                      child: Text('Reiniciar Quiz', style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LeaderboardPage()),
                        );
                      },
                      child: Text('Ver Ranking', style: TextStyle(color: Colors.white)),
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

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<LeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ranking Local'), centerTitle: true),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final entries = snap.data ?? [];
          if (entries.isEmpty) {
            return Center(child: Text('Nenhuma pontuação registrada.'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white30),
            itemBuilder: (_, i) {
              final e = entries[i];
              return ListTile(
                leading: Text('#${i + 1}', style: TextStyle(color: Colors.black, fontSize: 18)),
                title: Text(e.name, style: TextStyle(color: Colors.black, fontSize: 18)),
                trailing: Text('${e.score}', style: TextStyle(color: Colors.black, fontSize: 18)),
                subtitle: Text(
                  e.date.toLocal().toString().split('.').first,
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}