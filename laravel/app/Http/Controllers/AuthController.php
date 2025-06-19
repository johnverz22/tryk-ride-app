<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use App\Models\User;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = Validator::make($request->all(), [
            'name'     => 'required|string',
            'email'    => 'required|email|unique:users',
            'password' => 'required|min:8',
            'role_id'  => 'required|in:2,3', // Only user or driver
        ])->validate();

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role_id'  => $validated['role_id'],
        ]);

        $accessToken = JWTAuth::fromUser($user);
        $refreshToken = Str::random(64);
        $user->refresh_token = Hash::make($refreshToken);
        $user->save();

        return response()
            ->json(['access_token' => $accessToken, 'user' => $user])
            ->cookie(
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

    public function login(Request $request)
    {
        $data = Validator::make($request->all(), [
            'email'    => 'required|email',
            'password' => 'required',
            'role_id'  => 'required|in:2,3',
        ])->validate();

        $user = User::where('email', $data['email'])->first();

        if (
            !$user ||
            !Hash::check($data['password'], $user->password) ||
            $user->role_id !== (int)$data['role_id']
        ) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect or unauthorized.'],
            ]);
        }

        $accessToken = JWTAuth::fromUser($user);
        $refreshToken = Str::random(64);
        $user->refresh_token = Hash::make($refreshToken);
        $user->save();

        return response()
            ->json(['access_token' => $accessToken, 'user' => $user])
            ->cookie(
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

        $user = User::whereNotNull('refresh_token')->get()->first(function ($u) use ($refreshToken) {
            return Hash::check($refreshToken, $u->refresh_token);
        });

        if (!$user) {
            return response()->json(['message' => 'Invalid refresh token'], 401);
        }

        $accessToken = JWTAuth::fromUser($user);
        $newRefreshToken = Str::random(64);
        $user->refresh_token = Hash::make($newRefreshToken);
        $user->save();

        return response()
            ->json(['access_token' => $accessToken])
            ->cookie(
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
        try {
            $user = JWTAuth::parseToken()->authenticate();
            $user->refresh_token = null;
            $user->save();
            JWTAuth::invalidate(JWTAuth::getToken());
        } catch (JWTException) {
            return response()->json(['message' => 'Token invalid or expired'], 400);
        }

        return response()
            ->json(['message' => 'Logged out'])
            ->withoutCookie('refresh_token');
    }
}
