import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_allergy/bloc/auth/auth_cubit.dart';
import 'package:safe_allergy/pages/nfc_write_page.dart';
import 'package:safe_allergy/widgets/error_dialog.dart';
import 'package:safe_allergy/widgets/loading_indicator.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Authorization',
            style: TextStyle(
              color: Color(0xFF2E658F),
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthorized) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const NfcWritePage()),
              );
            } else if (state is AuthUnauthorized) {
              ErrorDialog.show(context, 'Authorization Failed', state.message);
            } else if (state is AuthError) {
              ErrorDialog.show(context, 'Error', state.message);
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const LoadingIndicator(
                message: 'Verifying authorization...',
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/ver.png', height: 200),
                      const SizedBox(height: 24),
                      Text(
                        'Write Access Required',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E658F),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please enter your authorized email address',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 50),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'nurse@hospital.com',
                          prefixIcon: Icon(
                            Icons.email,
                            color: Color.fromARGB(255, 110, 110, 110),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthCubit>().checkAuthorization(
                                _emailController.text.trim(),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Color(0xFF2E658F),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Verify Authorization',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
