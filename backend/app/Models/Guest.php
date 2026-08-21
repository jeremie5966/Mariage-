<?php

namespace App\Models;

use Database\Factories\GuestFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Guest extends Model
{
    use HasFactory;

    protected static function newFactory(): GuestFactory
    {
        return GuestFactory::new();
    }
    protected $fillable = [
        'event_id', 'first_name', 'last_name', 'phone', 'email', 'category',
        'number_of_guests', 'table_number', 'notes', 'status', 'qr_token',
        'qr_generated_at', 'used_at', 'used_by',
    ];

    protected function casts(): array
    {
        return ['qr_generated_at' => 'datetime', 'used_at' => 'datetime'];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function scans(): HasMany
    {
        return $this->hasMany(InvitationScan::class);
    }
}
