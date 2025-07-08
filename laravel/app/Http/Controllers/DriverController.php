<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Models\Ride;
use App\Enums\RideStatus;
use App\Services\DriverMatchingService;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DriverController extends Controller
{
    private function getAuthUser(): User
    {
        return Auth::user();
    }

    private function getDriverProfile($user)
    {
        $profile = $user->loadMissing('profile')->profile;

        if (!$profile) {
            abort(response()->json(['message' => 'Driver profile not found.'], 404));
        }

        return $profile;
    }

    public function update(Request $request)
    {
        $user = $this->getAuthUser();

        $validated = $request->validate([
            'name'  => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', Rule::unique('users')->ignore($user->id)],
            'phone' => ['nullable', 'string', Rule::unique('users')->ignore($user->id)],
        ]);

        Log::info('Updating user profile', [
            'user_id' => $user->id,
            'fields' => array_keys($validated),
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => [
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
            ],
        ]);
    }

    public function serveImage($userId, $filename)
    {
        $path = storage_path("app/public/driver_documents/{$userId}/{$filename}");

        if (!file_exists($path)) {
            abort(404, 'Image not found');
        }

        return response()->file($path, ['Cache-Control' => 'no-cache']);
    }

    public function getDocuments(Request $request)
    {
        $user = $this->getAuthUser();
        $profile = $this->getDriverProfile($user);

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
        $user = $this->getAuthUser();

        $validated = $request->validate([
            'type' => 'required|in:id,license',
            'document' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120',
        ]);

        $file = $validated['document'];
        $filename = "{$validated['type']}." . $file->getClientOriginalExtension();
        $path = $file->storeAs("driver_documents/{$user->id}", $filename, 'public');

        $profile = $user->profile()->firstOrCreate(
            ['user_id' => $user->id],
            ['driver_status_id' => 1]
        );

        // Delete old document if exists
        if ($validated['type'] === 'id' && $profile->id_document_path) {
            Storage::disk('public')->delete($profile->id_document_path);
            $profile->id_document_path = $path;
        } elseif ($validated['type'] === 'license' && $profile->license_document_path) {
            Storage::disk('public')->delete($profile->license_document_path);
            $profile->license_document_path = $path;
        }

        $profile->save();

        Log::info('Document uploaded', [
            'user_id' => $user->id,
            'type' => $validated['type'],
            'stored_path' => $path,
        ]);

        return response()->json([
            'message' => 'Document uploaded successfully',
            'path' => $path,
        ]);
    }

    public function submitVerification(Request $request)
    {
        $user = $this->getAuthUser();
        $profile = $this->getDriverProfile($user);

        $profile->update(['driver_status_id' => 2]);

        return response()->json(['message' => 'Verification submitted. Status set to pending.']);
    }

    public function requestedRides(Request $request)
    {
        Log::info('Auth Header', ['token' => $request->header('Authorization')]);
        Log::info('User', ['user' => Auth::user()]);
        $user = $this->getAuthUser();
        $profile = $this->getDriverProfile($user)->loadMissing('status');

        if ($profile->status->name !== 'approved') {
            return response()->json([
                'message' => 'Only approved drivers can view ride requests.'
            ], 403);
        }

        $rides = Ride::with(['rejections' => fn($q) => $q->where('driver_id', $user->id)])
            ->where('ride_status_id', RideStatus::REQUESTED)
            ->where(function ($query) use ($user) {
                $query->where('driver_id', $user->id)
                    ->orWhere(function ($q) use ($user) {
                        $q->whereNull('driver_id')
                            ->whereDoesntHave('rejections', fn($r) => $r->where('driver_id', $user->id));
                    });
            })
            ->get();

        return response()->json([
            'rides' => $rides,
        ]);
    }

    public function updateLocation(Request $request)
    {
        $user = $this->getAuthUser();
        $profile = $this->getDriverProfile($user);

        $validated = $request->validate([
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'is_online' => 'sometimes|boolean',
        ]);

        $profile->update([
            'current_latitude' => $validated['latitude'],
            'current_longitude' => $validated['longitude'],
            'is_online' => $validated['is_online'] ?? $profile->is_online,
        ]);

        return response()->json([
            'message' => 'Location updated',
            'latitude' => $profile->current_latitude,
            'longitude' => $profile->current_longitude,
            'is_online' => $profile->is_online,
        ]);
    }

    public function requestRide(Request $request, DriverMatchingService $matcher)
    {
        $user = $this->getAuthUser();

        $validated = $request->validate([
            'pickup_latitude' => 'required|numeric|between:-90,90',
            'pickup_longitude' => 'required|numeric|between:-180,180',
            'dropoff_latitude' => 'required|numeric|between:-90,90',
            'dropoff_longitude' => 'required|numeric|between:-180,180',
            'pickup_address' => 'required|string|max:255',
            'dropoff_address' => 'required|string|max:255',
        ]);

        $drivers = $matcher->findNearbyDrivers(
            $validated['pickup_latitude'],
            $validated['pickup_longitude'],
            10
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
        $user = $this->getAuthUser();
        $profile = $this->getDriverProfile($user);

        $profile->update(['is_online' => false]);

        return response()->json(['message' => 'Driver is now offline.']);
    }

    public function getLocation(Request $request, $rideId)
    {
        $ride = Ride::with('driver.profile')->findOrFail($rideId);

        if (!$ride->driver || !$ride->driver->profile) {
            Log::warning("Ride ID {$rideId} has no assigned driver or driver profile.");
            return response()->json(['error' => 'Driver not assigned or profile missing'], 404);
        }

        $profile = $ride->driver->profile;

        return response()->json([
            'latitude' => $profile->current_latitude,
            'longitude' => $profile->current_longitude,
            'driver' => [
                'name' => $ride->driver->name,
                'plate' => $ride->driver->car_plate,
            ],
        ]);
    }

    public function trips(Request $request)
    {
        $user = $this->getAuthUser();

        try {
            $trips = Ride::with([
                'user:id,name,email',
                'status:id,name',
            ])
            ->where('driver_id', $user->id)
            ->latest('requested_at')
            ->get([
                'id', 'user_id', 'ride_status_id', 'pickup_address', 'dropoff_address', 'requested_at'
            ]);

            Log::info('Fetched driver trips', [
                'driver_id' => $user->id,
                'count' => $trips->count(),
            ]);

            return response()->json($trips);
        } catch (\Exception $e) {
            Log::error('Failed to fetch driver trips', [
                'driver_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
            return response()->json(['error' => 'Could not fetch trips'], 500);
        }
    }

    public function earningsSummary(Request $request)
{
    $driver = $request->user();

    // Validate query param
    $range = $request->query('range', 'day'); // default: day
    if (!in_array($range, ['day', 'week', 'month'])) {
        return response()->json(['error' => 'Invalid range. Use day, week, or month.'], 400);
    }

    // Define date range
    $startDate = match ($range) {
        'day' => Carbon::today(),
        'week' => Carbon::now()->startOfWeek(),
        'month' => Carbon::now()->startOfMonth(),
    };
    $endDate = Carbon::now();

    // Get completed, paid rides
    $rides = DB::table('rides')
        ->where('driver_id', $driver->id)
        ->where('is_paid', true)
        ->whereNotNull('completed_at')
        ->whereBetween('completed_at', [$startDate, $endDate])
        ->get();

    // Calculate stats
    $totalTrips = $rides->count();
    $totalEarnings = $rides->sum('fare_amount');
    $averageFare = $totalTrips > 0 ? round($totalEarnings / $totalTrips, 2) : 0;

    return response()->json([
        'range' => $range,
        'total_trips' => $totalTrips,
        'average_fare' => $averageFare,
        'total_earnings' => $totalEarnings,
    ]);
}
}
