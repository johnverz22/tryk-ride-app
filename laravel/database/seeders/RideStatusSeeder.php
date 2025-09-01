<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RideStatusSeeder extends Seeder
{
    /**
     * Run the database seeder.
     */
    public function run(): void
    {
        $statuses = [
            ['status' => 'requested'],
            ['status' => 'accepted'],
            ['status' => 'driver_en_route'],
            ['status' => 'arrived'],
            ['status' => 'in_progress'],
            ['status' => 'completed'],
            ['status' => 'cancelled'],
        ];

        DB::table('ride_statuses')->insert($statuses);
    }
}