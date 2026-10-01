import 'dart:io';

class AdbService {
  /// Mengirim perintah adb ke IP TV Android.
  /// Memerlukan binary `adb` terinstal dan bisa diakses dari env PATH.
  /// (Catatan: Jika dijalankan di Windows, adb harus di set di PATH. Jika di Android murni, butuh package flutter_adb).
  
  static String get _adbCommand {
    if (Platform.isWindows) {
      // Fallback path default Windows untuk kenyamanan saat development
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) {
        final fullPath = '$localAppData\\Android\\Sdk\\platform-tools\\adb.exe';
        if (File(fullPath).existsSync()) {
          return fullPath;
        }
      }
    }
    return 'adb'; // Default jika sudah masuk PATH atau di OS lain
  }

  static Future<bool> connect(String ipAddress) async {
    try {
      print('ADB Connecting to $ipAddress...');
      final result = await Process.run(_adbCommand, ['connect', '$ipAddress:5555']);
      print('ADB Connect Result: ${result.stdout}');
      return result.stdout.toString().contains('connected to') || result.stdout.toString().contains('already connected');
    } catch (e) {
      print('ADB Connect Error: $e');
      return false;
    }
  }

  static Future<bool> turnOffTv(String ipAddress) async {
    if (ipAddress.isEmpty) return false;
    try {
      await connect(ipAddress);
      print('ADB Sending Sleep command to $ipAddress...');
      final result = await Process.run(_adbCommand, ['-s', '$ipAddress:5555', 'shell', 'input', 'keyevent', '26']);
      print('ADB Sleep Result: ${result.stdout}');
      return true;
    } catch (e) {
      print('ADB Error turnOffTv: $e');
      return false;
    }
  }

  static Future<bool> turnOnTv(String ipAddress) async {
    if (ipAddress.isEmpty) return false;
    try {
      await connect(ipAddress);
      print('ADB Sending Wake command to $ipAddress...');
      final result = await Process.run(_adbCommand, ['-s', '$ipAddress:5555', 'shell', 'input', 'keyevent', '224']); // 224 is KEYCODE_WAKEUP
      print('ADB Wake Result: ${result.stdout}');
      return true;
    } catch (e) {
      print('ADB Error turnOnTv: $e');
      return false;
    }
  }
}
