<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use App\Models\User;
use App\Models\Wallet;
use App\Models\DriverStatus;
use App\Models\DriverProfile;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = Validator::make($request->all(), [
            'name'     => 'required|string',
            'email'    => 'required|email|unique:users',
            'password' => 'required|min:8',
            'role_id'  => 'required|in:2,3',
        ])->validate();

        DB::beginTransaction();

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role_id'  => $validated['role_id'],
        ]);

        if ($user->role_id === 3) {
            $pendingStatus = DriverStatus::where('name', 'onboarding')->firstOrFail()->id;

            DriverProfile::create([
                'user_id' => $user->id,
                'driver_status_id' => $pendingStatus,
            ]);
        }

        Wallet::create([
            'user_id' => $user->id,
            'balance' => 0.00, // or any default value you want
        ]);

        DB::commit();

        $accessToken = $user->createToken('flutter')->plainTextToken;
        $refreshToken = Str::random(64);
        $user->refresh_token = Hash::make($refreshToken);
        $user->save();

        return response()->json([
            'token' => $accessToken,
            'user'  => $user,
        ])->cookie(
            'refresh_token',
            $refreshToken,
            60 * 24 * 7, // 7 days
            '/',
            config('session.domain'),
            true,  // Secure
            true,  // HttpOnly
            false, // Raw
            'Strict'
        );
    }

    public function login(Request $request)
    {
        $credentials = $request->only('email', 'password');

        if (!Auth::attempt($credentials)) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $user = Auth::user();

        // Revoke previous tokens
        $user->tokens()->delete();

        $accessToken = $user->createToken('flutter')->plainTextToken;
        $refreshToken = Str::random(64);
        $user->refresh_token = Hash::make($refreshToken);
        $user->save();

        return response()->json([
            'token' => $accessToken,
            'user'  => $user,
        ])->cookie(
            'refresh_token',
            $refreshToken,
            60 * 24 * 7,
            '/',
            config('session.domain'),
            true,
            true,
            false,
            'Strict'
        );
    }

    public function refresh(Request $request)
    {
        $refreshToken = $request->cookie('refresh_token');

        if (!$refreshToken) {
            return response()->json(['message' => 'Refresh token missing'], 401);
        }

        $user = User::whereNotNull('refresh_token')->get()->first(function ($user) use ($refreshToken) {
            return Hash::check($refreshToken, $user->refresh_token);
        });

        if (!$user) {
            return response()->json(['message' => 'Invalid refresh token'], 401);
        }

        // Revoke old tokens and generate new ones
        $user->tokens()->delete();

        $newAccessToken = $user->createToken('flutter')->plainTextToken;
        $newRefreshToken = Str::random(64);
        $user->refresh_token = Hash::make($newRefreshToken);
        $user->save();

        return response()->json([
            'token' => $newAccessToken,
        ])->cookie(
            'refresh_token',
            $newRefreshToken,
            60 * 24 * 7,
            '/',
            config('session.domain'),
            true,
            true,
            false,
            'Strict'
        );
    }

    public function logout(Request $request)
    {
        $user = $request->user();

        // Revoke the current access token (requires Laravel Sanctum 3+)
        $request->user()->tokens()->delete();

        // Clear refresh token from DB
        $user->refresh_token = null;
        $user->save();

        return response()->json([
            'message' => 'Logged out',
        ])->withoutCookie('refresh_token');
    }
}
