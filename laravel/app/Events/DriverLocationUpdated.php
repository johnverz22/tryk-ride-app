<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use App\Models\Driver; // Still need to resolve the Driver model to get driver info
use App\Models\Ride;   // Still need to resolve the Ride model to get ride info and ID

class DriverLocationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $driver;
    public $ride;
    public $latitude;
    public $longitude;
    public $bearing; // Optional
    public $speed;   // Optional

    /**
     * Create a new event instance.
     * @param Driver $driver The driver object (from authentication)
     * @param Ride $ride The ride object associated with the driver's current active ride
     * @param float $latitude The current latitude
     * @param float $longitude The current longitude
     * @param float|null $bearing Optional: current bearing/direction
     * @param float|null $speed Optional: current speed
     */
    public function __construct(Driver $driver, Ride $ride, float $latitude, float $longitude, ?float $bearing = null, ?float $speed = null)
    {
        $this->driver = $driver;
        $this->ride = $ride;
        $this->latitude = $latitude;
        $this->longitude = $longitude;
        $this->bearing = $bearing;
        $this->speed = $speed;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        // Broadcast on a public channel specific to the ride ID
        return [
            new Channel('ride.' . $this->ride->id),
        ];
    }

    /**
     * The event's broadcast name.
     *
     * @return string
     */
    public function broadcastAs(): string
    {
        return 'DriverLocationUpdated';
    }

    /**
     * Get the data to broadcast.
     *
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'ride_id' => $this->ride->id,
            'driver_id' => $this->driver->id,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'bearing' => $this->bearing,
            'speed' => $this->speed,
            'timestamp' => now()->timestamp,
            'driver_info' => [
                'name' => $this->driver->name,
                'vehicle_model' => $this->driver->vehicle_model, // Example
                'license_plate' => $this->driver->license_plate, // Example
                'profile_picture' => $this->driver->profile_picture_url, // Example
            ],
            'status' => [
                'id' => $this->ride->status_id,
                'name' => $this->ride->status->name ?? 'unknown',
            ]
        ];
    }
}