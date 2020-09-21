class DeviceCreateRequest {
  String appId;
  String deviceId;
  String deviceName;
  DeviceCreateRequest({this.appId, this.deviceId, this.deviceName});

  Map<String, dynamic> toJson() => {
        'app_id': appId,
        'device_id': deviceId,
        'device_name': deviceName,
      };
}
