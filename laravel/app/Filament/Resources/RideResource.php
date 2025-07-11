<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RideResource\Pages;
use App\Filament\Resources\RideResource\RelationManagers;
use App\Models\Ride;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class RideResource extends Resource
{
    protected static ?string $model = Ride::class;

    protected static ?string $navigationGroup = 'Users';
    protected static ?int $navigationSort = 3;
    protected static ?string $navigationIcon = 'heroicon-o-map-pin';
    protected static ?string $navigationBadgeTooltip = 'Number of rides';
    
    public static function getNavigationBadge(): ?string
        {
            return static::getModel()::count();
        }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                //
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')->label('Rider')->searchable(),
                Tables\Columns\TextColumn::make('driver.name')
                    ->label('Driver')
                    ->searchable(),
                Tables\Columns\IconColumn::make('status.name')
                    ->label('Status')
                    ->icon(fn (string $state): string => match ($state) {
                        'Requested' => 'heroicon-o-clock',
                        'Accepted' => 'heroicon-o-check-badge',
                        'Driver En Route' => 'heroicon-o-truck',
                        'Passenger Picked Up' => 'heroicon-o-user-group',
                        'Completed' => 'heroicon-o-check-circle',
                        'Cancelled' => 'heroicon-o-x-circle',
                        default => 'heroicon-o-question-mark-circle',
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'Requested' => 'gray',
                        'Accepted' => 'success',
                        'Driver En Route' => 'info',
                        'Passenger Picked Up' => 'info',
                        'Completed' => 'success',
                        'Cancelled' => 'danger',
                    })
                    ->tooltip(fn (string $state): string => $state),
                Tables\Columns\TextColumn::make('fare_amount')->money('php'),
                Tables\Columns\IconColumn::make('is_paid')->label('Paid')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-badge'),
                Tables\Columns\TextColumn::make('payment_method'),
                Tables\Columns\TextColumn::make('pickup_address')
                    ->searchable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('dropoff_address')
                    ->searchable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('requested_at')
                    ->dateTime()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('accepted_at')
                    ->dateTime()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('picked_up_at')
                    ->dateTime()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('completed_at')
                    ->dateTime()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('canceled_at')
                    ->dateTime()
                    ->toggleable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('ride_status_id')
                    ->label('Ride Status')
                    ->relationship('status', 'name'),
                Tables\Filters\SelectFilter::make('payment_method')
                    ->label('Payment Method')
                    ->options([
                        'Wallet' => 'Wallet',
                        'Digital Wallet' => 'Digital Wallet',
                        'Credit/Debit Card' => 'Credit/Debit Card',
                        'Cash' => 'Cash',
                    ]),
                Tables\Filters\SelectFilter::make('is_paid')
                    ->label('Paid')
                    ->options([
                        '1' => 'Yes',
                        '0' => 'No',
                    ]),
            ])
            ->actions([
                // Tables\Actions\EditAction::make(),
                // Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                // Tables\Actions\BulkActionGroup::make([
                //     Tables\Actions\DeleteBulkAction::make(),
                // ]),
            ])
            ->poll('30s');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageRides::route('/'),
        ];
    }
}
