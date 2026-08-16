<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $notifications = $user
            ? $user->notifications()->latest()->get()->map(function (DatabaseNotification $notification) {
                return [
                    'id' => $notification->id,
                    'type' => $notification->type,
                    'data' => $notification->data,
                    'read_at' => $notification->read_at,
                    'created_at' => $notification->created_at,
                    'updated_at' => $notification->updated_at,
                ];
            })->values()->all()
            : [];

        return response()->json([
            'message' => 'Notifications list',
            'data' => $notifications,
            'unread_count' => $user ? $user->unreadNotifications()->count() : 0,
        ], 200);
    }

    public function markAsRead(Request $request, string $id): JsonResponse
    {
        $notification = $request->user()?->notifications()->where('id', $id)->first();

        if (!$notification) {
            return response()->json(['message' => 'Notifikasi tidak ditemukan'], 404);
        }

        if ($notification->read_at === null) {
            $notification->markAsRead();
        }

        return response()->json([
            'message' => 'Notifikasi ditandai dibaca',
            'data' => $notification->fresh(),
        ], 200);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $notification = $request->user()?->notifications()->where('id', $id)->first();

        if (!$notification) {
            return response()->json(['message' => 'Notifikasi tidak ditemukan'], 404);
        }

        $notification->delete();

        return response()->json([
            'message' => 'Notifikasi dihapus',
        ], 200);
    }
}
