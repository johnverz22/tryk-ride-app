<?php

namespace App\Enums;

class RideStatus
{
    const REQUESTED = 1;
    const ACCEPTED = 2;
    const DRIVER_EN_ROUTE = 3;
    const PICKED_UP = 4;
    const COMPLETED = 5;
    const CANCELLED = 6;
}
