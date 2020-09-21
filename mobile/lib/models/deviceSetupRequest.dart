class DeviceSetupRequest {
  String ssid;
  String passphrase;
  String inSub;
  String outSub;
  String serviceKeyBlob;
  DeviceSetupRequest(
      {this.ssid,
      this.passphrase,
      this.inSub,
      this.outSub,
      this.serviceKeyBlob});

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'psk': passphrase,
        'in_sub': inSub,
        'out_sub': outSub,
        'service_key_blob': serviceKeyBlob,
      };
}
