<?php

namespace App\Filament\Pages;

use App\Filament\Resources\AdminResource\Widgets\UserWidget;
use App\Filament\Resources\AdminResource\Widgets\DriverWidget;
use Filament\Pages\Dashboard as BaseDashboard;
use App\Models\User;
use App\Models\Driver;
use Filament\Pages\Page;
use App\Models\DriverStatus;

class Dashboard extends BaseDashboard
{
    protected static ?string $navigationIcon = 'heroicon-o-chart-bar';
    protected static ?string $title = 'Dashboard';
    protected ?string $subheading = 'Subheading';

    public $pendingDriversCount;

    public function mount(): void
    {
        $this->pendingDriversCount = Driver::whereHas('profile.status', function ($query) {
            $query->where('name', 'pending');
        })->count();
    }

    protected function getHeaderWidgets(): array
    {
        return [
            UserWidget::class,
            DriverWidget::class,
        ];
    }
}
