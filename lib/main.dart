import 'package:firebase_core/firebase_core.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:flutter_application_1/register_page.dart';
import 'package:flutter_application_1/welcome-page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlameAudio.bgm.initialize();
  runApp(MyApp());
  FlameAudio.bgm.play('jazz-happy.mp3');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameStart(),
    );
  }
}

class GameStart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WelcomePage(
      onStartGame: () {
        navigateToHomePage(context);
      },
      onLogin: () {
        navigateToLoginPage(context);
      },
      onRegister: () {
        navigateToRegisterPage(context);
      },
    );
  }

  void navigateToHomePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage(level: 1)),
    );
  }

  void navigateToLoginPage(BuildContext context) {
    // Implement navigation to the login page
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void navigateToRegisterPage(BuildContext context) {
    // Implement navigation to the register page
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => RegisterPage()));
  }
}

void navigateToHomePage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => HomePage(level: 1)),
  );
}
