<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Broadcast;
use App\Http\Controllers;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;

// ───── Public Routes ─────
Route::post('/login', [Controllers\AuthController::class, 'login']);
Route::post('/register', [Controllers\AuthController::class, 'register']);

// ───── Protected Routes ─────
Route::middleware('auth:sanctum')->group(function () {

    // ── Broadcasting ──
    Route::post('/broadcasting/auth', fn (Request $request) => Broadcast::auth($request));

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
    Route::get('/driver/earnings', [Controllers\DriverController::class, 'earningsSummary']);
    
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
    Route::post('/rides/{ride}/rate', [Controllers\RideController::class, 'rateRide']);

    // ── Payment Methods ──
    Route::get('/payment-info', [Controllers\PaymentController::class, 'index']);
    Route::post('/wallet/top-up', [Controllers\PaymentController::class, 'topUp']);
    Route::post('/payment-methods', [Controllers\PaymentController::class, 'store']);
    Route::put('/payment-methods/{id}', [Controllers\PaymentController::class, 'update']);
    Route::delete('/payment-methods/{id}', [Controllers\PaymentController::class, 'destroy']);

    // ── Saved Locations ──
    Route::get('/user/saved-locations', [Controllers\SavedLocationController::class, 'index']);
    Route::post('/user/saved-locations', [Controllers\SavedLocationController::class, 'store']);
    Route::put('/user/saved-locations/{id}', [Controllers\SavedLocationController::class, 'update']);
    Route::delete('/user/saved-locations/{id}', [Controllers\SavedLocationController::class, 'destroy']);

    
    // ── Message Methods ──
    Route::get('/conversations/{id}/messages', [Controllers\MessageController::class, 'index']);
    Route::post('/conversations/{id}/messages', [Controllers\MessageController::class, 'store']);
    Route::get('/conversations', [Controllers\MessageController::class, 'userConversations']);

});
