<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Filament\Resources\UserResource\RelationManagers;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

use Filament\Forms\Components\TextInput;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationGroup = 'Users';
    protected static ?int $navigationSort = 1;
    protected static ?string $navigationIcon = 'heroicon-o-user-circle';
    protected static ?string $navigationBadgeTooltip = 'Number of users';

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('role_id', '!=', 1)->count();
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->where('role_id', '!=', 1);
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make('name')->required(),
                TextInput::make('email')
                    ->email()
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label('Full Name')
                    ->searchable(true),
                TextColumn::make('email')
                    ->searchable(true),
                TextColumn::make('email_verified_at')
                    ->searchable(true),
                TextColumn::make('phone')
                    ->searchable(true),
                TextColumn::make('phone_verified_at')
                    ->searchable(true),
            ])
            ->filters([
                SelectFilter::make('role_id')
                    ->label('User Type')
                    ->options([
                        2 => 'User',
                        3 => 'Driver',
                    ])
                    ->placeholder('All')
                    ->searchable()
                    ->multiple()
                    ->preload(),
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
            'index' => Pages\ManageUsers::route('/'),
        ];
    }
}
