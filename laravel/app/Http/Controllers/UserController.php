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

        $rides = Ride::with('driver', 'status')
            ->where('user_id', $user->id)
            ->orderByDesc('requested_at')
            ->get()
            ->map(function ($ride) {
                $formatted = [
                    'id' => $ride->id,
                    'pickup_address' => $ride->pickup_address,
                    'dropoff_address' => $ride->dropoff_address,
                    'fare_amount' => $ride->fare_amount,
                    'payment_method' => $ride->payment_method,
                    'driver' => $ride->driver?->name,
                    'rider_rating' => $ride->rider_rating,
                    'status' => $ride->status ? [
                        'id' => $ride->status->id,
                        'name' => $ride->status->name,
                    ] : null,
                    'accepted_at' => $ride->accepted_at,
                    'completed_at' => $ride->completed_at,
                    'canceled_at' => $ride->canceled_at,
                    'requested_at' => $ride->requested_at,
                ];
            Log::info("Trips Details", ['trips' => $formatted]);

                return $formatted;
            });
        
        return response()->json($rides);
    }
}
