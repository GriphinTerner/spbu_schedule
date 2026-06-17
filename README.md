# SPbU Schedule

SPbU Schedule is a Flutter mobile application for viewing the schedule of Saint Petersburg State University.  
The app receives schedule data from the SPbU API, stores it locally and allows students to view previously loaded data even without an internet connection.

## Stack

- Flutter
- Dart
- REST API
- Provider
- Local storage

## Features

- View SPbU schedule by faculties and groups
- Load schedule data from the SPbU API
- Display schedule for the current day and week
- Local caching of schedule data
- Offline access to previously loaded schedule
- Light and dark theme support
- Adaptive mobile interface
- Error handling for unstable internet connection

## Result

The Telegram version of the project is used by approximately 50–100 students.

## Project structure

```text
lib/
  main.dart
  screens/
  services/
  providers/
  models/
  widgets/
```
## Requirements

Before running the project, make sure that Flutter SDK is installed.

Check Flutter installation:

```bash

flutter doctor

```

Check connected devices:

```bash

flutter devices

```

## How to run

Clone the repository:

```bash

git clone https://github.com/GriphinTerner/spbu_schedule.git

cd spbu_schedule

```

Install dependencies:

```bash

flutter pub get

```

Run the application:

```bash

flutter run

```

Run the application on a specific device:

```bash

flutter run -d device_id

```

Build Android APK:

```bash

flutter build apk

```

Build iOS application:

```bash

flutter build ios

```

## License

This project is intended for educational and portfolio purposes.
