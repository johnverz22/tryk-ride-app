<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log;
use App\Models\User;
use Illuminate\Support\Facades\Storage;
use App\Models\Ride;
use App\Services\DriverMatchingService;
use Illuminate\Support\Facades\DB;

class DriverController extends Controller
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

    public function serveImage($userId, $filename)
    {
        $path = storage_path("app/public/driver_documents/{$userId}/{$filename}");

        if (!file_exists($path)) {
            abort(404, 'Image not found');
        }

        return response()->make(file_get_contents($path), 200, [
            'Content-Type' => mime_content_type($path),
            'Content-Length' => filesize($path),
            'Cache-Control' => 'no-cache',
        ]);
    }

    public function getDocuments(Request $request)
    {
        $user = Auth::user();
        $profile = $user->profile;

        if (!$profile) {
            return response()->json([
                'message' => 'Profile not found.'
            ], 404);
        }

        return response()->json([
            'id_document_url' => $profile->id_document_path 
                ? url("/driver-image/{$user->id}/" . basename($profile->id_document_path)) 
                : null,
            'license_document_url' => $profile->license_document_path 
                ? url("/driver-image/{$user->id}/" . basename($profile->license_document_path)) 
                : null,
            'submitted' => $profile->driver_status_id === 2,
        ]);
    }
    
    public function uploadDocument(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $request->validate([
            'type'     => 'required|in:id,license',
            'document' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120', // 5MB limit
        ]);

        $file = $request->file('document');

        $path = $file->storeAs(
            "driver_documents/{$user->id}",
            $request->type . '.' . $file->getClientOriginalExtension(),
            'public'
        );

        // Ensure profile() relation exists in User model
        $profile = $user->profile()->firstOrCreate(
            ['user_id' => $user->id],
            ['driver_status_id' => 1]
        );

        if ($request->type === 'id') {
            $profile->id_document_path = $path;
        } else {
            $profile->license_document_path = $path;
        }
        
        $profile->save();

        Log::info('Document uploaded', [
            'user_id' => $user->id,
            'type'    => $request->type,
            'path'    => $path,
        ]);

        return response()->json([
            'message' => 'Document uploaded successfully',
            'type'    => $request->type,
            'path'    => $path,
        ]);
    }

    public function submitVerification(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $profile = $user->profile()->first();

        if (!$profile) {
            return response()->json(['message' => 'Driver profile not found'], 404);
        }

        $profile->driver_status_id = 2;
        $profile->save();

        return response()->json([
            'message' => 'Verification submitted successfully. Status set to pending.',
            'status' => 'pending',
        ]);
    }

    public function requestedRides(Request $request)
    {
        $user = $request->user();

        $driverProfile = $user->profile;
        if (
            !$driverProfile ||
            !$driverProfile->relationLoaded('status') && !$driverProfile->load('status') ||
            $driverProfile->status->name !== 'approved'
        ) {
            return response()->json([
                'message' => 'Access denied. Only approved drivers can view ride requests.'
            ], 403);
        }

        // Fetch ride IDs this driver has rejected
        $rejectedRideIds = DB::table('ride_rejections')
            ->where('driver_id', $user->id)
            ->pluck('ride_id');

        $rides = Ride::with('user')
            ->whereHas('status', function ($query) {
                $query->where('name', 'Requested');
            })
            ->where(function ($query) use ($user) {
                $query->where('assigned_driver_id', $user->id)
                    ->orWhereNull('assigned_driver_id');
            })
            ->whereNull('driver_id')
            ->whereNotIn('id', $rejectedRideIds)
            ->latest()
            ->get([
                'id',
                'pickup_address',
                'pickup_latitude',
                'pickup_longitude',
                'dropoff_address',
                'dropoff_latitude',
                'dropoff_longitude',
                'requested_at',
                'ride_status_id',
                'fare_amount',
                'distance_km',
                'duration_minutes',
            ]);

        Log::info('Driver requested rides', [
            'driver_id' => $user->id,
            'ride_ids' => $rides->pluck('id'),
            'count' => $rides->count(),
        ]);
        
        return response()->json($rides);
    }
    
    public function updateLocation(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $validated = $request->validate([
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'is_online' => 'sometimes|boolean',
        ]);

        $profile = $user->profile;

        if (!$profile) {
            return response()->json(['message' => 'Driver profile not found.'], 404);
        }

        $profile->current_latitude = $validated['latitude'];
        $profile->current_longitude = $validated['longitude'];
        $profile->is_online =  $validated['is_online'];
        $profile->save();

        return response()->json([
            'message' => 'Location updated successfully',
            'latitude' => $profile->current_latitude,
            'longitude' => $profile->current_longitude,
            'is_online' => $profile->is_online,
        ]);
    }

    public function requestRide(Request $request, DriverMatchingService $matcher)
    {
        $user = Auth::user();

        // log the user
        Log::info('Ride request initiated', [
            'user_id' => $user ? $user->id : null,
            'request_data' => $request->all(),
        ]);

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $validated = $request->validate([
            'pickup_latitude'  => 'required|numeric|between:-90,90',
            'pickup_longitude' => 'required|numeric|between:-180,180',
            'dropoff_latitude' => 'required|numeric|between:-90,90',
            'dropoff_longitude'=> 'required|numeric|between:-180,180',
            'pickup_address'   => 'required|string|max:255',
            'dropoff_address'  => 'required|string|max:255',
        ]);

        // Find nearby drivers
        $drivers = $matcher->findNearbyDrivers(
            $validated['pickup_latitude'],
            $validated['pickup_longitude']
        );

        if ($drivers->isEmpty()) {
            return response()->json(['message' => 'No drivers available nearby'], 404);
        }
        
        return response()->json([
            'message' => 'Nearby drivers found',
            'drivers' => $drivers->pluck('id'),
        ]);
    }

    public function goOffline(Request $request)
    {
        $user = $request->user();

        if (!$user || !$user->profile) {
            return response()->json(['message' => 'Driver profile not found.'], 404);
        }

        $profile = $user->profile;
        $profile->is_online = false;
        $profile->save();

        return response()->json(['message' => 'Driver is now offline.']);
    }
}