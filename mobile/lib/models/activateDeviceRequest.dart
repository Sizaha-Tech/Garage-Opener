class ActivateDeviceRequest {
  String command;
  ActivateDeviceRequest({this.command});

  Map<String, dynamic> toJson() => {
        'command': command,
      };
}
