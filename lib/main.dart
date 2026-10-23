import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb){
    await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: "AIzaSyDucwHqIIOOCKDg3qpLjtCw1-8OfREnu4Q",
      authDomain: "teencu.firebaseapp.com",
      projectId: "teencu",
      storageBucket: "teencu.firebasestorage.app",
      messagingSenderId: "341428856100",
      appId: "1:341428856100:web:fd44031df060ccc7afffb1",
      measurementId: "G-EYCBERYH7Z"
    ));
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      // Ganti dengan halaman berikutnya setelah splash screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC0CB), // Pink background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/teencu_icon.png',
              height: 250, // Sesuaikan ukuran sesuai kebutuhan
            ),
            Image.asset(
              'assets/teencu_logo.png',
              height: 250, // Sesuaikan ukuran sesuai kebutuhan
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      body: const Center(
        child: Text("Welcome to Teencu!"),
      ),
    );
  }
}
