<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/driver-image/{userId}/{filename}', [Controllers\DriverController::class, 'serveImage']);
