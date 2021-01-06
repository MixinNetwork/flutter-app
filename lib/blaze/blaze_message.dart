class BlazeMessage {
  BlazeMessage(this.id, {this.action, this.status, String messageId});

  BlazeMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        action = json['action'],
        status = json['status'];

  final String id;
  String action;
  String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'status': status,
      };
}
