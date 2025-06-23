<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log;
use App\Models\User;
use Illuminate\Support\Facades\Storage;

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
            'id_document_url' => $profile->id_document_path ? url(Storage::url($profile->id_document_path)) : null,
            'license_document_url' => $profile->license_document_path ? url(Storage::url($profile->license_document_path)) : null,
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
}
