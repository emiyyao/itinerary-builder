import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalproj/auth_service.dart';
import 'package:finalproj/login_screen.dart';
import 'package:finalproj/home_screen.dart';
import 'package:finalproj/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Form( // Wrap your UI with a Form widget
          key: _formKey, // Assign the form key
          child: Column(
            children: [
              const Spacer(),
              const Text("Signup",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500)),
              const SizedBox(
                height: 50,
              ),
              CustomTextField(
                hint: "Enter Name",
                label: "Name",
                controller: _name,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                hint: "Enter Email",
                label: "Email",
                controller: _email,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                hint: "Enter Password",
                label: "Password",
                isPassword: true,
                controller: _password,
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: _signup,
                child: Text("Sign up"),
              ),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Already have an account? "),
                InkWell(
                  onTap: () => goToLogin(context),
                  child: const Text(
                      "Login", style: TextStyle(color: Colors.red)),
                )
              ]),
              const Spacer()
            ],
          ),
        ),
      ),
    );
  }

  goToLogin(BuildContext context) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

  goToHome(BuildContext context) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );

//   _signup() async {
//     // Check if the form is valid before proceeding
//     if (_formKey.currentState?.validate() ?? false) {
//       User? userCredential = await _auth.createUserWithEmailAndPassword(_email.text, _password.text);
//       FirebaseFirestore.instance.collection('users').doc(userCredential?.uid).set({
//         'displayName': _name.text,
//         'photoURL': "https://www.google.com/imgres?q=sky&imgurl=https%3A%2F%2Fupload.wikimedia.org%2Fwikipedia%2Fcommons%2Fthumb%2Fd%2Fd3%2FJuly_night_sky_%252835972569256%2529.jpg%2F1200px-July_night_sky_%252835972569256%2529.jpg&imgrefurl=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FSky&docid=YPXA7BoLczLIIM&tbnid=d_TX36ztPC4x6M&vet=12ahUKEwj80b6NldeFAxWSE1kFHUtZB_4QM3oFCIQBEAA..i&w=1200&h=800&hcb=2&ved=2ahUKEwj80b6NldeFAxWSE1kFHUtZB_4QM3oFCIQBEAA"
//       });
//       Navigator.pop(context);
//     }
//   }
// }

  _signup() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        User? userCredential = await _auth.createUserWithEmailAndPassword(
            _email.text, _password.text);
        FirebaseFirestore.instance.collection('users')
            .doc(userCredential?.uid)
            .set({
          'displayName': _name.text,
          'photoURL': "https://www.google.com/imgres?q=sky&imgurl=https%3A%2F%2Fupload.wikimedia.org%2Fwikipedia%2Fcommons%2Fthumb%2Fd%2Fd3%2FJuly_night_sky_%252835972569256%2529.jpg%2F1200px-July_night_sky_%252835972569256%2529.jpg&imgrefurl=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FSky&docid=YPXA7BoLczLIIM&tbnid=d_TX36ztPC4x6M&vet=12ahUKEwj80b6NldeFAxWSE1kFHUtZB_4QM3oFCIQBEAA..i&w=1200&h=800&hcb=2&ved=2ahUKEwj80b6NldeFAxWSE1kFHUtZB_4QM3oFCIQBEAA"
        });
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$e"),
          duration: Duration(seconds: 3), // Adjust duration as needed
        ),
      );
    }
  }
}
