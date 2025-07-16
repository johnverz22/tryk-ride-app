<?php

namespace App\Events;

use App\Models\Ride;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class RideStatusUpdated implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public Ride $ride;

    public function __construct(Ride $ride)
    {
        $this->ride = $ride;
        Log::info('RideStatusUpdated constructed', ['ride_id' => $ride->id]);
    }

    public function broadcastOn(): Channel
    {
        Log::info('Broadcasting on channel: ride.' . $this->ride->id);
        return new Channel('ride.' . $this->ride->id);
    }

    public function broadcastAs(): string
    {
        return 'RideStatusUpdated';
    }

    public function broadcastWith(): array
    {
        Log::info('Broadcasting RideStatusUpdated', ['ride_id' => $this->ride->id]);
        return [
            'ride_id' => $this->ride->id,
            'ride_status_id' => $this->ride->ride_status_id,
            'assigned_driver_id' => $this->ride->assigned_driver_id,
        ];
    }
}
