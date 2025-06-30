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
            ['id' => 4, 'name' => 'Passenger Picked Up'],
            ['id' => 5, 'name' => 'Completed'],
            ['id' => 6, 'name' => 'Cancelled'],
        ];

        DB::table('ride_statuses')->insert($statuses);
    }
}
