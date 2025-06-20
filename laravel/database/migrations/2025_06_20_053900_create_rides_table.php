<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('rides', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->uuid('driver_id')->nullable()->constrained('drivers')->onDelete('set null');
            $table->foreignId('ride_status_id')->constrained()->onDelete('restrict');
            
            $table->string('pickup_address');
            $table->double('pickup_latitude');
            $table->double('pickup_longitude');

            $table->string('dropoff_address');
            $table->double('dropoff_latitude');
            $table->double('dropoff_longitude');

            $table->timestamp('requested_at');
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('picked_up_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('canceled_at')->nullable();

            $table->double('distance_km')->nullable();
            $table->double('duration_minutes')->nullable();
            $table->double('fare_amount')->nullable();
            $table->string('payment_method')->nullable();
            $table->boolean('is_paid')->default(false);

            $table->tinyInteger('rider_rating')->nullable();
            $table->text('rider_review')->nullable();

            $table->tinyInteger('driver_rating')->nullable();
            $table->text('driver_review')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rides');
    }
};
