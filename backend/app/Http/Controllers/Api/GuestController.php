<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreGuestRequest;
use App\Http\Requests\UpdateGuestRequest;
use App\Models\Event;
use App\Models\Guest;
use App\Services\InvitationVerificationService;
use Illuminate\Http\Request;

class GuestController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Event $event, Request $request)
    {
        return response()->json($event->guests()->latest()->paginate($request->integer('per_page', 25)));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Event $event, StoreGuestRequest $request, InvitationVerificationService $service)
    {
        $guest = $event->guests()->create([
            ...$request->validated(),
            'qr_token' => $service->generateToken(),
            'qr_generated_at' => now(),
        ]);
        return response()->json($guest, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Event $event, Guest $guest)
    {
        abort_unless($guest->event_id === $event->id, 404);
        return response()->json($guest);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Event $event, Guest $guest, UpdateGuestRequest $request)
    {
        abort_unless($guest->event_id === $event->id, 404);
        $guest->update($request->validated());
        return response()->json($guest->refresh());
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Event $event, Guest $guest)
    {
        abort_unless($guest->event_id === $event->id, 404);
        $guest->delete();
        return response()->noContent();
    }
}
