<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers;

// ───── Public Routes ─────
Route::post('/login', [Controllers\AuthController::class, 'login']);
Route::post('/register', [Controllers\AuthController::class, 'register']);

// ───── Protected Routes ─────
Route::middleware('auth:sanctum')->group(function () {

    // ── Authenticated User ──
    Route::get('/user', fn(Request $request) => $request->user());
    Route::post('/logout', [Controllers\AuthController::class, 'logout']);

    // ── User Routes ──
    Route::put('/user/update', [Controllers\UserController::class, 'update']);
    Route::get('/user/trips', [Controllers\UserController::class, 'userTrips']);

    // ── Driver Routes ──
    Route::put('/driver/update', [Controllers\UserController::class, 'update']);
    Route::get('/driver/trips', [Controllers\DriverController::class, 'trips']);
    Route::post('/driver/update-location', [Controllers\DriverController::class, 'updateLocation']);
    Route::get('/driver/requested-rides', [Controllers\DriverController::class, 'requestedRides']);
    Route::post('/driver/go-offline', [Controllers\DriverController::class, 'goOffline']);
    Route::get('/driver/documents', [Controllers\DriverController::class, 'getDocuments']);
    Route::post('/driver/upload-document', [Controllers\DriverController::class, 'uploadDocument']);
    Route::post('/driver/submit-verification', [Controllers\DriverController::class, 'submitVerification']);
    
    // ── Ride Routes ──
    Route::post('/rides/cancel', [Controllers\RideController::class, 'cancel']);
    Route::post('/rides/request', [Controllers\RideController::class, 'store']);
    Route::get('/rides/ongoing', [Controllers\RideController::class, 'ongoing']);
    Route::get('/rides/{id}', [Controllers\RideController::class, 'show']);
    Route::post('/rides/{id}/accept', [Controllers\RideController::class, 'accept']);
    Route::post('/rides/{id}/complete', [Controllers\RideController::class, 'complete']);
    Route::post('/rides/{id}/confirm-completion', [Controllers\RideController::class, 'confirmCompletion']);
    Route::post('/rides/{id}/confirm-start', [Controllers\RideController::class, 'confirmStart']);
    Route::get('/rides/{id}/driver-location', [Controllers\DriverController::class, 'getLocation']);
    Route::post('/rides/{id}/start', [Controllers\RideController::class, 'start']);
    Route::patch('/rides/{ride}/reject', [Controllers\RideController::class, 'reject']);

    // ── Saved Locations ──
    Route::get('/user/saved-locations', [Controllers\SavedLocationController::class, 'index']);
    Route::post('/user/saved-locations', [Controllers\SavedLocationController::class, 'store']);
    Route::put('/user/saved-locations/{id}', [Controllers\SavedLocationController::class, 'update']);
});
