<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverProfile extends Model
{
    protected $fillable = [
        'user_id',
        'driver_status_id',
    ];

    /**
     * Get the user (driver) that owns this profile.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'user_id');
    }

    /**
     * Get the driver's current status.
     */
    public function status(): BelongsTo
    {
        return $this->belongsTo(DriverStatus::class, 'driver_status_id');
    }
}
