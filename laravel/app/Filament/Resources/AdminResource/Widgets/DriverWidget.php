<?php

namespace App\Filament\Resources\AdminResource\Widgets;

use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use App\Models\Driver;
use Filament\Support\Enums\IconPosition;

class DriverWidget extends BaseWidget
{
    protected function getStats(): array
    {
        $statuses = [
            'approved' => [
                'label' => 'Approved',
                'icon' => 'heroicon-o-check-circle',
                'color' => 'success',
                'description' => 'Drivers ready for activation',
            ],
            'pending' => [
                'label' => 'Pending',
                'icon' => 'heroicon-o-clock',
                'color' => 'warning',
                'description' => 'New signups or reverifications',
            ],
            'rejected' => [
                'label' => 'Rejected',
                'icon' => 'heroicon-o-x-circle',
                'color' => 'danger',
                'description' => 'Incomplete or invalid documents',
            ],
            'onboarding' => [
                'label' => 'Onboarding',
                'icon' => 'heroicon-o-folder-plus',
                'color' => 'info',
                'description' => 'Started signup, awaiting submission',
            ],
            'under_review' => [
                'label' => 'Under Review',
                'icon' => 'heroicon-o-eye',
                'color' => 'gray',
                'description' => 'Documents under manual review',
            ],
            'suspended' => [
                'label' => 'Suspended',
                'icon' => 'heroicon-o-exclamation-circle',
                'color' => 'danger',
                'description' => 'Temporarily restricted due to violations',
            ],
            'deactivated' => [
                'label' => 'Deactivated',
                'icon' => 'heroicon-o-minus-circle',
                'color' => 'gray',
                'description' => 'Manually disabled account',
            ],
            'banned' => [
                'label' => 'Banned',
                'icon' => 'heroicon-o-no-symbol',
                'color' => 'danger',
                'description' => 'Permanently blocked',
            ],
        ];

        return collect($statuses)->map(function ($meta, $status) {
            $count = Driver::whereHas('profile.status', fn ($q) => $q->where('name', $status))->count();

            return Stat::make($meta['label'], $count)
                ->description($meta['description'],)
                ->chartColor($meta['color'])
                ->descriptionColor($meta['color'])
                ->descriptionIcon($meta['icon'], IconPosition::Before)
                ->icon($meta['icon'])
                ->color($meta['color']);
        })->toArray();
    }
}
