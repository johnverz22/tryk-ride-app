<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\Ride;
use Illuminate\Support\Facades\Log;

// Broadcast::channel('private-ride.{rideId}', function ($user, $rideId) {
//     Log::info("🔐 Broadcast channel start");
    
//     $ride = Ride::find($rideId);

//     if (!$ride) {
//         Log::warning("❌ Ride not found for channel auth", [
//             'ride_id' => $rideId,
//             'user_id' => $user->id,
//         ]);
//         return false;
//     }

//     $authorized = $user->id === $ride->user_id || $user->id === $ride->assigned_driver_id;

//     Log::info("🔐 Channel auth decision", [
//         'ride_id' => $rideId,
//         'user_id' => $user->id,
//         'authorized' => $authorized,
//     ]);

//     return $authorized;
// });
