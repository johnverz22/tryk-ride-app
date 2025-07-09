<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'balance',
    ];

    // Optional: Set default value
    protected $attributes = [
        'balance' => 0.00,
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
