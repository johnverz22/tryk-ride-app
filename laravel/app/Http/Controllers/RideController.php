<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Ride;
use App\Models\RideRejection;
use App\Events\RideStatusUpdated;
use App\Events\RideCancelled;
use App\Events\NewRideOffer;
use App\Jobs\OfferRideToDrivers;
use App\Enums\RideStatus;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Services\RideService;
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
            'payment_method' => 'nullable|string|max:50',
            'search_radius_km' => 'nullable|integer|min:1|max:100',
        ]);

        $user = $request->user();

        // --- START: NEW, CLEANED-UP LOGIC ---
        DB::beginTransaction();
        try {
            // Step 1: Create the ride with a 'requested' status. No driver is assigned yet.
            $ride = Ride::create([
                ...$validated,
                'ride_status_id' => RideStatus::REQUESTED,
                'user_id' => $user->id,
                'search_radius_km' => $validated['search_radius_km'] ?? 100,
            ]);

            // Step 2: Handle wallet deduction if applicable.
            if (strtolower($ride->payment_method) === 'wallet') {
                $wallet = $user->wallet;
                if (!$wallet || $wallet->balance < $ride->fare_amount) {
                    DB::rollBack();
                    return response()->json(['message' => 'Insufficient wallet balance.'], 402);
                }
                $wallet->balance -= $ride->fare_amount;
                $wallet->save();
                $ride->update(['is_paid' => true]);
            }

            DB::commit();

            $matcher = app(DriverMatchingService::class);
            $primaryDriver = $matcher->findNextAvailableDriver(
                $validated['pickup_latitude'],
                $validated['pickup_longitude'],
                $validated['search_radius_km'] ?? 100,
                []
            );

            if ($primaryDriver) {
                $poolDrivers = $matcher->findAllNearbyDriversForPool(
                    $validated['pickup_latitude'],
                    $validated['pickup_longitude'],
                    $validated['search_radius_km'] ?? 100
                );
                OfferRideToDrivers::dispatch($ride, $primaryDriver, $poolDrivers);

                return response()->json([
                    'message' => 'Finding a driver for your ride...',
                    'ride' => $ride,
                ], 202); // 202 Accepted
            }

            $ride->update(['ride_status_id' => RideStatus::NO_DRIVERS_AVAILABLE]);
            return response()->json(['message' => "No drivers available at the moment."], 404);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Ride creation failed: ' . $e->getMessage(), ['exception' => $e]);
            return response()->json(['message' => 'Ride creation failed due to a server error.'], 500);
        }
    }

    public function cancel(Request $request)
    {
        $request->validate(['ride_id' => 'required|exists:rides,id']);

        $ride = Ride::where('id', $request->ride_id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        // THE FIX: Add RideStatus::OFFERED to the list of cancellable statuses.
        $cancellableStatuses = [
            RideStatus::REQUESTED,
            RideStatus::OFFERED,
            RideStatus::ACCEPTED
        ];

        if (!in_array($ride->ride_status_id, $cancellableStatuses)) {
            return response()->json(['message' => 'This ride can no longer be cancelled.'], 409);
        }

        DB::beginTransaction();
        try {
            $ride->update([
                'ride_status_id' => RideStatus::CANCELLED,
                'canceled_at' => now(),
            ]);

            // FEATURE: Refund wallet if the ride was paid for.
            if ($ride->is_paid && strtolower($ride->payment_method) === 'wallet') {
                $user = $request->user();
                $user->wallet()->increment('balance', $ride->fare_amount);
                
                // Set is_paid to false to indicate a refund.
                $ride->update(['is_paid' => false]);
                Log::info("Refunded {$ride->fare_amount} to user {$user->id} for cancelled ride {$ride->id}.");
            }
            
            DB::commit();

            // FEATURE: Notify the assigned/offered driver in real-time.
            // This prevents them from driving to a cancelled ride.
            event(new RideCancelled($ride));

            return response()->json(['message' => 'Ride cancelled successfully.'], 200);

        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error("Failed to cancel ride {$ride->id}: " . $e->getMessage());
            return response()->json(['message' => 'Failed to cancel ride.'], 500);
        }
    }

    public function accept($id, RideService $rideService)
    {
        $driver = Auth::user();
        $ride = Ride::find($id);

        if (!$ride) {
            return response()->json(['message' => 'Ride not found.'], 404);
        }

        $acceptedRide = $rideService->acceptRide($ride, $driver);

        if (!$acceptedRide) {
            return response()->json(['message' => 'This ride is no longer available for you to accept.'], 409);
        }

        return response()->json([
            'message' => 'Ride accepted.',
            'ride' => $acceptedRide->load(['driver:id,name', 'user:id,name', 'status:id,name']),
        ]);
    }

    public function reject(Ride $ride)
    {
        $rejectingDriver = Auth::user();

        // 1. Validate that this driver can actually reject this ride.
        if ($ride->ride_status_id !== RideStatus::OFFERED || $ride->assigned_driver_id !== $rejectingDriver->id) {
            return response()->json(['message' => 'This ride cannot be rejected by you.'], 409); // 409 Conflict
        }

        // 2. Log the rejection so we don't offer it to this driver again.
        RideRejection::create([
            'ride_id' => $ride->id,
            'driver_id' => $rejectingDriver->id,
        ]);

        // 3. Find the IDs of all drivers who have rejected this ride so far.
        $rejectedDriverIds = $ride->rejections()->pluck('driver_id')->toArray();

        // 4. Use the service to find the NEXT best driver, excluding all rejectors.
        $matcher = app(DriverMatchingService::class);
        $nextPrimaryDriver = $matcher->findNextAvailableDriver(
            $ride->pickup_latitude,
            $ride->pickup_longitude,
            $ride->search_radius_km,
            $rejectedDriverIds // Pass the list of drivers to exclude
        );

        // 5. Check if a new driver was found.
        if ($nextPrimaryDriver) {
            // --- A new driver was found, start the offer process for them ---
            Log::info("Driver {$rejectingDriver->id} rejected ride {$ride->id}. Offering to next driver {$nextPrimaryDriver->id}.");

            // We also need the full pool of drivers for the broadcast.
            $poolDrivers = $matcher->findAllNearbyDriversForPool(
                $ride->pickup_latitude,
                $ride->pickup_longitude,
                $ride->search_radius_km
            );
            
            // Dispatch the job to handle the exclusive offer logic cleanly.
            OfferRideToDrivers::dispatch($ride, $nextPrimaryDriver, $poolDrivers);

            return response()->json(['message' => 'Ride rejected. Offering to the next available driver.']);

        } else {
            // --- No other drivers were found ---
            Log::warning("No other drivers available for ride {$ride->id} after rejection by driver {$rejectingDriver->id}.");
            
            $ride->update([
                'assigned_driver_id' => null,
                'ride_status_id' => RideStatus::NO_DRIVERS_AVAILABLE,
            ]);

            // You might want to broadcast a cancellation event to the user here.

            return response()->json(['message' => 'Ride rejected. No other drivers were found.']);
        }
    }

    public function show($id)
    {
        if (!is_numeric($id)) {
            return response()->json(['error' => 'Invalid ride ID'], 400);
        }
        $ride = Ride::with(['driver:id,name', 'user:id,name,email', 'status:id,name'])->findOrFail($id);
        return response()->json($ride);
    }

    public function ongoing()
    {
        $user = Auth::user();
        $query = $user->is_driver ? ['driver_id', $user->id] : ['user_id', $user->id];

        $rides = Ride::with(['driver', 'user', 'status'])
                    ->whereIn('ride_status_id', [
                        RideStatus::ACCEPTED,
                        RideStatus::DRIVER_EN_ROUTE,
                        RideStatus::RIDE_IN_PROGRESS,
                    ])
                    ->where(...$query)
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

        event(new RideStatusUpdated($ride));

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
        
        event(new RideStatusUpdated($ride));

        return response()->json([
            'message' => 'Ride completed successfully.',
            'ride' => $ride,
        ]);
    }

    public function rateRide(Request $request, Ride $ride)
    {
        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'review' => 'nullable|string|max:1000',
        ]);

        // Optional: Check if the user is authorized to rate this ride
        if ($ride->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        // Prevent duplicate rating
        if ($ride->rider_rating !== null) {
            return response()->json(['message' => 'You have already rated this ride.'], 400);
        }

        $ride->update([
            'rider_rating' => $request->input('rating'),
            'rider_review' => $request->input('review'),
        ]);

        $ride->driver?->profile?->updateAverageRating();

        return response()->json(['message' => 'Rating submitted successfully.']);
    }
}
