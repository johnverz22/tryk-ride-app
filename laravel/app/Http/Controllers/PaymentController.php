<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Wallet;
use App\Models\PaymentMethod;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $wallet = $user->wallet;
        $paymentMethods = $user->paymentMethods;

        $response = [
            'wallet' => $wallet ? $wallet->toArray() : null,
            'payment_methods' => $paymentMethods->map(function ($method) {
                return [
                    'id' => $method->id,
                    'type' => $method->type,
                    'provider' => $method->provider,
                    'last_four' => $method->last_four,
                    'label' => $method->label ?? null,
                ];
            }),
        ];

        return response()->json($response);
    }

    public function topUp(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
        ]);

        $wallet = $request->user()->wallet;
        $wallet->balance += $request->amount;
        $wallet->save();

        return response()->json(['message' => 'Wallet topped up', 'wallet' => $wallet]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'provider' => 'required|string',
            'token' => 'nullable|string',
            'type' => 'required|in:wallet,card',
            'last_four' => 'nullable|string|max:4',
            'expiry_month' => 'nullable|integer|between:1,12',
            'expiry_year' => 'nullable|integer|min:2023|max:2100',
            'is_default' => 'boolean',
        ]);

        $user = $request->user();

        if ($request->boolean('is_default')) {
            $user->paymentMethods()->update(['is_default' => false]);
        }

        $method = $user->paymentMethods()->create([
            'provider' => $request->provider,
            'token' => $request->token,
            'type' => $request->type,
            'last_four' => $request->last_four,
            'expiry_month' => $request->expiry_month,
            'expiry_year' => $request->expiry_year,
            'is_default' => $request->boolean('is_default'),
        ]);

        return response()->json([
            'message' => 'Payment method added',
            'method' => $method,
        ]);
    }

    public function update(Request $request, $id)
    {
        $method = $request->user()->paymentMethods()->findOrFail($id);

        $method->update($request->only(['provider', 'token', 'last_four', 'is_default']));

        return response()->json(['message' => 'Payment method updated', 'method' => $method]);
    }

    public function destroy(Request $request, $id)
    {
        $method = $request->user()->paymentMethods()->findOrFail($id);
        $method->delete();

        return response()->json(['message' => 'Payment method removed']);
    }
}
