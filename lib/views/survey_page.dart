import 'package:flutter/material.dart';

class SurveyPage extends StatelessWidget {
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('初回アンケート'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('基本情報'),

              _buildPlaceholder('年齢区分入力領域'),
              _buildPlaceholder('性別入力領域'),
              _buildPlaceholder('世帯人数入力領域'),
              _buildPlaceholder('避難状況入力領域'),

              const SizedBox(height: 24),

              _buildSectionTitle('要配慮者情報'),

              _buildPlaceholder('要配慮者入力領域'),

              const SizedBox(height: 24),

              _buildSectionTitle('支援情報'),

              _buildPlaceholder('必要な支援入力領域'),
              _buildPlaceholder('体調状態入力領域'),

              const SizedBox(height: 24),

              _buildSectionTitle('その他'),

              _buildPlaceholder('特記事項入力領域'),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('TODO: 保存処理');
                  },
                  child: const Text('保存'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}