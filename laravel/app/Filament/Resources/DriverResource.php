<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DriverResource\Pages;
use App\Filament\Resources\DriverResource\RelationManagers;
use App\Models\Driver;
use App\Models\DriverStatus;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\SelectColumn;
use Filament\Tables\Columns\IconColumn;

use Filament\Tables\Filters\SelectFilter;

class DriverResource extends Resource
{
    protected static ?string $model = Driver::class;

    protected static ?int $navigationSort = 2;
    protected static ?string $navigationIcon = 'heroicon-o-key';
    protected static ?string $navigationBadgeTooltip = 'Number of drivers';

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::count();
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->with(['profile.status', 'vehicles']);
    }


    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make('name')->required(),
                TextInput::make('email')->email()->required(),
                TextInput::make('phone')->tel(),
                // TextInput::make('type'),
                // TextInput::make('brand'),
                // TextInput::make('model'),
                // TextInput::make('license_plate'),
                // TextInput::make('registration_number'),

                Select::make('profile.driver_status_id')
                    ->label('Driver Status')
                    ->relationship('profile.status', 'label')
                    ->options(DriverStatus::all()->pluck('label', 'id'))
                    ->searchable()
                    ->preload()
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label('Driver Name')
                    ->searchable(true),
                TextColumn::make('email')
                    ->searchable(true),
                TextColumn::make('phone')
                    ->searchable(true),
                TextColumn::make('vehicles.model')
                    ->label('Vehicle Type')
                    ->formatStateUsing(fn ($state, $record) =>
                        $record->vehicles->pluck('model')->join(', ')
                    ),
                TextColumn::make('brand'),
                TextColumn::make('model'),
                TextColumn::make('license_plate'),
                TextColumn::make('registration_number'),
                IconColumn::make('profile.status.name')
                    ->label('Status')
                    ->icon(fn (string $state): string => match ($state) {
                        'onboarding' => 'heroicon-o-folder-plus',
                        'pending' => 'heroicon-o-clock',
                        'under_review' => 'heroicon-o-eye',
                        'approved' => 'heroicon-o-check-circle',
                        'rejected' => 'heroicon-o-x-circle',
                        'suspended' => 'heroicon-o-exclamation-circle',
                        'deactivated' => 'heroicon-o-minus-circle',
                        'banned' => 'heroicon-o-no-symbol',
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'onboarding' => 'info',
                        'pending', 'under_review' => 'warning',
                        'approved' => 'success',
                        'deactivated' => 'gray',
                        'rejected', 'suspended', 'banned' => 'danger',
                    })
                    ->tooltip(fn ($record) => $record->profile?->status?->label ?? 'Unknown'),
                // SelectColumn::make('profile.driver_status_id')
                //     ->label('Status')
                //     ->options(
                //         \App\Models\DriverStatus::all()->pluck('label', 'id')
                //     )
                //     ->searchable()
                //     ->selectablePlaceholder(false),
            ])
            ->filters([
                SelectFilter::make('driver_status_id')
                    ->label('Status')
                    ->relationship('profile.status', 'label')
                    ->options(
                        DriverStatus::all()->pluck('label', 'id')
                    )
                    ->searchable()
                    ->multiple()
                    ->preload()
    ->selectablePlaceholder(false),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageDrivers::route('/'),
        ];
    }
}
