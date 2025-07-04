<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Ride;
use App\Models\RideRejection;
use App\Events\RideRequested;
use App\Enums\RideStatus;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Services\DriverMatchingService;

class RideController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'pickup_address' => 'required|string|max:255',
            'pickup_latitude' => 'required|numeric|between:-90,90',
            'pickup_longitude' => 'required|numeric|between:-180,180',
            'dropoff_address' => 'required|string|max:255',
            'dropoff_latitude' => 'required|numeric|between:-90,90',
            'dropoff_longitude' => 'required|numeric|between:-180,180',
            'requested_at' => 'required|date',
            'distance_km' => 'required|numeric|min:0',
            'duration_minutes' => 'required|numeric|min:0',
            'fare_amount' => 'required|numeric|min:0',
            'ride_status_id' => 'required|exists:ride_statuses,id',
            'payment_method' => 'nullable|string|max:50',
            'search_radius_km' => 'nullable|integer|min:1|max:100',
        ]);

        $pickupLat = $validated['pickup_latitude'];
        $pickupLng = $validated['pickup_longitude'];
        $maxUserRadius = $validated['search_radius_km'] ?? 10;

        $matcher = app(DriverMatchingService::class);
        $initialRadius = 1;
        $matchingRadiusUsed = $initialRadius;

        $drivers = $matcher->findNearbyDrivers($pickupLat, $pickupLng, $initialRadius);
        Log::info('Initial driver search', ['radius_km' => $initialRadius, 'drivers' => $drivers->pluck('id')]);

        if ($drivers->isEmpty()) {
            for ($radius = $initialRadius + 1; $radius <= $maxUserRadius; $radius++) {
                $drivers = $matcher->findNearbyDrivers($pickupLat, $pickupLng, $radius);
                Log::info("Expanded driver search (radius {$radius} km)", ['drivers' => $drivers->pluck('id')]);

                if ($drivers->isNotEmpty()) {
                    $matchingRadiusUsed = $radius;
                    break;
                }
            }
        }

        if ($drivers->isEmpty()) {
            return response()->json(['message' => "No drivers available within {$maxUserRadius} km."], 202);
        }

        $ride = Ride::create([
            ...$validated,
            'user_id' => $request->user()->id,
            'search_radius_km' => $matchingRadiusUsed,
            'assigned_driver_id' => $drivers->first()->id,
        ]);

        event(new RideRequested($ride, $drivers->first()));

        return response()->json([
            'message' => 'Ride created and driver notified.',
            'ride' => $ride,
            'notified_drivers' => $drivers->pluck('id'),
        ], 201);
    }

    public function cancel(Request $request)
    {
        $request->validate(['ride_id' => 'required|exists:rides,id']);

        $ride = Ride::where('id', $request->ride_id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $ride->update([
            'ride_status_id' => RideStatus::CANCELLED,
            'canceled_at' => now(),
        ]);

        return response()->json(['message' => 'Ride cancelled successfully.'], 200);
    }

    public function accept($id)
    {
        $driver = Auth::user();

        $ride = Ride::where('id', $id)
            ->where('ride_status_id', RideStatus::REQUESTED)
            ->first();

        if (!$ride) {
            return response()->json(['message' => 'Ride already taken or unavailable.'], 409);
        }

        $ride->update([
            'driver_id' => $driver->id,
            'ride_status_id' => RideStatus::ACCEPTED,
            'accepted_at' => now(),
        ]);

        return response()->json([
            'message' => 'Ride accepted.',
            'ride' => $ride->load(['driver:id,name', 'user:id,name', 'status:id,name']),
        ]);
    }

    public function reject(Ride $ride)
    {
        $user = Auth::user();

        if (!$user || !$user->profile || $user->profile->status->name !== 'approved') {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if ($ride->ride_status_id !== RideStatus::REQUESTED) {
            return response()->json(['message' => 'Ride is not in a rejectable state.'], 409);
        }

        $ride->update(['assigned_driver_id' => null]);

        RideRejection::firstOrCreate([
            'ride_id' => $ride->id,
            'driver_id' => $user->id,
        ]);

        $matcher = app(DriverMatchingService::class);
        $nearbyDrivers = $matcher->findNearbyDrivers(
            $ride->pickup_latitude,
            $ride->pickup_longitude,
            $ride->search_radius_km
        )->reject(fn($driver) => $ride->rejections->pluck('driver_id')->contains($driver->id));

        foreach ($nearbyDrivers as $driver) {
            event(new RideRequested($ride, $driver));
        }

        return response()->json(['message' => 'Ride rejected and reassigned to nearby drivers.']);
    }

    public function show($id)
    {
        if (!is_numeric($id)) {
            return response()->json(['error' => 'Invalid ride ID'], 400);
        }

        $ride = Ride::with([
            'driver:id,name',
            'user:id,name,email',
            'status:id,name',
        ])->findOrFail($id);

        Log::info('Ride fetched', ['ride_id' => $ride->id]);

        return response()->json($ride);
    }

    public function ongoing()
    {
        $userId = Auth::id();

        $rides = Ride::with([
            'driver:id,name',
            'user:id,name',
            'status:id,name',
        ])
        ->select([
            'id', 'user_id', 'driver_id', 'status_id',
            'pickup_address', 'dropoff_address', 'requested_at',
        ])
        ->where('user_id', $userId)
        ->whereIn('ride_status_id', [
            RideStatus::ACCEPTED,
            RideStatus::DRIVER_EN_ROUTE,
            RideStatus::RIDE_IN_PROGRESS,
        ])
        ->get();

        return response()->json(['rides' => $rides]);
    }

    public function start($id, Request $request)
    {
        $user = Auth::user();
        $ride = Ride::find($id);

        if (!$ride) return response()->json(['message' => 'Ride not found.'], 404);
        if ($ride->driver_id !== $user->id) return response()->json(['message' => 'Unauthorized.'], 403);

        $statusId = $request->input('status_id');

        if (!in_array($statusId, [RideStatus::DRIVER_EN_ROUTE, RideStatus::RIDE_IN_PROGRESS])) {
            return response()->json(['message' => 'Invalid status transition.'], 400);
        }

        if (
            ($statusId === RideStatus::DRIVER_EN_ROUTE && $ride->ride_status_id !== RideStatus::ACCEPTED) ||
            ($statusId === RideStatus::RIDE_IN_PROGRESS && !in_array($ride->ride_status_id, [RideStatus::ACCEPTED, RideStatus::DRIVER_EN_ROUTE]))
        ) {
            return response()->json(['message' => 'Invalid status change for current ride state.'], 400);
        }

        $ride->ride_status_id = $statusId;
        if ($statusId === RideStatus::RIDE_IN_PROGRESS) {
            $ride->picked_up_at = now();
        }
        $ride->save();

        return response()->json([
            'message' => 'Ride status updated.',
            'ride' => $ride,
        ]);
    }

    public function complete($id)
    {
        $user = Auth::user();
        $ride = Ride::find($id);

        if (!$ride) return response()->json(['message' => 'Ride not found.'], 404);
        if ($ride->driver_id !== $user->id) return response()->json(['message' => 'Unauthorized.'], 403);

        $ride->update([
            'ride_status_id' => RideStatus::COMPLETED,
            'completed_at' => now(),
        ]);

        return response()->json([
            'message' => 'Ride completed successfully.',
            'ride' => $ride,
        ]);
    }
}
