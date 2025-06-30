<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

Broadcast::channel('driver.{driverId}', function ($user, $driverId) {
    return (int) $user->id === (int) $driverId;
});

Broadcast::channel('drivers', function ($user) {
    return $user->is_driver; // or whatever logic you use
});
