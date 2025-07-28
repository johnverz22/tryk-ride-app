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
use App\Events\DriverLocationUpdated;

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

        $drivers = $matcher->findNextAvailableDriver(
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
            ->get();

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

        // 🔹 Validate the 'range' parameter, defaulting to 'week' if not provided.
        $range = $request->query('range', 'week');
        if (!in_array($range, ['day', 'week', 'month'])) {
            return response()->json(['error' => 'Invalid range. Use day, week, or month.'], 400);
        }

        $now = Carbon::now();

        // 🔹 Define the date range for the main query.
        $startDate = match ($range) {
            'day'   => $now->copy()->startOfDay(),
            'week'  => $now->copy()->startOfWeek(Carbon::MONDAY), // Explicitly set Monday as start of the week
            'month' => $now->copy()->startOfMonth(),
        };

        // Always query up to the current moment to include all completed rides.
        $endDate = $now->copy();

        // 🔹 Fetch all relevant rides in a single, efficient query.
        $rides = Ride::where('driver_id', $driver->id)
            ->where('is_paid', true)
            ->whereNotNull('completed_at')
            ->whereBetween('completed_at', [$startDate, $endDate])
            ->get();

        // --- 1. Calculate Base Statistics ---
        $totalTrips = $rides->count();
        $totalEarnings = $rides->sum('fare_amount');
        $averageFare = $totalTrips > 0 ? round($totalEarnings / $totalTrips, 2) : 0;
        // Calculate rating only on rides that actually have a rating to avoid diluting the average.
        $averageRating = $rides->whereNotNull('rider_rating')->avg('rider_rating');


        // --- 2. Prepare Chart-Specific Data ---
        $chartData = [];

        switch ($range) {
            case 'day':
                // Group rides by the hour of the day (0-23).
                $ridesByHour = $rides->groupBy(fn($ride) => $ride->completed_at->hour);

                // Initialize an array of 24 hours with 0.0 earnings.
                $hourlyEarnings = array_fill(0, 24, 0.0);

                // Populate the array with the summed fare for each hour that has earnings.
                foreach ($ridesByHour as $hour => $ridesInHour) {
                    $hourlyEarnings[$hour] = round($ridesInHour->sum('fare_amount'), 2);
                }
                $chartData['hourly_earnings'] = $hourlyEarnings;
                break;

            case 'week':
                // Group rides by the day of the week (0=Mon, 1=Tue, ..., 6=Sun).
                $ridesByDay = $rides->groupBy(fn($ride) => $ride->completed_at->dayOfWeekIso - 1);

                // Initialize an array of 7 days with 0.0 earnings.
                $dailyEarnings = array_fill(0, 7, 0.0);

                // Populate the array for each day that has earnings.
                foreach ($ridesByDay as $dayIndex => $ridesInDay) {
                    $dailyEarnings[$dayIndex] = round($ridesInDay->sum('fare_amount'), 2);
                }
                $chartData['daily_earnings'] = $dailyEarnings;
                break;

            case 'month':
                // Group rides by the week number within the current month (0-indexed).
                $ridesByWeek = $rides->groupBy(fn($ride) => $ride->completed_at->weekOfMonth - 1);

                // Determine the total number of weeks in the current month to create the array.
                $weeksInMonth = $now->copy()->endOfMonth()->weekOfMonth;
                // Initialize an array for each week with 0.0 earnings.
                $monthlyEarningsByWeek = array_fill(0, $weeksInMonth, 0.0);

                // Populate the array for each week that has earnings.
                foreach ($ridesByWeek as $weekIndex => $ridesInWeek) {
                    $monthlyEarningsByWeek[$weekIndex] = round($ridesInWeek->sum('fare_amount'), 2);
                }
                $chartData['monthly_earnings_by_week'] = $monthlyEarningsByWeek;
                break;
        }

        // --- 3. Construct and Return the Final JSON Response ---
        $baseResponse = [
            'total_earnings' => $totalEarnings,
            'total_trips' => $totalTrips,
            'average_fare' => $averageFare,
            // Ensure rating is a number, defaulting to 0 if null.
            'average_rating' => round($averageRating ?? 0, 1),
        ];

        // Merge the base stats with the dynamically generated chart data.
        $finalResponse = array_merge($baseResponse, $chartData);
        
        return response()->json($finalResponse);
    }

    public function updateLocation(Request $request)
    {
        $user = $this->getAuthUser();  // Assuming this fetches the authenticated user
        $driverProfile = $this->getDriverProfile($user); // This should return the authenticated driver's profile
        
        // Validate the incoming request data
        $request->validate([
            'ride_id' => 'required|exists:rides,id',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);
        
        // Assuming $driverProfile is the Driver model, fetch the ride associated with the driver
        $ride = Ride::findOrFail($request->ride_id);
        
        // Check if the driver is associated with the ride, if not return an error
        if ($ride->driver_id !== $driverProfile->id) {
            return response()->json(['error' => 'This ride does not belong to the authenticated driver.'], 403);
        }

        // Update the driver's current location
        if ($driverProfile) {
            $driverProfile->update([
                'current_latitude' => $request->latitude,
                'current_longitude' => $request->longitude,
            ]);
        }

        // Broadcasting the updated location using the event
        broadcast(new DriverLocationUpdated(
            $driverProfile,        // Pass the full driver model
            $ride,                 // Pass the ride model
            $request->latitude,   // Pass latitude
            $request->longitude   // Pass longitude
        ))->toOthers();  // Broadcast to others, excluding the sender
        
        return response()->json(['message' => 'Location updated successfully']);
    }
}
