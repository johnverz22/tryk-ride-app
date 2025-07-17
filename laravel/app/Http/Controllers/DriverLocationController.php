<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver; // Import your Driver model
use App\Models\Ride;   // Import your Ride model
use App\Events\DriverLocationUpdated;
use Illuminate\Support\Facades\Auth;
use App\Models\User; // Import the base User model, if that's what Auth::user() returns

class DriverLocationController extends Controller
{
    public function updateLocation(Request $request)
    {
        // 1. Authenticate the user (who is a driver)
        // This will return an instance of the model configured for the 'driver' guard,
        // which you've indicated is NOT App\Models\Driver directly, but likely App\Models\User.
        /** @var User|null $authenticatedUser */ // Use a PHPDoc for better IDE hinting
        $authenticatedUser = Auth::guard('driver')->user();

        if (!$authenticatedUser) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        // 2. Explicitly retrieve the Driver model instance using the authenticated user's ID.
        // This is crucial because your Driver model has a global scope for role_id = 3.
        /** @var Driver|null $driver */ // PHPDoc for better IDE hinting
        $driver = Driver::find($authenticatedUser->id);

        if (!$driver) {
            // This means the authenticated user's ID does not correspond to a 'driver'
            // according to the Driver model's global scope (role_id = 3).
            return response()->json(['message' => 'Authenticated user is not a recognized driver.'], 403);
        }

        // 3. Validate incoming data
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'ride_id' => 'required|exists:rides,id', // Still need to associate with a ride
            'bearing' => 'nullable|numeric|between:0,360',
            'speed' => 'nullable|numeric|min:0',
        ]);

        // 4. Find the associated ride (crucial for channel name)
        $ride = Ride::find($request->ride_id);

        if (!$ride || $ride->driver_id !== $driver->id) {
            return response()->json(['message' => 'Ride not found or not assigned to this driver.'], 403);
        }

        // 5. Dispatch the broadcasting event directly with the received data
        // Now $driver is guaranteed to be of type App\Models\Driver, satisfying the event's type hint.
        event(new DriverLocationUpdated(
            $driver,
            $ride,
            $request->latitude,
            $request->longitude,
            $request->bearing,
            $request->speed
        ));

        return response()->json(['message' => 'Location broadcasted directly.']);
    }
}