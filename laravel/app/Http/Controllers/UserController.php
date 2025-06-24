<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log;
use App\Models\User;
use App\Models\SavedLocation;

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
}
