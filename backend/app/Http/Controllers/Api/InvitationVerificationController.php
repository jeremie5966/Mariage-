<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Services\InvitationVerificationService;
use Illuminate\Http\Request;

class InvitationVerificationController extends Controller
{
    public function __invoke(Request $request, Event $event, InvitationVerificationService $service)
    {
        $data = $request->validate(['qr_token' => ['required', 'string', 'max:96']]);

        $result = $service->verify($event, $data['qr_token'], $request->user()->id, $request);
        if ($result['status'] !== 'valid') {
            $messages = [
                'invalid' => ['Invitation invalide', 404],
                'blocked' => ['Invitation désactivée', 422],
                'already_used' => ['Invitation déjà utilisée', 409],
            ];
            [$message, $status] = $messages[$result['status']];
            return response()->json(['status' => $result['status'], 'message' => $message], $status);
        }
        return response()->json($result);
    }
}
