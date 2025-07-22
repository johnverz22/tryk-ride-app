<?php

namespace App\Enums;

class RideStatus
{
    const REQUESTED = 1;
    const OFFERED = 2;
    const ACCEPTED = 3;
    const DRIVER_EN_ROUTE = 4;
    const RIDE_IN_PROGRESS = 5;
    const COMPLETED = 6;
    const CANCELLED = 7;
    const NO_DRIVERS_AVAILABLE = 8;
}
