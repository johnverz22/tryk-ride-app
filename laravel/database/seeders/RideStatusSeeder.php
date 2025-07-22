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
        DB::table('ride_statuses')->truncate();

        $statuses = [
            ['id' => 1, 'name' => 'Requested'],
            ['id' => 2, 'name' => 'Offered'],
            ['id' => 3, 'name' => 'Accepted'],
            ['id' => 4, 'name' => 'Driver En Route'],
            ['id' => 5, 'name' => 'Ride in Progress'],
            ['id' => 6, 'name' => 'Completed'],
            ['id' => 7, 'name' => 'Cancelled'],
            ['id' => 8, 'name' => 'No Drivers Available'],
        ];

        DB::table('ride_statuses')->insert($statuses);
    }
}
