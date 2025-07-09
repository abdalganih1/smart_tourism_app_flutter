import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/screens/login_screen.dart';
import 'package:smart_tourism_app/screens/main_screen.dart';
import '../repositories/auth_repository.dart';
import '../utils/api_exceptions.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _fatherNameController = TextEditingController(); // <-- New Controller
  final _motherNameController = TextEditingController(); // <-- New Controller
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _fatherNameController.dispose(); // <-- Dispose Controller
    _motherNameController.dispose(); // <-- Dispose Controller
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      await authRepo.register({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'father_name': _fatherNameController.text, // <-- Add father_name
        'mother_name': _motherNameController.text, // <-- Add mother_name
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'password_confirmation': _confirmPasswordController.text, // <-- FIX: Add password_confirmation
        'user_type': 'Tourist',
        'device_name': 'mobile_app',
      });

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
      }
    } on ValidationException catch (e) {
      _showErrorDialog(e.message ?? 'An error occurred.');
    } on ApiException catch (e) {
      _showErrorDialog(e.message ?? 'An error occurred.');
    } catch (error) {
      _showErrorDialog('Could not authenticate you. Please try again later.');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registration Failed!'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF005B96).withOpacity(0.9),
                  const Color(0xFF03396C).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Join us to explore Syria!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _firstNameController,
                                  labelText: 'First Name',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value!.isEmpty) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _lastNameController,
                                  labelText: 'Last Name',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value!.isEmpty) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _fatherNameController,
                                  labelText: 'Father\'s Name',
                                  icon: Icons.person_outline,
                                   validator: (value) {
                                    if (value!.isEmpty) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _motherNameController,
                                  labelText: 'Mother\'s Name',
                                  icon: Icons.person_outline,
                                   validator: (value) {
                                    if (value!.isEmpty) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextFormField(
                            controller: _usernameController,
                            labelText: 'Username',
                            icon: Icons.account_circle_outlined,
                            validator: (value) {
                              if (value!.isEmpty || value.length < 4) {
                                return 'At least 4 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildTextFormField(
                            controller: _emailController,
                            labelText: 'E-Mail',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value!.isEmpty || !value.contains('@')) {
                                return 'Invalid email!';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildTextFormField(
                            controller: _passwordController,
                            labelText: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value!.isEmpty || value.length < 8) {
                                return 'Password is too short!';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildTextFormField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                             suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match!';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                backgroundColor: const Color(0xFF005B96),
                              ),
                              child: const Text(
                                'REGISTER',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(color: Colors.white70),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
                    },
                  ),
                   const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: const Color(0xFF005B96)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(width: 1, color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(width: 2, color: Color(0xFF005B96)),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}
