import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:teencu/home.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpState();
}

class _SignUpState extends State<SignUpPage> {
  String? _email;
  String? _password;
  String? _cpassword;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 80),
            Text(
              "Create an\naccount",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            // Email TextField
            TextField(
              decoration: InputDecoration(
                hintText: "Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              onChanged: (value){
                setState((){
                  _email = value;
                });
              },
            ),
            SizedBox(height: 16),
            // Password TextField
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: Icon(Icons.lock),
                suffixIcon: Icon(Icons.visibility),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              onChanged: (value){
                setState((){
                  _password = value;
                });
              },
            ),
            SizedBox(height: 16),
            // Confirm Password TextField
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Confirm Password",
                prefixIcon: Icon(Icons.lock),
                suffixIcon: Icon(Icons.visibility),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              onChanged: (value){
                setState((){
                  _cpassword = value;
                });
              },
            ),
            SizedBox(height: 16),
            // Terms and conditions
            Text(
              "By clicking the Register button, you agree to the public offer",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            // Register Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_email != null && _password != null && _cpassword != null){
                    submitForm();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(500, 248,55,88),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Create Account",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 30),
            // Divider with text
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("- OR Continue with -"),
                ),
                Expanded(child: Divider(color: Colors.grey)),
              ],
            ),
            SizedBox(height: 20),
            // Social Media Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon("assets/icons/google.png"),
                SizedBox(width: 16),
                _buildSocialIcon("assets/icons/apple.png"),
                SizedBox(width: 16),
                _buildSocialIcon("assets/icons/facebook.png"),
              ],
            ),
            Spacer(),
            // Already Have an Account
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("I Already Have an Account "),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Navigate back to LoginPage
                  },
                  child: Text(
                    "Login",
                    style: TextStyle(color: Color.fromARGB(500, 248,55,88), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String assetPath) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[200],
      child: Image.asset(
        assetPath,
        height: 24,
        width: 24,
      ),
    );
  }

  String generateUsername() {
    const prefix = "user-";
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return prefix + List.generate(32, (index) => characters[random.nextInt(characters.length)]).join();
  }

  void submitForm() async {
    _email = _email?.trim();
    _password = _password?.trim();
    _cpassword = _cpassword?.trim();

    if (_password != _cpassword){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak sama dengan password yang dimasukkan.')),
      );
      return;
    }
    var emailQuery = await firestore
      .collection('users')
      .where('email', isEqualTo: _email)
      .get();
    if (emailQuery.docs.isNotEmpty){
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sudah terpakai, ganti email lain.')),
      );
      return;
    }
    UserCredential userCredential = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: _email!, password: _password!);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrasi Berhasil!')),
    );
    String uid = userCredential.user!.uid;
    await firestore.collection('users').doc(uid).set({
      'username': generateUsername(),
      'email': _email,
      'points': 0,
      'lastMbti': '',
      'lastMbtiDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
  }
}
