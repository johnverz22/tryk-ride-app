<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log;
use App\Models\SavedLocation;
use App\Models\Ride;

class UserController extends Controller
{
    public function update(Request $request)
    {
        // Get the currently authenticated user via Sanctum
        $user = Auth::user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        // Validate incoming data
        $validated = $request->validate([
            'name'     => ['sometimes', 'string', 'max:255'],
            'email'    => ['sometimes', 'email', Rule::unique('users')->ignore($user->id)],
            'phone'    => ['nullable', 'string', Rule::unique('users')->ignore($user->id)],
            'location' => ['nullable', 'string'],
        ]);

        // Log the update attempt
        Log::info('Updating user profile', [
            'user_id' => $user->id,
            'validated_data' => $validated,
        ]);

        // Update the user only with provided fields
        $user->fill($validated);
        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user,
        ]);
    }

    public function savedLocations()
    {
        try {
            $user = Auth::user();
            $locations = SavedLocation::where('user_id', $user->id)->get();

            return response()->json($locations);
        } catch (\Exception $e) {
            Log::error('Failed to fetch saved locations', ['error' => $e->getMessage()]);
            return response()->json(['message' => 'Internal server error'], 500);
        }
    }

    public function userTrips(Request $request)
    {
            $user = Auth::user();

            if (!$user) {
                Log::warning('Attempted to fetch user trips without authentication.');
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $ridesPaginator = Ride::with(['driver', 'status'])
                ->where('user_id', $user->id)
                ->orderByDesc('requested_at')
                ->paginate(10);

            $formattedRides = $ridesPaginator->through(function ($ride) {
                $formatted = [
                    'id' => $ride->id,
                    'pickup_address' => $ride->pickup_address ?? 'N/A', // Null coalescing for safety
                    'dropoff_address' => $ride->dropoff_address ?? 'N/A', // Null coalescing for safety
                    'fare_amount' => (float) ($ride->fare_amount ?? 0.0), // Cast to float, default 0.0
                    'payment_method' => (string) ($ride->payment_method ?? 'Unknown'), // Cast to string, default 'Unknown'
                    'driver' => $ride->driver?->name, // Null-safe access to driver name
                    'rider_rating' => (int) ($ride->rider_rating ?? 0), // Cast to int, default 0
                    'status' => $ride->status ? [
                        'id' => $ride->status->id ?? null,
                        'name' => $ride->status->name ?? 'Unknown',
                    ] : null, // Ensure status is an object or null
                    'accepted_at' => $ride->accepted_at?->toIso8601String(), // Format dates, null-safe
                    'completed_at' => $ride->completed_at?->toIso8601String(),
                    'canceled_at' => $ride->canceled_at?->toIso8601String(),
                    'requested_at' => $ride->requested_at?->toIso8601String(),
                ];

                Log::info("Formatted Trip Item", ['item' => $formatted]);

                return $formatted;
            });

            Log::info("Paginated Trips Details", ['trips_data' => $formattedRides->toArray()]);

            return response()->json($formattedRides);
    }
}
