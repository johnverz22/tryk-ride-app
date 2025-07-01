<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\User;

Broadcast::channel('driver.{driverId}', function ($user, $driverId) {
    return (int) $user->id === (int) $driverId
        && (int) $user->role_id === 3
        && optional($user->profile)->status->name === 'approved';
});
