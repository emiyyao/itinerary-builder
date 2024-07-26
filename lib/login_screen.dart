
import 'package:finalproj/auth_service.dart';
import 'package:finalproj/signup_screen.dart';
import 'package:finalproj/textfield.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();

  bool isLoading = false;

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const Spacer(),
            const Text("Login",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500)),
            const SizedBox(height: 50),
            CustomTextField(
              hint: "Enter Email",
              label: "Email",
              controller: _email,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Password",
              label: "Password",
              controller: _password,
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: _login,
              child: Text("Login"),
            ),
            SizedBox(height: 5,),
            isLoading
                ? const CircularProgressIndicator()
                :TextButton(onPressed: () async {
                  setState(() {
                    isLoading = true;
                  });
                  await _auth.loginWithGoogle();
                  setState(() {
                    isLoading = false;
                  });
                }, child: Text("Sign in with Google")),

            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Don't already have an account? "),
              InkWell(
                onTap: () => goToSignup(context),
                child:
                const Text("Sign up", style: TextStyle(color: Colors.red)),
              )
            ]),
            const Spacer()
          ],
        ),
      ),
    );
  }

  goToSignup(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SignupScreen()),
  );

  _login() async {
    try {
      await _auth.loginUserWithEmailAndPassword(_email.text, _password.text);
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