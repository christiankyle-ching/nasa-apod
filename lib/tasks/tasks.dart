import 'package:nasa_apod/tasks/wallpaper_task.dart';
import 'package:workmanager/workmanager.dart';

// Gets called for every task called
void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    print("Native called background task: $task");

    switch (task) {
      case CHANGE_WALLPAPER_TASKNAME:
        try {
          await attemptChangeWallpaper(inputData['screenRatio']);
          return Future.value(true);
        } catch (err) {
          return Future.value(false);
        }
        break;
      default:
        return Future.value(true);
    }
  });
}

// Register tasks
void initializeBackgroundTasks() async {
  Workmanager.initialize(
    callbackDispatcher,
    // DEBUG: change to false on production
    isInDebugMode: true,
  );
}
