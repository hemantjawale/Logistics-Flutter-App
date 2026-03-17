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
    
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // Send to backend
    final user = await UserSession.getUser();
    if (user != null && user['role'] == 'driver') {
      final vehicleId = user['assignedVehicleId'];
      if (vehicleId != null) {
        await ApiClient.updateVehicleLocation(vehicleId, position.latitude, position.longitude);
        print("Background Task: Updated location for vehicle $vehicleId");
      }
    }
    
    print("Background Task: Battery $batteryLevel%, Location: ${position.latitude}, ${position.longitude}");
    
    if (isLowBattery) {
      print("CRITICAL: Low Battery! Sending emergency location update.");
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
