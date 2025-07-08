// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/auth_repository.dart'; // Import repository
import '../models/user.dart';
import '../utils/api_exceptions.dart'; // Import exceptions

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Get the AuthRepository from Provider
        final authRepo = Provider.of<AuthRepository>(context, listen: false);
        // Call the login method
        User user = await authRepo.login(
          _loginController.text,
          _passwordController.text,
          deviceName: 'FlutterApp', // Optional device name
        );

        // Login successful, navigate to home or dashboard based on user type
        // You would implement navigation logic based on user.userType
        print('Login successful! User type: ${user.userType}');

        // Example: Navigate to HomeScreen
        Navigator.pushReplacementNamed(context, '/home');


      } on ValidationException catch (e) {
         // Handle validation errors (e.g., display under fields)
         print('Validation Error: ${e.errors}');
         setState(() {
           _errorMessage = e.message; // Or process e.errors to show field-specific errors
         });
      } on ApiException catch (e) {
        // Handle other API errors (401, 403, 404, 409, 500 etc.)
        print('API Error: ${e.statusCode} - ${e.message}');
        setState(() {
          _errorMessage = e.message;
        });
      } on NetworkException catch (e) {
         // Handle network connectivity errors
         print('Network Error: ${e.message}');
         setState(() {
           _errorMessage = e.message;
         });
      } catch (e) {
        // Handle any other unexpected errors
        print('Unexpected Error: ${e.toString()}');
         setState(() {
           _errorMessage = 'An unexpected error occurred.';
         });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(labelText: 'Email or Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email or username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
              // Basic Register Button
              TextButton(
                onPressed: () {
                   // Navigate to Register Screen (you'd create this)
                   // Navigator.pushNamed(context, '/register');
                },
                child: const Text('Don\'t have an account? Register'),
              ),
              // Quick Login Button for testing
              ElevatedButton(
                onPressed: () {
                  _loginController.text = 'tourist1@app.com';
                  _passwordController.text = 'password';
                  _login();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // A different color to distinguish
                ),
                child: const Text('Quick Login (Test)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}