class BlazeMessage {
  final String id;
  final String action;
  BlazeMessage(this.id, this.action);

  BlazeMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        action = json['action'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
      };
}
