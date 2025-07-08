<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\DriverProfile;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DriverProfileSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Optional: Filter only users with driver role_id (if applicable)
        $drivers = User::where('role_id', 3)->get(); // Assuming role_id 3 = Driver
        $defaultStatusId = 1; // You may want to get an actual status from driver_statuses

        foreach ($drivers as $driver) {
            DriverProfile::updateOrCreate(
                ['user_id' => $driver->id],
                [
                    'driver_status_id' => $defaultStatusId,
                    'id_document_path' => 'documents/ids/' . Str::uuid() . '.jpg',
                    'license_document_path' => 'documents/licenses/' . Str::uuid() . '.jpg',
                    'current_latitude' => fake()->latitude(16.60, 16.62),
                    'current_longitude' => fake()->longitude(120.30, 120.32),
                    'is_online' => fake()->boolean(70), // 70% chance to be online
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }
}
