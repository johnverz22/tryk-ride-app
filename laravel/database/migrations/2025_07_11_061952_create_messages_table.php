<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void 
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();

            $table->foreignId('conversation_id')
                ->index();

            $table->foreignId('sender_id')
                ->index();

            $table->text('message');
            $table->timestamp('read_at')->nullable();

            $table->timestamps();

            // Explicit foreign key constraints
            $table->foreign('conversation_id', 'messages_conversation_id_foreign')
                ->references('id')->on('conversations')->onDelete('cascade');

            $table->foreign('sender_id', 'messages_sender_id_foreign')
                ->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void {
        Schema::dropIfExists('messages');
    }
};
