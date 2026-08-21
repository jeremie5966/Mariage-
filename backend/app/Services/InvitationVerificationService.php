<?php

namespace App\Services;

use App\Models\Event;
use App\Models\Guest;
use App\Models\InvitationScan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class InvitationVerificationService
{
    public function generateToken(): string
    {
        return 'inv_'.Str::random(64);
    }

    public function verify(Event $event, string $token, ?int $userId, Request $request): array
    {
        return DB::transaction(function () use ($event, $token, $userId, $request): array {
            $guest = Guest::query()
                ->where('event_id', $event->id)
                ->where('qr_token', $token)
                ->lockForUpdate()
                ->first();

            if (! $guest) {
                $this->record($event, null, $userId, 'invalid', $request);
                return ['status' => 'invalid'];
            }

            if ($guest->status !== 'active') {
                $this->record($event, $guest, $userId, 'blocked', $request);
                return ['status' => 'blocked'];
            }

            if ($event->single_use && $guest->used_at) {
                $this->record($event, $guest, $userId, 'already_used', $request);
                return ['status' => 'already_used'];
            }

            $guest->forceFill(['used_at' => now(), 'used_by' => $userId])->save();
            $this->record($event, $guest, $userId, 'valid', $request);

            return [
                'status' => 'valid',
                'guest' => $guest->only(['id', 'first_name', 'last_name', 'number_of_guests', 'table_number']),
            ];
        });
    }

    private function record(Event $event, ?Guest $guest, ?int $userId, string $status, Request $request): void
    {
        InvitationScan::create([
            'event_id' => $event->id,
            'guest_id' => $guest?->id,
            'scanned_by' => $userId,
            'scanned_at' => now(),
            'status' => $status,
            'device_name' => $request->userAgent(),
            'ip_address' => $request->ip(),
        ]);
    }
}
