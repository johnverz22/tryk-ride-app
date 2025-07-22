<?php

namespace App\Services;

use App\Enums\RideStatus;
use App\Events\RideStatusUpdated;
use App\Models\Ride;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class RideService
{
    public function acceptRide(Ride $ride, User $driver): ?Ride
    {
        if ($ride->ride_status_id !== RideStatus::OFFERED || $ride->assigned_driver_id !== $driver->id) {
            return null;
        }

        $ride->update([
            'driver_id' => $driver->id,
            'ride_status_id' => RideStatus::ACCEPTED,
            'accepted_at' => now(),
        ]);

        event(new RideStatusUpdated($ride));

        return $ride;
    }
}
