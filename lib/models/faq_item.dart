class FaqItem {
  final String id;
  final String question;
  final String answer;
  final List<String> roles; // e.g., ['Buyer', 'Seller', 'Admin']

  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.roles,
  });

  factory FaqItem.fromMap(Map<String, dynamic> map, String id) {
    return FaqItem(
      id: id,
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      roles: List<String>.from(map['roles'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'roles': roles,
    };
  }
}