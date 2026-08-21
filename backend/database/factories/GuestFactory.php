<?php

namespace Database\Factories;

use App\Models\Event;
use App\Models\Guest;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/** @extends Factory<Guest> */
class GuestFactory extends Factory
{
    protected $model = Guest::class;

    public function definition(): array
    {
        return [
            'event_id' => Event::factory(),
            'first_name' => fake()->firstName(),
            'last_name' => fake()->lastName(),
            'category' => 'Autre',
            'number_of_guests' => 1,
            'status' => 'active',
            'qr_token' => 'inv_'.Str::random(64),
            'qr_generated_at' => now(),
        ];
    }
}
