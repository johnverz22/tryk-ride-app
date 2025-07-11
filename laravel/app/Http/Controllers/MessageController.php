<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class MessageController extends Controller
{
    public function index($conversationId)
    {
        $conversation = Conversation::findOrFail($conversationId);

        if ($conversation->user_id !== Auth::id() && $conversation->driver_id !== Auth::id()) {
            abort(403, 'Unauthorized access to this conversation.');
        }

        return $conversation->messages()
            ->with('sender')
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public function store(Request $request, $conversationId)
    {
        $request->validate([
            'message' => 'required|string',
        ]);

        $conversation = Conversation::findOrFail($conversationId);

        if ($conversation->user_id !== Auth::id() && $conversation->driver_id !== Auth::id()) {
            abort(403, 'Unauthorized to send messages in this conversation.');
        }

        $message = $conversation->messages()->create([
            'sender_id' => Auth::id(),
            'message'   => $request->message,
        ]);

        return response()->json($message->load('sender'), 201);
    }

    public function userConversations()
    {
        $user = Auth::user();

        $conversations = Conversation::where('user_id', $user->id)
            ->orWhere('driver_id', $user->id)
            ->with(['messages' => fn($q) => $q->latest()->limit(1), 'messages.sender'])
            ->latest()
            ->get()
            ->map(function ($conversation) {
                $latest = $conversation->messages->first();
                return [
                    'conversation_id' => $conversation->id,
                    'message' => $latest?->message ?? '',
                    'created_at' => $latest?->created_at ?? now(),
                    'sender' => [
                        'id' => $latest?->sender->id ?? null,
                        'name' => $latest?->sender->name ?? '',
                    ],
                ];
            });

        return response()->json($conversations);
    }
}
