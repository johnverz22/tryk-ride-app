<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Vehicle extends Model
{
    protected $fillable = [
        'type',
        'brand',
        'model',
        'license_plate',
        'registration_number',
    ];
}
