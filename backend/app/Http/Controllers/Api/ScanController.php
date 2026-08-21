<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;

class ScanController extends Controller
{
    public function index(Event $event, Request $request)
    {
        $query = $event->scans()->with(['guest:id,first_name,last_name,phone,qr_token', 'scanner:id,name']);
        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }
        if ($request->filled('from')) {
            $query->whereDate('scanned_at', '>=', $request->date('from'));
        }
        if ($request->filled('to')) {
            $query->whereDate('scanned_at', '<=', $request->date('to'));
        }
        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->whereHas('guest', function ($guestQuery) use ($search): void {
                $guestQuery->where(function ($nameQuery) use ($search): void {
                    $nameQuery->where('first_name', 'like', "%{$search}%")
                        ->orWhere('last_name', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%")
                        ->orWhere('qr_token', $search);
                });
            });
        }
        return response()->json($query->latest('scanned_at')->paginate(min($request->integer('per_page', 30), 100)));
    }
}
