import 'package:nasa_apod/models/app_storage.dart';
import 'package:nasa_apod/tasks/wallpaper_task.dart';
import 'package:workmanager/workmanager.dart';

// Gets called for every task called
void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    print("Native called background task: $task");

    switch (task) {
      case CHANGE_WALLPAPER_TASKNAME:
        await changeWallpaper();
        return true;
      default:
        return true;
    }
  });
}

// Register tasks
void initializeBackgroundTasks() async {
  Workmanager.initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  updateWallpaperTask(await AppStorage.getDynamicWallpaper());
}
