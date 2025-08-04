class CardMessage {
  final String occasion;
  final String? templateId;
  final String dear;
  final String message;
  final String from;
  final bool hideSenderName;

  CardMessage({
    required this.occasion,
    this.templateId,
    required this.dear,
    required this.message,
    required this.from,
    required this.hideSenderName,
  });

  factory CardMessage.fromJson(Map<String, dynamic> json) {
    return CardMessage(
      occasion: json['occasion'],
      templateId: json['templateId'],
      dear: json['dear'],
      message: json['message'],
      from: json['from'],
      hideSenderName: json['hideSenderName'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'occasion': occasion,
    if (templateId != null) 'templateId': templateId,
    'dear': dear,
    'message': message,
    'from': from,
    'hideSenderName': hideSenderName,
  };
}
