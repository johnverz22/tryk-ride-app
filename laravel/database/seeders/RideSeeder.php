<?php

namespace Database\Seeders;

use App\Models\Ride;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class RideSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Ensure there are users and a ride status
        $user = User::first();
        $driver = User::where('id', '!=', $user->id)->inRandomOrder()->first();
        $rideStatusId = 2; // or random from your ride_statuses table

        Ride::create([
            'user_id' => $user->id,
            'driver_id' => $driver?->id,
            'assigned_driver_id' => $driver?->id,
            'ride_status_id' => $rideStatusId,

            'pickup_address' => 'San Fernando Plaza Waiting Shed, La Union, PH',
            'pickup_latitude' => 16.6155,
            'pickup_longitude' => 120.317,

            'dropoff_address' => '42 San Fernando By-Pass Rd, La Union, PH',
            'dropoff_latitude' => 16.614,
            'dropoff_longitude' => 120.32,

            'requested_at' => Carbon::now()->subMinutes(10),
            'accepted_at' => Carbon::now()->subMinutes(8),
            'picked_up_at' => Carbon::now()->subMinutes(5),
            'completed_at' => Carbon::now()->subMinutes(1),
            'canceled_at' => null,

            'start_requested_at' => Carbon::now()->subMinutes(7),
            'completion_requested_at' => Carbon::now()->subMinutes(2),

            'distance_km' => 0.783,
            'duration_minutes' => 3,
            'fare_amount' => 6.57,
            'payment_method' => 'Cash',
            'search_radius_km' => 1,
            'is_paid' => false,

            // 'rider_rating' => 5,
            // 'rider_review' => 'Quick and friendly.',
            // 'driver_rating' => 5,
            // 'driver_review' => 'Passenger was polite.',

            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
