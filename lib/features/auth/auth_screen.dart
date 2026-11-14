import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../domain/task.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});
  final FirebaseAuth auth;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _name = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;
  String? _message;
  Future<void> _submit({bool reset = false}) async {
    FocusScope.of(context).unfocus();
    if (reset) {
      final error = validateEmail(_email.text);
      if (error != null) {
        setState(() => _message = error);
        return;
      }
    } else if (!_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (reset) {
        await widget.auth.sendPasswordResetEmail(email: _email.text.trim());
        if (mounted) {
          setState(
            () => _message = 'Si el correo está registrado, recibirás un enlace para recuperar tu contraseña.',
          );
        }
      } else if (_register) {
        final credential = await widget.auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        await credential.user?.updateDisplayName(_name.text.trim());
      } else {
        await widget.auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _message = readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              Text(
                'enfoque',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/escritorio.jpg',
                  height: 180,
                  fit: BoxFit.cover,
                  semanticLabel: 'Espacio de trabajo con luz natural',
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _register
                    ? 'Un lugar para tus planes.'
                    : 'Haz espacio para lo importante.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                _register
                    ? 'Crea tu cuenta y organiza tu primera tarea.'
                    : 'Tus tareas, tus tiempos. Todo en un mismo lugar.',
              ),
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    children: [
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Tu nombre',
                          ),
                          textCapitalization: TextCapitalization.words,
                          maxLength: 60,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Escribe tu nombre.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: [
                          _register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _register
                            ? validatePassword
                            : (v) => v == null || v.isEmpty
                                  ? 'Escribe tu contraseña.'
                                  : null,
                        onFieldSubmitted: (_) {
                          if (!_busy) _submit();
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(_message!, semanticsLabel: _message),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : () => _submit(),
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_register ? 'Crear cuenta' : 'Entrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _register = !_register;
                        _message = null;
                      }),
                child: Text(
                  _register ? 'Ya tengo una cuenta' : 'Crear una cuenta',
                ),
              ),
              if (!_register)
                TextButton(
                  onPressed: _busy ? null : () => _submit(reset: true),
                  child: const Text('Olvidé mi contraseña'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
