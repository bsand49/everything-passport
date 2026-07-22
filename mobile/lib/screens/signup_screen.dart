import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const emailFieldKey = Key('signUpEmailField');
  static const passwordFieldKey = Key('signUpPasswordField');
  static const confirmPasswordFieldKey = Key('signUpConfirmPasswordField');
  static const signUpButtonKey = Key('signUpButton');

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController
            .text, // Don't trim passwords as spaces can be intentional
      );
      if (mounted) {
        Navigator.pop(context); // Go back to login or let wrapper handle it
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              AuthTextField(
                fieldKey: SignUpScreen.emailFieldKey,
                controller: _emailController,
                labelText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                fieldKey: SignUpScreen.passwordFieldKey,
                controller: _passwordController,
                labelText: 'Password',
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                fieldKey: SignUpScreen.confirmPasswordFieldKey,
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                prefixIcon: Icons.lock_clock,
                obscureText: true,
                validator: (value) => Validators.validateConfirmPassword(
                    value, _passwordController.text),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                key: SignUpScreen.signUpButtonKey,
                onPressed: _signUp,
                isLoading: _isLoading,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
