class Message {
  final String id;
  final String action;
  Message(this.id, this.action);

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        action = json['action'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
      };
}
