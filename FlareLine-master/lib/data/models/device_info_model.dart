class DeviceInfoModel {
  final String? userAgent;
  final String? ip;
  final String? device;
  final String? browser;
  final String? os;

  DeviceInfoModel({
    this.userAgent,
    this.ip,
    this.device,
    this.browser,
    this.os,
  });

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      userAgent: json['userAgent'],
      ip: json['ip'],
      device: json['device'],
      browser: json['browser'],
      os: json['os'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userAgent': userAgent,
      'ip': ip,
      'device': device,
      'browser': browser,
      'os': os,
    };
  }
}