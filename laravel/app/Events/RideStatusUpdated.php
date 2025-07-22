<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use App\Models\Ride;
use App\Models\Driver;
use Illuminate\Support\Facades\Log;

class RideStatusUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Ride $ride;

    /**
     * Create a new event instance.
     *
     * @param  \App\Models\Ride  $ride
     */
    public function __construct(Ride $ride)
    {
        // It's CRUCIAL that $ride is loaded with 'driver' and 'status' relationships
        // before being passed into this constructor.
        // Example: $ride->load('driver', 'status');
        $this->ride = $ride;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
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
        return 'RideStatusUpdated';
    }

    /**
     * Get the data to broadcast.
     *
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        $payload = $this->ride->toArray();

        // Get the driver instance via the relationship
        $driver = $this->ride->driver; // This will be an App\Models\Driver instance if loaded

        Log::info('Driver details:', ['driver' => $driver]);
        if ($driver) {
            $payload['driver_info'] = [
                'id' => $driver->id,
                'name' => $driver->name, // This is the key you need
                'email' => $driver->email ?? null,
                'phone' => $driver->phone ?? null, // Fixed missing comma here
                'profile_picture' => $driver->profile_picture_url ?? null,
                'vehicle_model' => $driver->vehicle_model ?? null,
                'license_plate' => $driver->license_plate ?? null,
                'current_latitude' => (float) $driver->current_latitude ?? null,
                'current_longitude' => (float) $driver->current_longitude ?? null,
                'bearing' => (float) $driver->bearing ?? null,
                'speed' => (float) $driver->speed ?? null,
            ];
            // Remove redundant IDs if driver_info is comprehensive
            unset($payload['driver_id']);
            unset($payload['assigned_driver_id']);
        } else {
            $payload['driver_info'] = null; // Explicitly null if no driver assigned/found
            unset($payload['driver_id']);
            unset($payload['assigned_driver_id']);
        }

        // Handle the 'status' relationship
        $status = $this->ride->status;
        if ($status) {
            $payload['status'] = [
                'id' => $status->id,
                'name' => $status->name,
            ];
        } else {
            $payload['status'] = null;
        }
        unset($payload['ride_status_id']); // Remove if status object is preferred

        // Ensure date fields are formatted to ISO 8601 strings
        $payload['requested_at'] = $this->ride->requested_at?->toIso8601String();
        $payload['accepted_at'] = $this->ride->accepted_at?->toIso8601String();
        $payload['picked_up_at'] = $this->ride->picked_up_at?->toIso8601String();
        $payload['completed_at'] = $this->ride->completed_at?->toIso8601String();
        $payload['canceled_at'] = $this->ride->canceled_at?->toIso8601String();

        // Ensure numeric fields are cast to float for consistency
        $payload['fare_amount'] = (float) $payload['fare_amount'];
        $payload['distance_km'] = (float) $payload['distance_km'];
        $payload['duration_minutes'] = (float) $payload['duration_minutes'];
        $payload['rider_rating'] = (float) $payload['rider_rating'] ?? null;
        $payload['driver_rating'] = (float) $payload['driver_rating'] ?? null;
        $payload['search_radius_km'] = (int) $payload['search_radius_km']; // Cast to int if appropriate

        Log::info('Broadcasting RideStatusUpdated (Full Payload)', $payload);
        return $payload;
    }
}