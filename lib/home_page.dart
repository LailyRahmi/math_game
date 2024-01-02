import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/const.dart';
import 'package:flutter_application_1/controller/auth.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/util/my_button.dart';
import 'package:flutter_application_1/util/result_message.dart';

class HomePage extends StatefulWidget {
  final int level;

  const HomePage({Key? key, required this.level}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController authController = AuthController();

  int score = 0;
  int numberA = 0;
  int numberB = 0;
  String userAnswer = '';
  int level = 1;
  int correctAnswersInARow = 0;
  int wrongAttempts = 0;

  List<String> numberPad = [
    '7',
    '8',
    '9',
    'C',
    '4',
    '5',
    '6',
    'DEL',
    '1',
    '2',
    '3',
    'OK',
    ',',
    '0',
    '.',
    '-',
  ];

  var randomNumber = Random();

  @override
  void initState() {
    super.initState();
    // Inisialisasi levelOperators dengan operator untuk setiap level hingga level 15
    for (int i = 1; i <= 15; i++) {
      if (levelOperators[i] == null) {
        levelOperators[i] = _getMathOperator(i);
      }
    }

    print('Level Operators: $levelOperators');
    generateNewQuestion();
  }

  // Fungsi untuk mendapatkan operator matematika berdasarkan level
  String _getMathOperator(int level) {
    if (level <= 15) {
      return levelOperators[level] ?? ' '; // Ambil operator dari map
    } else {
      // Jika level melebihi 15, gunakan operator acak tetapkan ke level > 15
      if (levelOperators.containsKey(level)) {
        return levelOperators[level]!;
      } else {
        List<String> operators = [' + ', ' - ', ' x '];
        int randomIndex = Random().nextInt(operators.length);
        levelOperators[level] = operators[randomIndex];
        return operators[randomIndex];
      }
    }
  }

  void buttonTapped(String button) {
    setState(() {
      if (button == 'OK') {
        checkResult();
      } else if (button == 'C') {
        userAnswer = '';
      } else if (button == 'DEL') {
        if (userAnswer.isNotEmpty) {
          userAnswer = userAnswer.substring(0, userAnswer.length - 1);
        }
      } else if (button == '-') {
        if (userAnswer.isEmpty) {
          userAnswer += '-';
        }
      } else if (button == ',') {
        if (!userAnswer.contains(',')) {
          userAnswer += ',';
        }
      } else if (button == '.' ||
          button == '0' ||
          button == '1' ||
          button == '2' ||
          button == '3' ||
          button == '4' ||
          button == '5' ||
          button == '6' ||
          button == '7' ||
          button == '8' ||
          button == '9') {
        userAnswer += button;
      }
    });
  }

  void checkResult() {
    double? userAnswerDouble = double.tryParse(userAnswer);
    bool isCorrect = false;
    String message = '';
    IconData icon = Icons.error;
    double epsilon = 0.0001;

    if (userAnswerDouble != null) {
      if (level <= 15) {
        // Perhitungan hasil untuk level <= 15
        switch (level) {
          case 1:
          case 2:
          case 3:
          case 4:
          case 5:
            isCorrect =
                ((numberA + numberB - userAnswerDouble).abs() < epsilon);
            break;
          case 6:
          case 7:
          case 8:
          case 9:
          case 10:
            isCorrect =
                ((numberA - numberB - userAnswerDouble).abs() < epsilon);
            break;
          case 11:
          case 12:
          case 13:
          case 14:
          case 15:
            isCorrect =
                ((numberA * numberB - userAnswerDouble).abs() < epsilon);
            break;
          default:
            break;
        }
      } else {
        // Perhitungan hasil untuk level > 15
        String operator = _getMathOperator(level);
        switch (operator.trim()) {
          case '+':
            isCorrect =
                ((numberA + numberB - userAnswerDouble).abs() < epsilon);
            break;
          case '-':
            isCorrect =
                ((numberA - numberB - userAnswerDouble).abs() < epsilon);
            break;
          case 'x':
            isCorrect =
                ((numberA * numberB - userAnswerDouble).abs() < epsilon);
            break;
          default:
            break;
        }
      }

      // Menampilkan pesan berdasarkan kebenaran jawaban
      if (isCorrect) {
        message = 'Correct!';
        icon = Icons.check;
        correctAnswersInARow++;

        if (correctAnswersInARow >= 5) {
          level++;
          correctAnswersInARow = 0;
          message = 'Level $level Unlocked!';
        }

        score += 10;
        // Update the score in Firestore
        updateScoreInFirestore();

        generateNewQuestion();
        setState(() {
          // Memastikan variabel level diperbarui setelah level naik
          level = level;
        });
        FlameAudio.bgm.pause();
        FlameAudio.play('success-1.mp3');
      } else {
        message = 'Sorry, try again.';
        FlameAudio.bgm.pause();
        FlameAudio.play('negative.mp3');
      }

      if (!isCorrect) {
        wrongAttempts++;

        if (wrongAttempts >= 3) {
          showDialog(
            context: context,
            builder: (context) {
              return ResultMessage(
                message: 'Game Over!',
                onTap: () {
                  setState(() {
                    level = 1;
                    score = 0;
                    wrongAttempts = 0;
                  });
                  FlameAudio.bgm.resume();
                  generateNewQuestion();
                  Navigator.pop(context);
                },
                icon: Icons.replay,
              );
            },
          );
          return;
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return ResultMessage(
            message: message,
            onTap: () {
              FlameAudio.bgm.resume();
              goToNextQuestion();
            },
            icon: icon,
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Invalid Answer'),
            content: Text('Please enter a valid number.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void updateScoreInFirestore() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      if (user != null) {
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Use the correct collection and document references
        CollectionReference users = firestore.collection('score');
        DocumentReference userDoc = users.doc(user.uid);

        // Check if the document exists
        if (!(await userDoc.get()).exists) {
          // If the document doesn't exist, create a new one
          await userDoc.set({'score': 0});
        }

        // Update the user's score in Firestore
        await userDoc.update({
          'score': score,
        });
      }
    } catch (e) {
      print('Error updating score: $e');
    }
  }

  Map<int, String> levelOperators = {
    1: ' + ',
    2: ' + ',
    3: ' + ',
    4: ' + ',
    5: ' + ',
    6: ' - ',
    7: ' - ',
    8: ' - ',
    9: ' - ',
    10: ' - ',
    11: ' x ',
    12: ' x ',
    13: ' x ',
    14: ' x ',
    15: ' x ',
  };

// Fungsi untuk menghasilkan pertanyaan matematika baru
  void generateNewQuestion() {
    setState(() {
      userAnswer = '';
      int range = level * 10;

      if (level <= 5) {
        numberA = randomNumber.nextInt(range);
        numberB = randomNumber.nextInt(range);
      } else if (level <= 10) {
        numberA = randomNumber.nextInt(range);
        numberB = randomNumber.nextInt(range);
        if (Random().nextInt(2) == 1) {
          numberA += numberB;
          numberB = numberA - numberB;
          numberA -= numberB;
        }
      } else if (level <= 15) {
        numberA = randomNumber.nextInt(range);
        numberB = randomNumber.nextInt(range);
        if (Random().nextInt(3) == 1) {
          numberA = randomNumber.nextInt(10);
          numberB = randomNumber.nextInt(10);
        }
      } else {
        numberA = randomNumber.nextInt(range);
        numberB = randomNumber.nextInt(range);
        if (Random().nextInt(4) == 1) {
          int divisor = randomNumber.nextInt(9) + 1;
          numberA = divisor * randomNumber.nextInt(10);
          numberB = divisor;
        }
      }

      // Mendapatkan operator berdasarkan level
      String operator = _getMathOperator(level);

      // Menampilkan pertanyaan ke pengguna
      String mathQuestion =
          '$numberA $operator $numberB = ?'; // Format pertanyaan
      print(
          'Math Question: $mathQuestion'); // Tampilkan pertanyaan di konsol atau sesuaikan dengan kebutuhan UI Anda.
    });
  }

  void goToNextQuestion() {
    Navigator.of(context).pop();

    setState(() {
      userAnswer = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[100],
      appBar: AppBar(
        title: Center(
          child: Text(
            'MathSum Quest',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.indigo[300],
        actions: [
          IconButton(
            onPressed: () {
              authController.logoutUser();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => GameStart()),
              );
            },
            icon: Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$numberA ${_getMathOperator(level)} $numberB = ',
                      style: whiteTextStyle,
                    ),
                    Container(
                      height: 50,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.indigo[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          userAnswer,
                          style: whiteTextStyle,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: GridView.builder(
                itemCount: numberPad.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemBuilder: (context, index) {
                  return MyButton(
                    child: numberPad[index],
                    onTap: () => buttonTapped(numberPad[index]),
                  );
                },
              ),
            ),
          ),

          // Display the score
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.indigo[200],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              'Score: $score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
