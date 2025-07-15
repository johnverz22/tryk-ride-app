<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers;
use App\Events\RideStatusUpdated;
use App\Models\Ride;
use Illuminate\Support\Facades\Log;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/driver-image/{userId}/{filename}', [Controllers\DriverController::class, 'serveImage']);
