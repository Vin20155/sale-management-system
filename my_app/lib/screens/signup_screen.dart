import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _keyForm = GlobalKey<FormState>();
  final txtfulllname = TextEditingController();
  final txtemail = TextEditingController();
  final txtpassword = TextEditingController();
  final txtconfirmpassword = TextEditingController();

  Future<void> signUp() async {
    try {
      EasyLoading.show();
      await Future.delayed(const Duration(seconds: 2));

      // Sign Up user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: txtemail.text.trim(), 
              password: txtpassword.text.trim());

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Save user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
            'user id': userCredential.user?.uid,
            'fulllname': txtfulllname.text.trim(),
            'email': txtemail.text.trim(),
            'is active': true,
            'created at': FieldValue.serverTimestamp(),
          });

      EasyLoading.showSuccess('Sign Up successful! Please check your email for verification.');

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (ex) {
      EasyLoading.showError('Error: ${ex.message}');
    } finally {
      EasyLoading.dismiss();
    }
      
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up User'),),
      body: Form(
      key: _keyForm,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 35),
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.bgColor,
              child: Icon(Icons.person, size: 50, color: AppColors.white),
            ),
            const SizedBox(height: 50),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required full name!';
                }
                return null;
              },
              controller: txtfulllname,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),
             TextFormField(
              validator: (value) {
                final emailRegExp = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );

                if (value == null || value.isEmpty) {
                  return 'Required email!';
                }
                if (!emailRegExp.hasMatch(value.trim())) {
                  return 'Invalid email format!';
                }
                return null;
              },
              controller: txtemail,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),
             TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required password!';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters long!';
                }
                return null;
              },
              controller: txtpassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: Icon(Icons.visibility_rounded),
              ),
            ),
            const SizedBox(height: 15),
             TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required confirm password!';
                }
                if (value != txtpassword.text.trim()) {
                  return 'Passwords do not match!';
                }
                return null;
              },
              controller: txtconfirmpassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: Icon(Icons.visibility_rounded),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: AppColors.bgColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ),
              onPressed: () {
                if (_keyForm.currentState!.validate()) {
                  signUp();
                }
              }, // Add your sign-up logic here
              child:  const Text('Sign Up', style: TextStyle(color: AppColors.white, fontSize: 18),),
            )
          ],
        ),
      ),
    
            
      ),
    );
    
    

          
  }
}
            
    