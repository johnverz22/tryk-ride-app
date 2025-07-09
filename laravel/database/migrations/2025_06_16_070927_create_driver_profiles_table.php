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
        Schema::create('driver_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('driver_status_id')->constrained('driver_statuses')->onDelete('restrict');
            $table->string('id_document_path')->nullable();
            $table->string('license_document_path')->nullable();
            $table->decimal('current_latitude', 11, 8)->nullable();
            $table->decimal('current_longitude', 11, 8)->nullable();
            $table->boolean('is_online')->default(false);
            $table->float('average_rating')->nullable();
            $table->timestamps();

            $table->index(['current_latitude', 'current_longitude'], 'driver_location_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('driver_profiles');
    }
};
