<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class RideRejection extends Model
{
    use HasFactory;

    protected $fillable = ['ride_id', 'driver_id'];
}