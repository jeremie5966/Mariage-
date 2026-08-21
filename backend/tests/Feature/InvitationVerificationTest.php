<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Guest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InvitationVerificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_valid_invitation_is_used_once(): void
    {
        $user = User::factory()->create(['role' => 'staff']);
        $event = Event::factory()->create();
        $guest = Guest::factory()->create(['event_id' => $event->id]);

        $this->actingAs($user)->postJson("/api/events/{$event->id}/invitations/verify", ['qr_token' => $guest->qr_token])->assertOk()->assertJsonPath('status', 'valid');
        $this->actingAs($user)->postJson("/api/events/{$event->id}/invitations/verify", ['qr_token' => $guest->qr_token])->assertStatus(409)->assertJsonPath('status', 'already_used');
    }

    public function test_unknown_token_is_rejected(): void
    {
        $user = User::factory()->create(['role' => 'staff']);
        $event = Event::factory()->create();

        $this->actingAs($user)->postJson("/api/events/{$event->id}/invitations/verify", ['qr_token' => 'inv_unknown'])->assertStatus(404)->assertJsonPath('status', 'invalid');
    }

    public function test_inactive_invitation_is_rejected_and_logged(): void
    {
        $user = User::factory()->create(['role' => 'staff']);
        $event = Event::factory()->create();
        $guest = Guest::factory()->create(['event_id' => $event->id, 'status' => 'inactive']);

        $this->actingAs($user)->postJson("/api/events/{$event->id}/invitations/verify", ['qr_token' => $guest->qr_token])
            ->assertStatus(422)
            ->assertJsonPath('status', 'blocked');
        $this->assertDatabaseHas('invitation_scans', ['guest_id' => $guest->id, 'status' => 'blocked']);
    }

    public function test_unauthenticated_user_cannot_verify(): void
    {
        $event = Event::factory()->create();
        $guest = Guest::factory()->create(['event_id' => $event->id]);

        $this->postJson("/api/events/{$event->id}/invitations/verify", ['qr_token' => $guest->qr_token])
            ->assertUnauthorized();
    }
}
