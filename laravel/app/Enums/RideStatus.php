<?php

namespace App\Enums;

class RideStatus
{
    const REQUESTED = 1;
    const ACCEPTED = 2;
    const DRIVER_EN_ROUTE = 3;
    const RIDE_STARTED_AWAITING_USER_CONFIRMATION = 4;
    const RIDE_IN_PROGRESS = 5;
    const RIDE_COMPLETED_AWAITING_USER_CONFIRMATION = 6;
    const COMPLETED = 7;
    const CANCELLED = 8;
}
