<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\User;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Validation\ValidationException;

class UserController extends Controller
{
    public function update(Request $request)
    {
        Log::info('HIT User update controller', $request->all());

        $user = Auth::user();

        $validated = $request->validate([
            'fullName'        => 'required|string|max:255',
            'email'           => ['required', 'email', Rule::unique('users')->ignore($user->id)],
            'phoneNumber'     => 'nullable|string|max:20',
            'location'        => 'nullable|string|max:255',
            'profile_picture' => 'nullable|url',
        ]);

        // $user->update([
        //     // 'name'            => $validated['fullName'],
        //     'email'           => $validated['email'],
        //     // 'phone'           => $validated['phoneNumber'] ?? $user->phone,
        //     // 'location'        => $validated['location'] ?? $user->location,
        //     // 'profile_picture' => $validated['profile_picture'] ?? $user->profile_picture,
        // ]);

        // $user->name = $validated['fullName'];
        $user->email = $validated['email'];
        // $user->phone = $validated['phoneNumber'] ?? $user->phone;
        // $user->location = $validated['location'] ?? $user->location;
        // $user->profile_picture = $validated['profile_picture'] ?? $user->profile_picture;

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user'    => $user,
        ]);
    }
}