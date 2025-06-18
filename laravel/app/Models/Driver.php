<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Auth\User as Authenticatable;

class Driver extends Model
{
    
    protected $table = 'users';

    protected $fillable = [
        'name',
        'email',
        'phone',
        'type',
        'brand',
        'model',
        'license_plate',
        'registration_number',
    ];

    protected static function booted()
    {
        static::addGlobalScope('driver', function (Builder $builder) {
            $builder->where('role_id', '3');
        });
    }

    public function vehicles()
    {
        return $this->hasMany(Vehicle::class, 'user_id');
    }

    public function profile()
    {
        return $this->hasOne(DriverProfile::class, 'user_id');
    }
}
