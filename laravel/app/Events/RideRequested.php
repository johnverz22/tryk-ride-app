<?php

namespace App\Events;

use App\Models\Ride;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class RideRequested
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Ride $ride;

    /**
     * Create a new event instance.
     *
     * @param \App\Models\Ride $ride
     * @return void
     */
    public function __construct(Ride $ride)
    {
        $this->ride = $ride;
    }
}