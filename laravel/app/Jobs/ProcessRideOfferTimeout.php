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
        // 1. Get the most current state of the ride from the database.
        $ride = $this->ride->fresh();

        // 2. Check if the job's purpose is still valid.
        // If the status is NOT 'OFFERED', the driver has already acted.
        if ($ride->ride_status_id !== RideStatus::OFFERED) {
            
            // 3. The job is obsolete. Log it and delete it from the queue.
            // This prevents it from being retried or showing as 'failed'. It's simply gone.
            Log::info("Ride {$ride->id} status is now '{$ride->ride_status_id}'. Deleting obsolete timeout job.");
            $this->delete();
            return; // Stop further execution.
        }

        // 4. If the code reaches here, the timeout is valid.
        // The driver did not respond in time.
        Log::info("Driver {$this->driver->id} timed out for ride {$ride->id}. Auto-accepting via RideService.");
        $rideService->acceptRide($ride, $this->driver);
    }
}