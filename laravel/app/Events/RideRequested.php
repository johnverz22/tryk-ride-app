<?php

namespace App\Events;

use App\Models\Ride;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Queue\SerializesModels;

class RideRequested implements ShouldBroadcast
{
    use SerializesModels;

    public $ride;

    public function __construct(Ride $ride)
    {
        $this->ride = $ride;
    }

    public function broadcastOn()
    {
        return new Channel('drivers'); // Public or Presence channel
    }

    public function broadcastAs()
    {
        return 'ride.request';
    }

    public function broadcastWith()
    {
        return $this->ride->toArray(); // This will be sent as JSON to Flutter
    }
}
