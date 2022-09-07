class MessageResult {
  MessageResult(this.success, this.retry, [this.errorCode]);

  final bool success;
  final bool retry;
  final int? errorCode;
}
