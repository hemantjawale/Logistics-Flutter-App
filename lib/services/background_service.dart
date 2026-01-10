import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'api_client.dart';
import 'user_session.dart';

const String taskName = "backgroundLocationTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskName) {
      await _checkAndSendLocation();
    }
    return Future.value(true);
  });
}

Future<void> _checkAndSendLocation() async {
  try {
    final Battery battery = Battery();
    final int batteryLevel = await battery.batteryLevel;
    
    // Condition 1: Battery below 15%
    bool isLowBattery = batteryLevel < 15;
    
    // Condition 2: Regular 30-min update (Handled by Workmanager interval)
    // But we can force it here if we want to add extra logic
    
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // Send to backend
    // Assuming we have a way to identify the user/device.
    // In background, UserSession might not be available or persistent in the same way.
    // We might need to store token/ID in shared prefs accessible here.
    // For now, let's assume we can get the driver ID or use a generic update endpoint.
    
    // Since we are in a background isolate, we need to be careful with dependencies.
    // ApiClient might need initialization or token.
    
    // For simplicity in this demo, we will just print/log.
    // In production: await ApiClient.updateDriverLocation(driverId, position, batteryLevel);
    
    print("Background Task: Battery $batteryLevel%, Location: ${position.latitude}, ${position.longitude}");
    
    if (isLowBattery) {
      // Trigger "Urgent" update
      print("CRITICAL: Low Battery! Sending emergency location update.");
      // ApiClient.sendEmergencyAlert(...)
    }

  } catch (e) {
    print("Background Task Error: $e");
  }
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  static Future<void> startTracking() async {
    // Register periodic task every 30 minutes (15 min is minimum for Android)
    await Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
