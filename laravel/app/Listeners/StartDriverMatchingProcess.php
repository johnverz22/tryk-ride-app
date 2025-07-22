<?php

namespace App\Listeners;

use App\Jobs\OfferRideToDrivers;
use App\Models\Ride;
use App\Services\DriverMatchingService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class StartDriverMatchingProcess implements ShouldQueue
{
    use InteractsWithQueue;

    public function handle(Ride $ride): void
    {
        Log::info("Starting driver matching process for Ride ID: {$ride->id}");

        $matcher = app(DriverMatchingService::class);

        // 1. Find the best driver for the exclusive offer.
        $primaryDriver = $matcher->findNextAvailableDriver(
            $ride->pickup_latitude,
            $ride->pickup_longitude,
            $ride->search_radius_km
        );

        if ($primaryDriver) {
            // 2. Find ALL other nearby drivers for the public pool.
            $poolDrivers = $matcher->findAllNearbyDriversForPool(
                $ride->pickup_latitude,
                $ride->pickup_longitude,
                $ride->search_radius_km
            );

            Log::info("Found primary driver {$primaryDriver->id} for Ride ID: {$ride->id}. Broadcasting to a pool of {$poolDrivers->count()}.");
            
            // 3. Dispatch ONE job to orchestrate the offer process.
            OfferRideToDrivers::dispatch($ride, $primaryDriver, $poolDrivers);
        } else {
            Log::warning("No drivers found for Ride ID: {$ride->id}.");
            $ride->update(['ride_status_id' => \App\Enums\RideStatus::NO_DRIVERS_AVAILABLE]);
        }
    }
}