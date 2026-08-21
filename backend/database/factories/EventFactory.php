<?php

namespace Database\Factories;

use App\Models\Event;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<Event> */
class EventFactory extends Factory
{
    protected $model = Event::class;

    public function definition(): array
    {
        return [
            'name' => 'Mariage de Jérémie & Stéphanie',
            'bride_name' => 'Stéphanie',
            'groom_name' => 'Jérémie',
            'event_date' => now()->addMonths(2),
            'venue' => 'Douala',
            'status' => 'active',
            'single_use' => true,
        ];
    }
}
