class FeedbackModel {
  final int? id;
  final String name;
  final String message;

  FeedbackModel({this.id, required this.name, required this.message});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'message': message,
      };

  factory FeedbackModel.fromMap(Map<String, dynamic> map) => FeedbackModel(
        id: map['id'],
        name: map['name'],
        message: map['message'],
      );
}
