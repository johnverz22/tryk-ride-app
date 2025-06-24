<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Ride;

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

        return response()->json([
            'message' => 'Ride created successfully',
            'ride' => $ride,
        ], 201);
    }
}
