# Todo App

A simple Todo app with a Flutter + GetX client and a Node.js + Express API backed by MongoDB Atlas. Tasks support descriptions, due dates and times, priorities, completion status, and device-local reminders.

## Project layout

```text
todo-node/
├── todo_app/                 # Flutter app
│   └── lib/todos/
│       ├── controllers/      # GetX state and app actions
│       ├── models/           # Todo data model
│       ├── pages/            # Todo and onboarding screens
│       └── services/         # API, device ID, and notifications
└── todo-backend/             # Express API and MongoDB models
    └── src/
        ├── config/           # MongoDB connection
        ├── modules/todos/    # Todo model, controller, and routes
        ├── app.js            # Express app and middleware
        └── server.js         # Starts MongoDB and HTTP server
```

## Requirements

- Flutter SDK and Dart (versions compatible with `todo_app/pubspec.yaml`)
- Node.js and npm
- A MongoDB Atlas cluster and database user
- An Android emulator or phone for mobile use

## Run the backend

Open PowerShell in `todo-backend` and install dependencies:

```powershell
npm install
```

Create `todo-backend/.env` with your Atlas connection string. Keep this file private and do not commit it.

```env
PORT=5000
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster-host>/<database>?retryWrites=true&w=majority
```

Replace the placeholders with your Atlas values. URL-encode special characters in the database password. In Atlas, allow network access from the computer running the backend.

Start the server:

```powershell
node src/server.js
```

When connected, the API is available at `http://localhost:5000/api/todos`. The server defaults to port `3000` if `PORT` is not set.

## Run the Flutter app

Install Flutter packages:

```powershell
cd ..\todo_app
flutter pub get
```

The API address depends on where Flutter runs.

**Android emulator** (this is also the app’s default Android address):

```powershell
flutter run --dart-define=TODO_API_URL=http://10.0.2.2:5000/api/todos
```

**Physical Android phone:** connect the phone and computer to the same network, find the computer’s local IPv4 address, and use it in place of `<computer-ip>`:

```powershell
flutter run --dart-define=TODO_API_URL=http://<computer-ip>:5000/api/todos
```

For example, if the computer’s address is `192.168.1.25`, use `http://192.168.1.25:5000/api/todos`. Allow Node.js through the computer’s firewall if the phone cannot connect. Keep the backend running while using the app.

**Flutter web:** use `http://localhost:5000/api/todos`.

The app can receive a time zone at run time. If omitted, reminders use `Asia/Kathmandu`:

```powershell
flutter run --dart-define=TODO_TIME_ZONE=Asia/Kathmandu
```

## API overview

All routes are under `/api/todos`. Every request must include an `x-device-id` header. The Flutter app creates a UUID for the app installation and stores it locally; the backend uses it as `ownerId` to separate that device’s tasks.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/api/todos` | List this device’s tasks |
| `POST` | `/api/todos` | Create a task |
| `PUT` | `/api/todos/:id` | Update a task |
| `DELETE` | `/api/todos/:id` | Delete a task |

Example create request body:

```json
{
  "title": "Study Node.js",
  "description": "Review Express routes",
  "completed": false,
  "dueAt": "2026-12-01T09:30:00.000Z",
  "priority": "important",
  "reminderEnabled": true
}
```

`priority` can be `basic`, `important`, or `urgent`. Dates are ISO 8601 timestamps. The server stores each task with the device’s `ownerId` and timestamps.

Example PowerShell request:

```powershell
Invoke-RestMethod `
  -Method Get `
  -Uri "http://localhost:5000/api/todos" `
  -Headers @{ "x-device-id" = "my-test-device" }
```

## Reminders

Reminders are scheduled locally by the Flutter app with `flutter_local_notifications`; they are not push messages sent by the backend. The phone must allow notifications, and Android may also ask for exact-alarm access. The task is saved to MongoDB independently of whether notification permission is granted. Completing or deleting a task cancels its scheduled reminder.

This project has no accounts or authentication. The device ID is stored locally, so clearing app data or reinstalling can create a new ID. This is suitable for learning and personal development, not secure multi-user access. Before a public deployment, use authenticated user identities, validate ownership on the server, enable HTTPS, and keep database credentials out of the app.

## Checks

From `todo_app`:

```powershell
flutter analyze
flutter test
```

The current `test/widget_test.dart` is Flutter’s generated counter test and should be replaced with Todo app tests as the project grows.
