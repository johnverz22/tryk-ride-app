<?php

namespace App\Http\Controllers;

use App\Models\SavedLocation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class SavedLocationController extends Controller
{
    // GET /user/saved-locations
    public function index()
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $locations = SavedLocation::where('user_id', $user->id)->get();

        return response()->json([
            'locations' => $locations,
        ]);
    }

    public function store(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $validated = $request->validate([
            'location_name' => 'required|string|max:255',
            'latitude'      => 'required|numeric|between:-90,90',
            'longitude'     => 'required|numeric|between:-180,180',
        ]);

        $location = SavedLocation::create([
            'user_id'       => $user->id,
            'location_name' => $validated['location_name'],
            'latitude'      => $validated['latitude'],
            'longitude'     => $validated['longitude'],
        ]);

        return response()->json([
            'message'  => 'Location saved successfully',
            'location' => $location,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $user = Auth::user();

        $location = SavedLocation::where('id', $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $validated = $request->validate([
            'location_name' => 'required|string|max:255',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $location->location_name = $validated['location_name'];
        $location->latitude = $validated['latitude'];
        $location->longitude = $validated['longitude'];
        $location->save();

        Log::info('Saved updated location:', $location->toArray());

        return response()->json([
            'message' => 'Location updated',
            'location' => $location,
        ]);
    }
    
    public function destroy($id)
    {
        $user = Auth::user();

        $location = SavedLocation::where('id', $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $location->delete();

        Log::info('Deleted location:', ['id' => $id, 'user_id' => $user->id]);

        return response()->json([
            'message' => 'Location deleted successfully',
        ]);
    }
}
