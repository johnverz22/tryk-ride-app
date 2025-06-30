<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Ride;
use App\Events\RideRequested;
use App\Enums\RideStatus;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use App\Services\DriverMatchingService;
use Illuminate\Support\Facades\Log;
use App\Models\RideRejection; 

class RideController extends Controller
{

    public function store(Request $request)
    {
        $request->validate([
            'pickup_address' => 'required|string',
            'pickup_latitude' => 'required|numeric',
            'pickup_longitude' => 'required|numeric',
            'dropoff_address' => 'required|string',
            'dropoff_latitude' => 'required|numeric',
            'dropoff_longitude' => 'required|numeric',
            'requested_at' => 'required|date',
            'distance_km' => 'required|numeric',
            'duration_minutes' => 'required|numeric',
            'fare_amount' => 'required|numeric',
            'ride_status_id' => 'required|exists:ride_statuses,id',
            'payment_method' => 'nullable|string',
            'search_radius_km' => 'nullable|integer|min:1|max:100',
        ]);

        $pickupLat = $request->pickup_latitude;
        $pickupLng = $request->pickup_longitude;
        $maxUserRadius = (int) $request->input('search_radius_km', 10);
        $initialRadius = 1;
        $matchingRadiusUsed = $initialRadius;

        $matcher = app(DriverMatchingService::class);

        // Step 1: Try initial 5km search
        $drivers = $matcher->findNearbyDrivers($pickupLat, $pickupLng, $initialRadius);
        Log::info('Primary radius search', ['radius_km' => $initialRadius, 'drivers_found' => $drivers->pluck('id')]);

        // Step 2: Expand search up to user-defined radius
        if ($drivers->isEmpty()) {
            for ($radius = $initialRadius + 1; $radius <= $maxUserRadius; $radius++) {
                $drivers = $matcher->findNearbyDrivers($pickupLat, $pickupLng, $radius);
                Log::info('Fallback radius search', ['radius_km' => $radius, 'drivers_found' => $drivers->pluck('id')]);

                if ($drivers->isNotEmpty()) {
                    $matchingRadiusUsed = $radius;
                    break;
                }
            }
        }

        // Step 3: Abort if still no drivers found
        if ($drivers->isEmpty()) {
            return response()->json([
                'message' => "No drivers available within {$maxUserRadius} km. Ride not created."
            ], 202);
        }

        // Step 4: Create the ride
        $ride = Ride::create([
            'user_id' => $request->user()->id,
            'ride_status_id' => $request->ride_status_id,
            'pickup_address' => $request->pickup_address,
            'pickup_latitude' => $pickupLat,
            'pickup_longitude' => $pickupLng,
            'dropoff_address' => $request->dropoff_address,
            'dropoff_latitude' => $request->dropoff_latitude,
            'dropoff_longitude' => $request->dropoff_longitude,
            'requested_at' => $request->requested_at,
            'distance_km' => $request->distance_km,
            'duration_minutes' => $request->duration_minutes,
            'fare_amount' => $request->fare_amount,
            'payment_method' => $request->payment_method,
            'search_radius_km' => $matchingRadiusUsed,
        ]);

        $assignedDriver = $drivers->first();

        $ride->assigned_driver_id = $assignedDriver->id;
        $ride->save();

        // Notify assigned driver only
        event(new \App\Events\RideRequested($ride, $assignedDriver));

        return response()->json([
            'message' => 'Ride created and drivers notified.',
            'ride' => $ride,
            'notified_drivers' => $drivers->pluck('id'),
        ], 201);
    }


    public function cancel(Request $request)
    {
        $request->validate([
            'ride_id' => 'required|exists:rides,id',
        ]);

        $ride = Ride::where('id', $request->ride_id)
                    ->where('user_id', $request->user()->id)
                    ->firstOrFail();

        $ride->ride_status_id = 6;
        $ride->canceled_at = now();
        $ride->save();

        return response()->json(['message' => 'Ride cancelled successfully.'], 200);
    }

    public function accept($id)
    {
        $driver = Auth::user();

        // Only update the ride if it's still pending (ride_status_id = 1)
        $updated = DB::table('rides')
            ->where('id', $id)
            ->where('ride_status_id', 1)
            ->update([
                'driver_id' => $driver->id,
                'ride_status_id' => 2,
                'accepted_at' => now(),
            ]);

        if ($updated) {
            return response()->json(['message' => 'Ride accepted successfully.'], 200);
        } else {
            return response()->json(['message' => 'Ride has already been taken.'], 409);
        }
    }

    public function reject(Ride $ride)
    {
        $user = Auth::user();

        if (!$user || !$user->profile || $user->profile->status->name !== 'approved') {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if ($ride->assigned_driver_id !== $user->id) {
            return response()->json(['message' => 'You are not assigned to this ride.'], 403);
        }

        if ($ride->ride_status_id !== RideStatus::REQUESTED) {
            return response()->json(['message' => 'Ride is not in a rejectable state.'], 409);
        }

        // Unassign driver
        $ride->assigned_driver_id = null;
        $ride->save();

        // Record the rejection
        RideRejection::firstOrCreate([
            'ride_id' => $ride->id,
            'driver_id' => $user->id,
        ]);

        return response()->json(['message' => 'You rejected the ride. It is now visible to nearby drivers again.'], 200);
    }

    public function show($id)
    {
        if (!is_numeric($id)) {
            return response()->json(['error' => 'Invalid ride ID'], 400);
        }

        $ride = Ride::with(['driver', 'user', 'status'])->findOrFail($id);
        return response()->json(['ride' => $ride]);
    }
}
