import 'dart:convert';

class AccountKey {
  String keyAlgorithm;
  String keyOrigin;
  String keyType;
  String name;
  String privateKeyData;
  String privateKeyType;
  String validAfterTime;
  String validBeforeTime;

  AccountKey.fromJson(Map<String, dynamic> parsedJson)
      : keyAlgorithm = parsedJson["keyAlgorithm"],
        keyOrigin = parsedJson["keyOrigin"],
        keyType = parsedJson["keyType"],
        name = parsedJson["name"],
        privateKeyData = parsedJson["privateKeyData"],
        privateKeyType = parsedJson["privateKeyType"],
        validAfterTime = parsedJson["validAfterTime"],
        validBeforeTime = parsedJson["validBeforeTime"];
}

class DeviceModel {
  String deviceId;
  String deviceAccount;
  String outTopic;
  String inTopic;
  String outSubscription;
  String inSubscription;
  AccountKey appKey;
  AccountKey deviceKey;
  String appInstanceId;
  String createTime;

  DeviceModel.fromJson(Map<String, dynamic> parsedJson)
      : deviceAccount = parsedJson["account"],
        appInstanceId = parsedJson["app_id"],
        appKey = AccountKey.fromJson(json.decode(parsedJson["app_key"])),
        createTime = parsedJson["created"],
        deviceId = parsedJson["device_id"],
        deviceKey = AccountKey.fromJson(json.decode(parsedJson["device_key"])),
        inSubscription = parsedJson["in_sub"],
        inTopic = parsedJson["in_topic"],
        outSubscription = parsedJson["out_sub"],
        outTopic = parsedJson["out_topic"];
}
