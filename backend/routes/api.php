<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\InvitationVerificationController;
use App\Http\Controllers\Api\GuestController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ScanController;

Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
Route::middleware('auth:sanctum')->group(function (): void {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/events', [EventController::class, 'index']);
    Route::get('/events/{event}', [EventController::class, 'show']);
    Route::middleware('role:admin')->group(function (): void {
        Route::post('/events', [EventController::class, 'store']);
        Route::put('/events/{event}', [EventController::class, 'update']);
        Route::post('/events/{event}/branding', [EventController::class, 'branding']);
        Route::delete('/events/{event}', [EventController::class, 'destroy']);
        Route::apiResource('events.guests', GuestController::class)->only(['store', 'show', 'update', 'destroy']);
    });
    Route::get('/events/{event}/guests', [GuestController::class, 'index']);
    Route::get('/events/{event}/statistics', [EventController::class, 'statistics']);
    Route::get('/events/{event}/scans', [ScanController::class, 'index']);
    Route::post('/events/{event}/invitations/verify', InvitationVerificationController::class);
});
