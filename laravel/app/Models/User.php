<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens; // Optional if you're still using Sanctum elsewhere
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Tymon\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements FilamentUser, JWTSubject
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role_id',
        'phone',
        'profile_picture',
        'refresh_token', // ✅ Add this to store refresh token hash
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'refresh_token', // ✅ Hide it from serialization
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // 🔐 Required for JWT
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims(): array
    {
        return [];
    }

    // 🎛️ For Filament admin panel access control
    public function canAccessPanel(Panel $panel): bool
    {
        if ($panel->getId() === 'admin') {
            return str_ends_with($this->email, '@admin.com');
            // return str_ends_with($this->email, '@admin.com') && $this->hasVerifiedEmail();
        }

        return true;
    }
}
