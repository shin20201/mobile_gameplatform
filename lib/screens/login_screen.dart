import 'package:flutter/material.dart';

import '../services/auth_service.dart';

// 같은 입력 폼을 로그인과 회원가입에서 함께 사용합니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.isSignup = false});
  final bool isSignup;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      if (widget.isSignup) {
        await AuthService.signup(_nickname.text, _email.text, _password.text);
        if (mounted) Navigator.of(context).pop();
      } else {
        await AuthService.login(_email.text, _password.text);
      }
    } catch (error) {
      if (mounted) setState(() => _error = AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSignup ? '회원가입' : '로그인';
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text('Game Platform', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    if (widget.isSignup) ...[
                      TextFormField(
                        controller: _nickname, enabled: !_busy,
                        decoration: const InputDecoration(labelText: '닉네임', border: OutlineInputBorder()),
                        maxLength: 20,
                        textInputAction: TextInputAction.next,
                        validator: (value) => (value ?? '').trim().isEmpty ? '닉네임을 입력해 주세요.' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _email, enabled: !_busy,
                      decoration: const InputDecoration(labelText: '이메일', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim()) ? null : '올바른 이메일을 입력해 주세요.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password, enabled: !_busy, obscureText: true,
                      decoration: const InputDecoration(labelText: '비밀번호', border: OutlineInputBorder()),
                      enableSuggestions: false, autocorrect: false,
                      textInputAction: widget.isSignup ? TextInputAction.next : TextInputAction.done,
                      onFieldSubmitted: (_) { if (!widget.isSignup) _submit(); },
                      validator: (value) {
                        if (value == null || value.isEmpty) return '비밀번호를 입력해 주세요.';
                        if (widget.isSignup && value.length < 6) return '비밀번호는 6자 이상 입력해 주세요.';
                        return null;
                      },
                    ),
                    if (widget.isSignup) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmation, enabled: !_busy, obscureText: true,
                        decoration: const InputDecoration(labelText: '비밀번호 확인', border: OutlineInputBorder()),
                        enableSuggestions: false, autocorrect: false,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) => value != _password.text ? '비밀번호가 일치하지 않습니다.' : null,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(title),
                    ),
                    if (!widget.isSignup)
                      TextButton(
                        onPressed: _busy ? null : () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LoginScreen(isSignup: true))),
                        child: const Text('계정이 없으신가요? 회원가입'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
