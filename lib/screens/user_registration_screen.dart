import 'package:flutter/material.dart';

import '../services/user_registration_service.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({
    super.key,
    required this.userId,
    required this.registrationService,
    required this.nextScreenBuilder,
  });

  final String userId;
  final UserRegistrationService registrationService;
  final WidgetBuilder nextScreenBuilder;

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.registrationService.registerUser(
        userId: widget.userId,
        name: _nameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(builder: widget.nextScreenBuilder),
      );
    } on UserRegistrationException catch (error) {
      if (!mounted) return;
      final message = error.code == 'INVALID_REQUEST'
          ? error.message
          : '利用者登録に失敗しました。時間をおいて再度お試しください。';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通信に失敗しました。時間をおいて再度お試しください。')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用者登録')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'お名前を入力してください',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('登録した情報は避難支援のために利用します。'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                enabled: !_isSubmitting,
                maxLength: 100,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '名前',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '名前を入力してください'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('登録して次へ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
