<?php

namespace App\Filament\Resources\RideResource\Pages;

use App\Filament\Resources\RideResource;
use Filament\Actions;
use Filament\Resources\Pages\ManageRecords;

class ManageRides extends ManageRecords
{
    protected static string $resource = RideResource::class;

    protected function getHeaderActions(): array
    {
        return [
            // Actions\CreateAction::make(),
        ];
    }
}
