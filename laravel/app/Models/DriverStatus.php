<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DriverStatus extends Model
{
    protected $table = 'driver_statuses';

    protected $fillable = [
        'name',
    ];

    /**
     * Get all driver profiles with this status.
     */
    public function profiles(): HasMany
    {
        return $this->hasMany(DriverProfile::class, 'driver_status_id');
    }
}
