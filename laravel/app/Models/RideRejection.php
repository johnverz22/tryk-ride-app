<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class RideRejection extends Model
{
    use HasFactory;
    
    protected $table = 'ride_rejections';

    protected $fillable = ['ride_id', 'driver_id'];
    
    public function ride()
    {
        return $this->belongsTo(Ride::class);
    }

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }
}