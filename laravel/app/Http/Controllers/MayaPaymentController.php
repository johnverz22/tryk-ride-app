<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MayaPaymentController extends Controller
{
    public function createPayment(Request $request)
    {
        $amount = $request->amount ?? 100.00;

        $checkoutData = [
            "totalAmount" => [
                "value" => number_format($amount, 2, '.', ''),
                "currency" => "PHP"
            ],
            "buyer" => [
                "firstName" => "Juan",
                "lastName" => "Dela Cruz",
                "email" => "juan@example.com"
            ],
            "redirectUrl" => [
                "success" => "https://yourapp.com/payment-success",
                "failure" => "https://yourapp.com/payment-failed",
                "cancel" => "https://yourapp.com/payment-cancelled"
            ],
            "requestReferenceNumber" => "RIDE-" . uniqid(),
        ];

        $response = Http::withBasicAuth(
                env('MAYA_PUBLIC_KEY'),
                env('MAYA_SECRET_KEY')
            )
            ->post(env('MAYA_BASE_URL') . '/checkout/v1/checkouts', $checkoutData);

        if ($response->successful()) {
            return response()->json([
                'checkoutUrl' => $response['redirectUrl']
            ]);
        }

        return response()->json(['error' => 'Unable to create payment.'], 500);
    }

    public function webhook(Request $request)
    {
        Log::info('Maya Webhook:', $request->all());

        // Optional: validate signature

        $status = $request->input('paymentStatus');
        $ref = $request->input('requestReferenceNumber');

        if ($status === 'PAYMENT_SUCCESS') {
            // Update ride/payment status in DB
        }

        return response()->json(['message' => 'Webhook received']);
    }
}
