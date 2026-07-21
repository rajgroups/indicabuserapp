class FaqModel {
  FaqModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.sequence,
    required this.isActive,
  });

  final int id;
  final String category;
  final String question;
  final String answer;
  final int sequence;
  final bool isActive;

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as int? ?? 0,
      category: json['category']?.toString() ?? 'General',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      sequence: json['sequence'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'answer': answer,
      'sequence': sequence,
      'is_active': isActive,
    };
  }
}
