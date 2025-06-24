<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Ride extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'driver_id',
        'ride_status_id',

        'pickup_address',
        'pickup_latitude',
        'pickup_longitude',

        'dropoff_address',
        'dropoff_latitude',
        'dropoff_longitude',

        'requested_at',
        'accepted_at',
        'picked_up_at',
        'completed_at',
        'canceled_at',

        'distance_km',
        'duration_minutes',
        'fare_amount',
        'payment_method',
        'is_paid',

        'rider_rating',
        'rider_review',
        'driver_rating',
        'driver_review',
    ];

    protected $casts = [
        'requested_at' => 'datetime',
        'accepted_at' => 'datetime',
        'picked_up_at' => 'datetime',
        'completed_at' => 'datetime',
        'canceled_at' => 'datetime',

        'pickup_latitude' => 'double',
        'pickup_longitude' => 'double',
        'dropoff_latitude' => 'double',
        'dropoff_longitude' => 'double',

        'distance_km' => 'double',
        'duration_minutes' => 'double',
        'fare_amount' => 'double',
        'is_paid' => 'boolean',
    ];

    // Relationships

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function status()
    {
        return $this->belongsTo(RideStatus::class, 'ride_status_id');
    }
}
