# [Laravel](https://laravel.com/) with [Filament](https://filamentphp.com/) Template

## Change Directory to Laravel

```
cd laravel
```

## Install Dependencies

```
composer install
npm install
```

## Generate .env file

```
copy .env.example .env
```

## Generate App Key

```
php artisan key:generate
```

## Generate JWT Secret

```
php artisan jwt:secret
```

## Create Tables by Migration

```
php artisan migrate
```

## Seed the Roles Table

```
php artisan db:seed --class=RoleSeeder
```

## Create a Filament User

```
php artisan make:filament-user
```

## Run the Server

```
php artisan serve --host=0.0.0.0 --port=8000
```

## Visit the Admin Panel

```
http://127.0.0.1:8000/admin
```