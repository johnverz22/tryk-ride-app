<?php

namespace App\Filament\Resources;

use App\Filament\Resources\FeedbackResource\Pages;
use App\Filament\Resources\FeedbackResource\RelationManagers;
use App\Models\Ride;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class FeedbackResource extends Resource
{
    protected static ?string $model = Ride::class;
    protected static ?string $navigationIcon = 'heroicon-o-star';
    protected static ?string $navigationLabel = 'Rider Feedback';
    protected static ?string $navigationGroup = 'Feedback';

    // public static function getEloquentQuery(): Builder
    // {
    //     return parent::getEloquentQuery()
    //         ->whereNotNull('rider_rating')
    //         ->whereNotNull('rider_review');
    // }

public static function form(Form $form): Form
{
    return $form->schema([
        Forms\Components\Placeholder::make('user_name')
            ->label('Rider')
            ->content(fn ($record) => $record?->user?->name ?? '-'),

        Forms\Components\Placeholder::make('driver_name')
            ->label('Driver')
            ->content(fn ($record) => $record?->driver?->name ?? '-'),

        Forms\Components\Placeholder::make('rider_rating')
            ->label('Rating')
            ->content(fn ($record) => str_repeat('⭐', $record->rider_rating ?? 0)),

        Forms\Components\Placeholder::make('rider_review')
            ->label('Comment')
            ->content(fn ($record) => $record?->rider_review ?? '-'),

        Forms\Components\Placeholder::make('pickup_address')
            ->label('Pickup')
            ->content(fn ($record) => $record?->pickup_address ?? '-'),

        Forms\Components\Placeholder::make('dropoff_address')
            ->label('Dropoff')
            ->content(fn ($record) => $record?->dropoff_address ?? '-'),

        Forms\Components\Placeholder::make('fare_amount')
            ->label('Fare')
            ->content(fn ($record) => $record?->fare_amount ? '₱' . number_format($record->fare_amount, 2) : '-'),

        Forms\Components\Placeholder::make('payment_method')
            ->label('Payment Method')
            ->content(fn ($record) => $record?->payment_method ?? '-'),

        Forms\Components\Placeholder::make('requested_at')
            ->label('Requested At')
            ->content(fn ($record) => $record?->requested_at?->format('F j, Y g:i A') ?? '-'),

        Forms\Components\Placeholder::make('completed_at')
            ->label('Completed At')
            ->content(fn ($record) => $record?->completed_at?->format('F j, Y g:i A') ?? '-'),
    ]);
}

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')->label('Rider')->searchable(),
                Tables\Columns\TextColumn::make('driver.name')->label('Driver')->searchable(),

                Tables\Columns\TextColumn::make('rider_rating')
                    ->label('Rating')
                    ->sortable(),

                Tables\Columns\TextColumn::make('rider_review')
                    ->label('Comment')
                    ->wrap()
                    ->limit(100)
                    ->toggleable(),

                Tables\Columns\TextColumn::make('pickup_address')
                    ->label('Pickup')
                    ->limit(30)
                    ->toggleable(),

                Tables\Columns\TextColumn::make('dropoff_address')
                    ->label('Dropoff')
                    ->limit(30)
                    ->toggleable(),

                Tables\Columns\TextColumn::make('fare_amount')
                    ->label('Fare')
                    ->money('php')
                    ->toggleable(),

                Tables\Columns\TextColumn::make('payment_method')
                    ->label('Payment Method')
                    ->toggleable(),

                Tables\Columns\TextColumn::make('requested_at')
                    ->label('Requested At')
                    ->dateTime()
                    ->sortable(),

                Tables\Columns\TextColumn::make('completed_at')
                    ->label('Completed At')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('driver_id')
                    ->label('Driver')
                    ->relationship('driver', 'name')
                    ->searchable(),

                Tables\Filters\SelectFilter::make('user_id')
                    ->label('Rider')
                    ->relationship('user', 'name')
                    ->searchable(),

                Tables\Filters\SelectFilter::make('rider_rating')
                    ->label('Rating')
                    ->options([
                        1 => '1 Star',
                        2 => '2 Stars',
                        3 => '3 Stars',
                        4 => '4 Stars',
                        5 => '5 Stars',
                    ]),

                Tables\Filters\Filter::make('completed_at')
                    ->label('Ride Date')
                    ->form([
                        Forms\Components\DatePicker::make('from'),
                        Forms\Components\DatePicker::make('until'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['from'], fn ($q) => $q->whereDate('completed_at', '>=', $data['from']))
                            ->when($data['until'], fn ($q) => $q->whereDate('completed_at', '<=', $data['until']));
                    }),
            ])
            ->defaultSort('completed_at', 'desc')
            ->actions([
                Tables\Actions\ViewAction::make(),])
            ->bulkActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ManageFeedback::route('/'),
        ];
    }
}
