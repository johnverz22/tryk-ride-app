<?php

namespace App\Jobs;

use App\Enums\RideStatus;
use App\Events\RideStatusUpdated;
use App\Models\User;
use App\Models\Ride;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use App\Services\RideService;

class ProcessRideOfferTimeout implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        protected Ride $ride,
        protected User $driver,
    ) {}


    public function handle(RideService $rideService): void
    {
        $ride = $this->ride->fresh();

        if ($ride->ride_status_id === RideStatus::OFFERED && $ride->assigned_driver_id === $this->driver->id) {
            Log::info("Driver {$this->driver->id} timed out for ride {$ride->id}. Auto-accepting via RideService.");

            // Now, you can safely use the injected service.
            $rideService->acceptRide($ride, $this->driver);
        } else {
             Log::info("Skipping timeout job for ride {$ride->id}. Its status has already changed.");
        }
    }
}