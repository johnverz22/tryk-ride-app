<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class DriverProfile extends Model
{
    protected $fillable = [
        'user_id',
        'driver_status_id',
        'id_document_path',
        'license_document_path',
        'current_latitude',
        'current_longitude',
        'is_online',
        'average_rating',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'user_id');
    }

    public function status(): BelongsTo
    {
        return $this->belongsTo(DriverStatus::class, 'driver_status_id');
    }

    public function rides()
    {
        return $this->user->rides();
    }

    // ✅ Add these accessors:
    public function getIdDocumentUrlAttribute()
    {
        return $this->id_document_path
            ? asset('storage/' . ltrim($this->id_document_path, '/'))
            : null;
    }

    public function getLicenseDocumentUrlAttribute()
    {
        return $this->license_document_path
            ? asset('storage/' . ltrim($this->license_document_path, '/'))
            : null;
    }
    
    public function getIdDocumentMimeAttribute(): ?string
    {
        return $this->getDocumentMimeType($this->id_document_path);
    }

    public function getLicenseDocumentMimeAttribute(): ?string
    {
        return $this->getDocumentMimeType($this->license_document_path);
    }

    protected function getDocumentUrl(?string $path): ?string
    {
        return $path ? Storage::url($path) : null;
    }

    protected function getDocumentMimeType(?string $path): ?string
    {
        return $path && Storage::exists($path) ? Storage::mimeType($path) : null;
    }

    public function getAverageRatingAttribute($value)
    {
        return $value !== null ? round($value, 1) : null;
    }

    public function updateAverageRating(): void
    {
        $average = $this->user?->rides()
            ->whereNotNull('rider_rating')
            ->avg('rider_rating');

        $this->average_rating = $average;
        $this->save();
    }

    public function dailyEarnings($date = null): float
    {
        $date = $date ?? now()->toDateString();

        return $this->user?->rides()
            ->whereDate('completed_at', $date)
            ->sum('fare_amount');
    }
}
