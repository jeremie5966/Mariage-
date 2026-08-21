<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InvitationScan extends Model
{
    protected $fillable = [
        'event_id', 'guest_id', 'scanned_by', 'scanned_at', 'status',
        'device_name', 'ip_address', 'notes',
    ];

    protected function casts(): array
    {
        return ['scanned_at' => 'datetime'];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function guest(): BelongsTo
    {
        return $this->belongsTo(Guest::class);
    }

    public function scanner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'scanned_by');
    }
}
