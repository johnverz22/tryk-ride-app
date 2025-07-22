<?php

namespace App\Events;

use App\Models\Ride;
use App\Models\User;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NewRideOffer implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Ride $ride;
    public User $targetDriver;

    public function __construct(Ride $ride, User $targetDriver)
    {
        $this->ride = $ride;
        $this->targetDriver = $targetDriver;
    }

    public function broadcastOn(): array
    {
        // THE FIX: Always target the specific driver's private channel.
        return [new Channel('driver.' . $this->targetDriver->id)];
    }

    public function broadcastAs(): string
    {
        return 'NewRideRequest';
    }

    public function broadcastWith(): array
    {
        // We must include assigned_driver_id so the frontend knows who has the timed offer.
        $rideData = $this->ride->toArray();
        $rideData['assigned_driver_id'] = $this->ride->assigned_driver_id;
        // You might want to load user data here too if needed
        // $rideData['user'] = $this->ride->user->only(['id', 'name', 'profile_picture']);

        return ['ride' => $rideData];
    }
}