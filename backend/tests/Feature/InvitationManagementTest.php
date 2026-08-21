<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\Guest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InvitationManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_event_and_guest_with_unique_token(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $eventResponse = $this->actingAs($admin)->postJson('/api/events', [
            'name' => 'Mariage test',
            'bride_name' => 'Marie',
            'groom_name' => 'Paul',
            'event_date' => '2026-09-12 15:00:00',
            'venue' => 'Douala',
        ])->assertCreated();

        $eventId = $eventResponse->json('id');
        $first = $this->actingAs($admin)->postJson("/api/events/{$eventId}/guests", [
            'first_name' => 'Mathilde',
            'last_name' => 'Grégoire',
            'category' => 'VIP',
            'number_of_guests' => 2,
        ])->assertCreated();
        $second = $this->actingAs($admin)->postJson("/api/events/{$eventId}/guests", [
            'first_name' => 'Jean',
            'last_name' => 'Martin',
            'category' => 'Ami',
            'number_of_guests' => 1,
        ])->assertCreated();

        $this->assertNotSame($first->json('qr_token'), $second->json('qr_token'));
    }

    public function test_staff_cannot_mutate_events_or_guests(): void
    {
        $staff = User::factory()->create(['role' => 'staff']);
        $event = Event::factory()->create();

        $this->actingAs($staff)->postJson('/api/events', [
            'name' => 'Refusé',
            'bride_name' => 'A',
            'groom_name' => 'B',
            'event_date' => '2026-09-12 15:00:00',
            'venue' => 'Douala',
        ])->assertForbidden();

        $this->actingAs($staff)->postJson("/api/events/{$event->id}/guests", [
            'first_name' => 'Refusé',
            'last_name' => 'Staff',
            'category' => 'Ami',
            'number_of_guests' => 1,
        ])->assertForbidden();
    }

    public function test_statistics_and_scan_history_support_real_data_and_filters(): void
    {
        $user = User::factory()->create(['role' => 'staff']);
        $event = Event::factory()->create();
        $arrived = Guest::factory()->create(['event_id' => $event->id, 'number_of_guests' => 2, 'used_at' => now(), 'category' => 'VIP']);
        Guest::factory()->create(['event_id' => $event->id, 'number_of_guests' => 3, 'category' => 'Ami']);

        $this->actingAs($user)->postJson("/api/events/{$event->id}/invitations/verify", ['qr_token' => $arrived->qr_token])->assertStatus(409);
        $this->actingAs($user)->getJson("/api/events/{$event->id}/statistics?category=VIP")
            ->assertOk()
            ->assertJsonPath('guests', 1)
            ->assertJsonPath('expected_people', 2)
            ->assertJsonPath('present_people', 2);

        $this->actingAs($user)->getJson("/api/events/{$event->id}/scans?status=already_used&per_page=1")
            ->assertOk()
            ->assertJsonPath('per_page', 1)
            ->assertJsonPath('total', 1);
    }

    public function test_token_from_another_event_is_rejected(): void
    {
        $user = User::factory()->create(['role' => 'staff']);
        $firstEvent = Event::factory()->create();
        $secondEvent = Event::factory()->create();
        $guest = Guest::factory()->create(['event_id' => $firstEvent->id]);

        $this->actingAs($user)->postJson("/api/events/{$secondEvent->id}/invitations/verify", ['qr_token' => $guest->qr_token])
            ->assertNotFound()
            ->assertJsonPath('status', 'invalid');
    }
}
