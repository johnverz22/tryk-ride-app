<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DriverStatusesTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $statuses = [
            ['name' => 'onboarding', 'label' => 'Onboarding'],
            ['name' => 'pending', 'label' => 'Pending Approval'],
            ['name' => 'under_review', 'label' => 'Under Review'],
            ['name' => 'approved', 'label' => 'Approved'],
            ['name' => 'rejected', 'label' => 'Rejected'],
            ['name' => 'suspended', 'label' => 'Suspended'],
            ['name' => 'deactivated', 'label' => 'Deactivated'],
            ['name' => 'banned', 'label' => 'Banned'],
        ];

        DB::table('driver_statuses')->insert($statuses);
    }
}
