<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreEventRequest;
use App\Http\Requests\UpdateEventRequest;
use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class EventController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        return response()->json(Event::query()->latest()->paginate($request->integer('per_page', 20)));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreEventRequest $request)
    {
        return response()->json(Event::create($request->validated()), 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Event $event)
    {
        return response()->json($event);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateEventRequest $request, Event $event)
    {
        $event->update($request->validated());
        return response()->json($event->refresh());
    }

    public function branding(Request $request, Event $event)
    {
        $validated = $request->validate([
            'logo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'primary_color' => ['nullable', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'secondary_color' => ['nullable', 'regex:/^#[0-9A-Fa-f]{6}$/'],
        ]);

        if ($event->logo) {
            Storage::disk('public')->delete($event->logo);
        }

        $logo = $request->file('logo')->store('events', 'public');
        $event->update([
            'logo' => $logo,
            'primary_color' => $validated['primary_color'] ?? $event->primary_color,
            'secondary_color' => $validated['secondary_color'] ?? $event->secondary_color,
        ]);

        return response()->json($event->refresh());
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Event $event)
    {
        $event->delete();
        return response()->noContent();
    }

    public function statistics(Event $event, Request $request)
    {
        $guests = $event->guests();
        if ($request->filled('category')) {
            $guests->where('category', $request->string('category'));
        }
        $total = (clone $guests)->count();
        $arrived = (clone $guests)->whereNotNull('used_at')->count();
        return response()->json([
            'guests' => $total,
            'arrived' => $arrived,
            'not_arrived' => max(0, $total - $arrived),
            'expected_people' => (clone $guests)->sum('number_of_guests'),
            'present_people' => (clone $guests)->whereNotNull('used_at')->sum('number_of_guests'),
            'active_invitations' => (clone $guests)->where('status', 'active')->count(),
            'disabled_invitations' => (clone $guests)->whereIn('status', ['inactive', 'blocked'])->count(),
            'used_qr' => (clone $guests)->whereNotNull('used_at')->count(),
            'invalid_scans' => $event->scans()->where('status', 'invalid')->count(),
            'by_category' => (clone $guests)->selectRaw('category, COUNT(*) as total')->groupBy('category')->pluck('total', 'category'),
        ]);
    }
}
