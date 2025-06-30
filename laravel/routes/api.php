<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers;

// Public routes
Route::post('/register', [Controllers\AuthController::class, 'register']);
Route::post('/login', [Controllers\AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn(Request $request) => $request->user());
    Route::post('/logout', [Controllers\AuthController::class, 'logout']);
    
    Route::put('/user/update', [Controllers\UserController::class, 'update']);
    Route::get('/user/trips', [Controllers\UserController::class, 'userTrips']);
    Route::put('/driver/update', [Controllers\UserController::class, 'update']);
    Route::get('/driver/trips', [Controllers\DriverController::class, 'trips']);
    Route::post('/driver/update-location', [Controllers\DriverController::class, 'updateLocation']);
    Route::get('/driver/documents', [Controllers\DriverController::class, 'getDocuments']);
    Route::post('/driver/upload-document', [Controllers\DriverController::class, 'uploadDocument']);
    Route::post('/driver/submit-verification', [Controllers\DriverController::class, 'submitVerification']);
    Route::get('/driver/requested-rides', [Controllers\DriverController::class, 'requestedRides']);
    Route::post('/driver/go-offline', [Controllers\DriverController::class, 'goOffline']);
    
    Route::get('/user/saved-locations', [Controllers\SavedLocationController::class, 'index']);
    Route::post('/user/saved-locations', [Controllers\SavedLocationController::class, 'store']);
    Route::put('/user/saved-locations/{id}', [Controllers\SavedLocationController::class, 'update']);

    Route::post('/rides/request', [Controllers\RideController::class, 'store']);
    Route::post('/rides/cancel', [Controllers\RideController::class, 'cancel']);
    Route::post('/rides/{id}/accept', [Controllers\RideController::class, 'accept']);
    Route::patch('/rides/{ride}/reject', [Controllers\RideController::class, 'reject']);
    Route::get('/rides/{id}', [Controllers\RideController::class, 'show']);
    Route::get('/rides/{id}/driver-location', [Controllers\DriverController::class, 'getLocation']);
});
