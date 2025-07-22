<?php

namespace App\Jobs;

use App\Enums\RideStatus;
use App\Events\NewRideOffer;
use App\Models\Ride;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OfferRideToDrivers implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        protected Ride $ride,
        protected User $primaryDriver,
        protected Collection $poolDrivers
    ) {}

    public function handle(): void
    {
        DB::beginTransaction();
        try {
            // 1. Assign the ride to the primary driver for the timed offer.
            $this->ride->update([
                'assigned_driver_id' => $this->primaryDriver->id,
                'ride_status_id' => RideStatus::OFFERED,
            ]);

            // 2. Schedule the timeout job ONLY for the primary driver.
            ProcessRideOfferTimeout::dispatch($this->ride, $this->primaryDriver)
                ->delay(now()->addSeconds(30));

            // 3. Notify ALL drivers in the pool (including the primary one).
            // Your frontend will handle showing the timer only for the assigned_driver_id.
            foreach ($this->poolDrivers as $driver) {
                event(new NewRideOffer($this->ride, $driver));
            }
            
            DB::commit();
            Log::info("Offered ride {$this->ride->id} to primary driver {$this->primaryDriver->id} and broadcasted to {$this->poolDrivers->count()} pool drivers.");

        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error("Failed to offer ride {$this->ride->id}: " . $e->getMessage());
        }
    }
}