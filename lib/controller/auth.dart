import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method untuk login
  Future<bool> loginUser(String email, String password) async {
    try {
      // Melakukan login dengan Firebase Authentication
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true; // Mengembalikan nilai true jika login berhasil
    } catch (e) {
      print('Error during login: $e');
      return false; // Mengembalikan nilai false jika terjadi error saat login
    }
  }

  // Method untuk registrasi
  Future<bool> registerUser(String email, String password) async {
    try {
      // Melakukan registrasi dengan Firebase Authentication
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true; // Mengembalikan nilai true jika registrasi berhasil
    } catch (e) {
      print('Error during registration: $e');
      return false; // Mengembalikan nilai false jika terjadi error saat registrasi
    }
  }

  // Method untuk logout
  Future<void> logoutUser() async {
    await _auth.signOut();
  }
}
