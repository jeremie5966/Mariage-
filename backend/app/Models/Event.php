<?php

namespace App\Models;

use Database\Factories\EventFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Event extends Model
{
    use HasFactory;

    protected static function newFactory(): EventFactory
    {
        return EventFactory::new();
    }
    protected $fillable = [
        'name', 'description', 'bride_name', 'groom_name', 'event_date',
        'venue', 'address', 'invitation_message', 'primary_color',
        'secondary_color', 'logo', 'status', 'single_use',
    ];

    protected function casts(): array
    {
        return ['event_date' => 'datetime', 'single_use' => 'boolean'];
    }

    public function guests(): HasMany
    {
        return $this->hasMany(Guest::class);
    }

    public function scans(): HasMany
    {
        return $this->hasMany(InvitationScan::class);
    }
}
