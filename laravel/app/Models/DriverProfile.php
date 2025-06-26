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
        'is_online',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'user_id');
    }

    public function status(): BelongsTo
    {
        return $this->belongsTo(DriverStatus::class, 'driver_status_id');
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
}
