import 'package:flutter/material.dart';

enum AgeGroup {
  child,
  teenager,
  adult,
  senior,
}

enum Gender {
  male,
  female,
  noAnswer,
}

enum EvacuationStatus {
  evacuating,
  planning,
  notEvacuating,
}

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  AgeGroup? _selectedAgeGroup;
  Gender? _selectedGender;
  EvacuationStatus? _selectedEvacuationStatus;

  int _familyCount = 1; 

  final TextEditingController _familyCountController =
      TextEditingController();

  @override
  void dispose() {
    _familyCountController.dispose();
    super.dispose();
  }

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

              const Text(
                '年齢区分',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              RadioListTile<AgeGroup>(
                title: const Text('0〜6歳'),
                value: AgeGroup.child,
                groupValue: _selectedAgeGroup,
                onChanged: (value) {
                  setState(() {
                    _selectedAgeGroup = value;
                  });
                },
              ),

              RadioListTile<AgeGroup>(
                title: const Text('7〜18歳'),
                value: AgeGroup.teenager,
                groupValue: _selectedAgeGroup,
                onChanged: (value) {
                  setState(() {
                    _selectedAgeGroup = value;
                  });
                },
              ),

              RadioListTile<AgeGroup>(
                title: const Text('19〜64歳'),
                value: AgeGroup.adult,
                groupValue: _selectedAgeGroup,
                onChanged: (value) {
                  setState(() {
                    _selectedAgeGroup = value;
                  });
                },
              ),

              RadioListTile<AgeGroup>(
                title: const Text('65歳以上'),
                value: AgeGroup.senior,
                groupValue: _selectedAgeGroup,
                onChanged: (value) {
                  setState(() {
                    _selectedAgeGroup = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              const Text(
                '性別',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              RadioListTile<Gender>(
                title: const Text('男性'),
                value: Gender.male,
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),

              RadioListTile<Gender>(
                title: const Text('女性'),
                value: Gender.female,
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),

              RadioListTile<Gender>(
                title: const Text('回答しない'),
                value: Gender.noAnswer,
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              const Text(
                '世帯人数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<int>(
                value: _familyCount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  10,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}人'),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _familyCount = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              const Text(
                '避難状況',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              RadioListTile<EvacuationStatus>(
                title: const Text('避難中'),
                value: EvacuationStatus.evacuating,
                groupValue: _selectedEvacuationStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedEvacuationStatus = value;
                  });
                },
              ),

              RadioListTile<EvacuationStatus>(
                title: const Text('避難予定'),
                value: EvacuationStatus.planning,
                groupValue: _selectedEvacuationStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedEvacuationStatus = value;
                  });
                },
              ),

              RadioListTile<EvacuationStatus>(
                title: const Text('避難しない'),
                value: EvacuationStatus.notEvacuating,
                groupValue: _selectedEvacuationStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedEvacuationStatus = value;
                  });
                },
              ),

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
                    debugPrint('年齢区分: $_selectedAgeGroup');
                    debugPrint('性別: $_selectedGender');
                    debugPrint('世帯人数: ${_familyCountController.text}');
                    debugPrint('避難状況: $_selectedEvacuationStatus');
                  },
                  child: const Text('送信'),
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