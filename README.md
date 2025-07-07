# Tryk Ride App

A multi-platform ride-sharing application with:

- **Laravel** backend API and admin panel (using [Filament](https://filamentphp.com/))
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
copy .env.example .env
php artisan key:generate
```

## Generate JWT Secret

```
php artisan jwt:secret
```

## Create Tables by Migration and run Seeders

```
php artisan migrate --seed
```

## Create a Filament User

```
php artisan make:filament-user
```

## Run the Server

```
php artisan serve --host=192.168.0.0 --port=8000
```

## Visit the Admin Panel

```
http://127.0.0.1:8000/admin
```
