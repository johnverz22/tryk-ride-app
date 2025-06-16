<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

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
            $builder->where('role', '3'); // Adjust to your role logic
        });
    }

    public function vehicles()
    {
        return $this->hasMany(Vehicle::class, 'user_id');
    }
}
