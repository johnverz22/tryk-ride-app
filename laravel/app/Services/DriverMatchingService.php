<?php

namespace App\Services;

use App\Enums\RideStatus;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DriverMatchingService
{
    /**
     * Finds the single nearest, available driver for an exclusive offer.
     *
     * @param float $latitude
     * @param float $longitude
     * @param int $radiusInKm
     * @param array $excludedDriverIds Drivers to ignore in the search
     * @return User|null
     */
    public function findNextAvailableDriver(float $latitude, float $longitude, int $radiusInKm, array $excludedDriverIds = []): ?User
    {
        // THE FIX: Note the use of `driver_profiles.current_latitude` etc.
        $haversine = "(6371 * acos(cos(radians(?)) * cos(radians(driver_profiles.current_latitude)) * cos(radians(driver_profiles.current_longitude) - radians(?)) + sin(radians(?)) * sin(radians(driver_profiles.current_latitude))))";

        $busyDriverIds = DB::table('rides')
            ->where('ride_status_id', RideStatus::OFFERED)
            ->whereNotNull('assigned_driver_id')
            ->pluck('assigned_driver_id');

        $allExcludedIds = collect($excludedDriverIds)->merge($busyDriverIds)->unique()->toArray();

        $driver = User::query()
            ->where('role_id', 3)
            // THE FIX: Use `join` to make the profile and status columns available.
            ->join('driver_profiles', 'users.id', '=', 'driver_profiles.user_id')
            ->join('driver_statuses', 'driver_profiles.driver_status_id', '=', 'driver_statuses.id')
            // Now we can use simple `where` clauses on the joined tables.
            ->where('driver_profiles.is_online', true)
            ->where('driver_statuses.name', 'approved')
            ->whereNotIn('users.id', $allExcludedIds)
            ->select('users.*') // Select all columns from the users table to hydrate the User model
            ->selectRaw("$haversine AS distance", [$latitude, $longitude, $latitude])
            ->whereRaw("$haversine < ?", [$latitude, $longitude, $latitude, $radiusInKm])
            ->orderBy('distance', 'asc')
            ->first();

        Log::info('Next available driver search executed', [
            'latitude' => $latitude,
            'longitude' => $longitude,
            'excluded_ids' => $allExcludedIds,
            'found_driver' => $driver?->id,
        ]);

        return $driver;
    }

    /**
     * Finds ALL nearby drivers for the public pool broadcast.
     *
     * @param float $latitude
     * @param float $longitude
     * @param int $radiusInKm
     * @return Collection
     */
    public function findAllNearbyDriversForPool(float $latitude, float $longitude, int $radiusInKm): Collection
    {
        // THE FIX: Same changes applied here.
        $haversine = "(6371 * acos(cos(radians(?)) * cos(radians(driver_profiles.current_latitude)) * cos(radians(driver_profiles.current_longitude) - radians(?)) + sin(radians(?)) * sin(radians(driver_profiles.current_latitude))))";

        return User::query()
            ->where('role_id', 3)
            ->join('driver_profiles', 'users.id', '=', 'driver_profiles.user_id')
            ->where('driver_profiles.is_online', true)
            ->select('users.*')
            ->selectRaw("$haversine AS distance", [$latitude, $longitude, $latitude])
            ->whereRaw("$haversine < ?", [$latitude, $longitude, $latitude, $radiusInKm])
            ->orderBy('distance', 'asc')
            ->get();
    }
}