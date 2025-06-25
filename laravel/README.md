# Tryk Ride App

This repository contains a multi-platform ride-sharing application, including:

- **Laravel** backend API and admin panel (with [Filament](https://filamentphp.com/))
- **Flutter** apps for both drivers and users, supporting Android, iOS, Windows, macOS, and Linux

---

## Project Structure

```
.
├── laravel/      # Laravel backend (API & Admin)
├── flutter/
│   ├── driver/   # Flutter app for drivers
│   └── user/     # Flutter app for users
└── README.md
```

---

## Getting Started

### 1. Laravel Backend

#### Setup

```sh
cd laravel
composer install
npm install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed --class=RoleSeeder
php artisan make:filament-user
php artisan serve --host=0.0.0.0 --port=8000
```

- Visit the admin panel at [http://127.0.0.1:8000/admin](http://127.0.0.1:8000/admin)

#### Environment

- PHP 8.2+
- Node.js & npm
- PostgreSQL

---

### 2. Flutter Apps

Each app (`driver` and `user`) is a separate Flutter project.

#### Setup (example for user app)

```sh
cd flutter/user
flutter pub get
flutter run
```

- Repeat for `flutter/driver` as needed.

#### Platforms Supported

- Android
- iOS
- Windows
- macOS
- Linux

---

## Development Notes

- Laravel uses [Filament](https://filamentphp.com/) for the admin panel.
- Flutter apps are configured for multi-platform builds.
- See individual `README.md` files in each subproject for more details.

---

## License

This project is licensed under the MIT License.