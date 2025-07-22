<?php
// app/Events/RideCancelled.php

namespace App\Events;

use App\Models\Ride;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class RideCancelled implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Ride $ride) {}

    public function broadcastOn(): array
    {
        // Find the driver who was either assigned or had the ride offered to them.
        $driverId = $this->ride->driver_id ?? $this->ride->assigned_driver_id;

        // Only broadcast if there was a driver to notify.
        if ($driverId) {
            // Target the specific driver's public channel.
            return [new Channel('driver.' . $driverId)];
        }
        
        // If no driver was involved, don't broadcast anywhere.
        return [];
    }

    /**
     * The event's broadcast name.
     * Your Flutter app will listen for this specific name.
     */
    public function broadcastAs(): string
    {
        return 'RideCancelled';
    }

    /**
     * The data payload for the event.
     * We only need to send the ID of the ride that was cancelled.
     */
    public function broadcastWith(): array
    {
        return ['ride_id' => $this->ride->id];
    }
}