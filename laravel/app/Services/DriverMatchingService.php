<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Log;

class DriverMatchingService
{
    public function findNearbyDrivers($latitude, $longitude, $radiusInKm = 10)
    {
        $haversine = "(6371 * acos(
            cos(radians(?)) *
            cos(radians(current_latitude)) *
            cos(radians(current_longitude) - radians(?)) +
            sin(radians(?)) *
            sin(radians(current_latitude))
        ))";

        $drivers = User::whereHas('profile.status', function ($query) {
                    $query->where('name', 'approved');
                })
                ->whereHas('profile', function ($query) use ($haversine, $latitude, $longitude, $radiusInKm) {
                    $query->whereRaw("$haversine < ?", [$latitude, $longitude, $latitude, $radiusInKm])
                        ->orderByRaw("$haversine ASC", [$latitude, $longitude, $latitude]);
                })
                ->with('profile.status')
                ->get();

        // 📋 Log here
        Log::info('Matching drivers found', [
            'radius_km' => $radiusInKm,
            'lat' => $latitude,
            'lng' => $longitude,
            'driver_ids' => $drivers->pluck('id'),
            'total_found' => $drivers->count()
        ]);

        return $drivers;
    }
}
