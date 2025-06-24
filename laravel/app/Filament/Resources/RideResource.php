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
                Tables\Columns\TextColumn::make('user.name')->label('Rider'),
                Tables\Columns\TextColumn::make('pickup_address')->limit(30),
                Tables\Columns\TextColumn::make('dropoff_address')->limit(30),
                Tables\Columns\TextColumn::make('requested_at')->dateTime(),
                Tables\Columns\TextColumn::make('picked_up_at')->dateTime(),
                Tables\Columns\TextColumn::make('completed_at')->dateTime(),
                Tables\Columns\TextColumn::make('canceled_at')->dateTime(),
                Tables\Columns\TextColumn::make('fare_amount')->money('php'),
                Tables\Columns\IconColumn::make('is_paid')->label('Paid')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-badge'),
            ])
            ->filters([
                //
            ])
            ->actions([
                // Tables\Actions\EditAction::make(),
                // Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                // Tables\Actions\BulkActionGroup::make([
                //     Tables\Actions\DeleteBulkAction::make(),
                // ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageRides::route('/'),
        ];
    }
}
