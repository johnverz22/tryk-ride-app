<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RideStatusSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('ride_statuses')->truncate(); // Clears existing data

        $statuses = [
            ['id' => 1, 'name' => 'Requested'],
            ['id' => 2, 'name' => 'Accepted'],
            ['id' => 3, 'name' => 'Driver En Route'],
            ['id' => 4, 'name' => 'Ride Started Awaiting User Confirmation'],
            ['id' => 5, 'name' => 'Ride in Progress'],
            ['id' => 6, 'name' => 'Ride Completed Awaiting User Confirmation'],
            ['id' => 7, 'name' => 'Completed'],
            ['id' => 8, 'name' => 'Cancelled'],
        ];

        DB::table('ride_statuses')->insert($statuses);
    }
}
