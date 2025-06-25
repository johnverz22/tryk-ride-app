<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Ride;
use App\Events\RideRequested;
use App\Enums\RideStatus;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

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
        ]);

        $ride = Ride::create([
            'user_id' => $request->user()->id,
            'ride_status_id' => $request->ride_status_id,
            'pickup_address' => $request->pickup_address,
            'pickup_latitude' => $request->pickup_latitude,
            'pickup_longitude' => $request->pickup_longitude,
            'dropoff_address' => $request->dropoff_address,
            'dropoff_latitude' => $request->dropoff_latitude,
            'dropoff_longitude' => $request->dropoff_longitude,
            'requested_at' => $request->requested_at,
            'distance_km' => $request->distance_km,
            'duration_minutes' => $request->duration_minutes,
            'fare_amount' => $request->fare_amount,
            'payment_method' => $request->payment_method,
        ]);

        // // ✅ Fire the event
        // event(new RideRequested($ride));

        return response()->json([
            'message' => 'Ride created successfully',
            'ride' => $ride,
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
        $driver = Auth::user(); // assuming driver is authenticated

        // Only update the ride if it's still pending (ride_status_id = 1)
        $updated = DB::table('rides')
            ->where('id', $id)
            ->where('ride_status_id', 1) // 1 = Requested
            ->update([
                'driver_id' => $driver->id,
                'ride_status_id' => 2, // 2 = Accepted
                'accepted_at' => now(),
            ]);

        if ($updated) {
            return response()->json(['message' => 'Ride accepted successfully.'], 200);
        } else {
            return response()->json(['message' => 'Ride has already been taken.'], 409);
        }
    }

    public function show($id)
    {
        $ride = Ride::with(['driver', 'user', 'status'])->findOrFail($id);
        return response()->json(['ride' => $ride]);
    }
}
