<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\Ride;
use Illuminate\Support\Facades\Log;

Broadcast::routes(['middleware' => ['auth:sanctum']]);

Broadcast::channel('ride.{rideId}', function ($user, $rideId) {
    $ride = Ride::find($rideId);

    if (!$ride) {
        Log::warning("Ride not found for ID: {$rideId}");
        return false;
    }

    $authorized = $user->id === $ride->user_id || $user->id === $ride->assigned_driver_id;

    if (!$authorized) {
        Log::info("User {$user->id} not authorized for Ride {$rideId}. Ride user: {$ride->user_id}, driver: {$ride->assigned_driver_id}");
    }

    return $authorized;
});
