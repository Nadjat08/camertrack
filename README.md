# CamerTrack

CamerTrack is a family location-tracking project with:

- a Node.js backend API
- a PostgreSQL database
- a Flutter parent mobile app
- a Wear OS watch app for child tracking

This README explains what your colleague needs to install and how to run the project locally.

---

## Prerequisites

### Required software

- Node.js 18+ and npm
- PostgreSQL 13+ (or Docker with PostgreSQL)
- Flutter SDK compatible with Dart 3.12 (recommended Flutter 3.44.6)
- Android SDK with Android API 34 and emulator support
- Java JDK 17+ (needed for Android Gradle builds)
- Android Studio or command-line Android SDK tools

### Recommended tools

- VS Code or Android Studio for editing
- Docker Desktop (optional, for local PostgreSQL)
- `git` for version control

---

## What to install

### 1. Backend dependencies

In the repository root:

```bash
npm install
```

This installs:

- express
- socket.io
- pg
- jsonwebtoken
- bcrypt
- dotenv
- winston
- cors

### 2. Flutter dependencies

In the repository root:

```bash
flutter pub get
```

This installs:

- http
- shared_preferences
- flutter_map and latlong2
- geolocator
- permission_handler
- socket_io_client
- mobile_scanner

### 3. Android / Wear OS requirements

Your colleague should install:

- Android SDK Platform 34
- Android SDK Build-Tools 34.x
- Android Emulator
- Wear OS system image for API 34
- Android SDK Command-line Tools

Also make sure `flutter doctor` shows Android toolchain ready.

---

## Local database setup

This project expects a PostgreSQL database with environment variables configured.

Create a local database and user, or use Docker:

```bash
docker run --name camertrack-postgres -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=mkounga10 -e POSTGRES_DB=camertrack -p 5433:5432 -d postgres:15
```

Then configure environment variables in a `.env` file at the project root.

Example `.env` contents:

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5433
DB_NAME=camertrack
DB_USER=postgres
DB_PASSWORD=mkounga10
JWT_SECRET=your_jwt_secret_here
```

> Keep `.env` local and do not commit it.

If the database is already created on your colleague’s machine, she only needs to ensure the same values match her local PostgreSQL instance.

---

## Project structure

- `server.js` – Node/Express server entry point
- `src/config/db.js` – PostgreSQL connection pool
- `src/routes/` – API route definitions
- `src/controllers/` – API controllers for auth, groups, positions, bracelets, and watch location/SOS
- `src/middleware/` – auth middleware for users and bracelet devices
- `src/utils/logger.js` – Winston logging setup
- `lib/` – Flutter parent app source
- `android/` and `app/` – Android and Wear OS build configuration files

---

## Run the backend

In the project root:

```bash
npm run dev
```

This starts the API server on port 3000 by default.

Verify the backend is running:

```bash
curl http://localhost:3000/
```

Expected response:

```json
{ "message": "CamerTrack API is running" }
```

---

## Run the Flutter app

In the repository root, after `flutter pub get`:

```bash
flutter run -d emulator-5554
```

### Important emulator networking note

When running on the Android emulator, the mobile app must reach the backend through the special host alias:

```text
http://10.0.2.2:3000/api
```

That is already configured in the project, so the emulator should connect correctly if the backend is running locally.

---

## Run the Wear OS watch app

The watch app also uses the same backend and emulator networking setup.

If using the Wear OS emulator, make sure the emulator is started and reachable.

---

## Additional notes

- The project uses `10.0.2.2` for emulator-to-host networking.
- Do not commit `node_modules/`, `android/build/`, `.gradle/`, or `.env`.
- If Android build fails, verify Java JDK, Android SDK, and emulator images are installed.
- The backend requires a valid `JWT_SECRET` in `.env`.

---

## Checklist for your colleague

1. Clone the project repository
2. Install Node.js and run `npm install`
3. Install Flutter and run `flutter pub get`
4. Install PostgreSQL or run Docker Postgres
5. Create a `.env` file with DB and JWT settings
6. Start the backend with `npm run dev`
7. Start an Android or Wear OS emulator
8. Run `flutter run -d emulator-5554`

---

## If something does not work

- Check `flutter doctor` for missing Flutter/Android components
- Confirm PostgreSQL is listening on `localhost:5433`
- Confirm backend logs show `Serveur démarré sur le port 3000`
- Confirm emulator can access `http://10.0.2.2:3000/api`
- Use `npm install` and `flutter pub get` again if dependencies are missing
