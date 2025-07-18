<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SavedLocation extends Model
{
    protected $fillable = [
        'user_id',
        'location_name',
        'latitude',
        'longitude',
    ];

    protected $casts = [
        'latitude' => 'double',
        'longitude' => 'double',
    ];
}