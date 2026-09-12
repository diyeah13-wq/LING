import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learner_provider.dart';
import '../../models/learning_goal.dart';
import '../../models/skill_level.dart';
import '../../widgets/common/lingo_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.isSignUp});
  final bool isSignUp;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      final auth = ref.read(authServiceProvider);
      if (widget.isSignUp) {
        await auth.signUp(name: _name.text, email: _email.text, password: _password.text);
        await ref.read(learnerStateProvider.notifier).setProfile(
          name: _name.text.trim(),
          goal: LearningGoal.justLearning,
          level: SkillLevel.beginner,
        );
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFor(error))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use': return 'An account already exists with that email.';
      case 'invalid-credential': return 'Incorrect email or password.';
      case 'weak-password': return 'Use a password with at least 6 characters.';
      case 'invalid-email': return 'Enter a valid email address.';
      default: return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUp = widget.isSignUp;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LingoSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.sign_language, color: LingoColors.primary, size: 64),
                  const SizedBox(height: LingoSpacing.lg),
                  Text(signUp ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: LingoSpacing.sm),
                  Text(signUp ? 'Start your ASL learning journey.' : 'Continue learning ASL.',
                      textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: LingoSpacing.xl),
                  if (signUp) ...[
                    TextFormField(controller: _name, textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null),
                    const SizedBox(height: LingoSpacing.md),
                  ],
                  TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null),
                  const SizedBox(height: LingoSpacing.md),
                  TextFormField(controller: _password, obscureText: _obscure,
                    decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure))),
                    validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters' : null),
                  const SizedBox(height: LingoSpacing.xl),
                  LingoButton(label: _submitting ? 'Please wait…' : signUp ? 'Sign up' : 'Log in',
                    onPressed: _submitting ? null : _submit),
                  TextButton(
                    onPressed: _submitting ? null : () => context.go(signUp ? '/login' : '/signup'),
                    child: Text(signUp ? 'Already have an account? Log in' : 'New to LINGO? Sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
