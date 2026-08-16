<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderChatMessage;
use App\Models\OrderChatRoom;
use App\Models\SharingOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class OrderChatController extends Controller
{
    private const VALID_ORDER_TYPES = ['order', 'sharing_order'];
    private const VALID_CHAT_CHANNELS = ['warga_petani', 'warga_pengantar', 'petani_pengantar'];

    public function index(Request $request, string $orderType, int $orderId): JsonResponse
    {
        $order = $this->resolveOrder($orderType, $orderId);
        if (!$order) {
            return response()->json(['message' => 'Pesanan tidak ditemukan'], 404);
        }

        if (!$this->currentUserCanAccessOrder($request, $order, $orderType)) {
            return response()->json(['message' => 'Akses ditolak'], 403);
        }

        $chatChannel = $this->resolveChatChannel($request, $order, $orderType);
        if (!$chatChannel) {
            return response()->json(['message' => 'Parameter chat channel tidak valid atau tidak tersedia'], 400);
        }

        if (!$this->currentUserCanAccessChannel($request, $order, $chatChannel)) {
            return response()->json(['message' => 'Akses chat ditolak'], 403);
        }

        [$participantA, $participantB] = $this->resolveParticipants($request, $order, $chatChannel);

        $chatRoom = OrderChatRoom::firstOrCreate([
            'order_type' => $orderType,
            'order_id' => $orderId,
            'chat_channel' => $chatChannel,
        ], [
            'participant_a_id' => $participantA,
            'participant_b_id' => $participantB,
        ]);

        if ($chatRoom->participant_a_id !== $participantA || $chatRoom->participant_b_id !== $participantB) {
            $chatRoom->update([
                'participant_a_id' => $participantA,
                'participant_b_id' => $participantB,
            ]);
        }

        $messages = $chatRoom->messages()
            ->with('sender')
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(function (OrderChatMessage $message) {
                return [
                    'id' => $message->id,
                    'sender' => $message->sender ? [
                        'id' => $message->sender->id,
                        'name' => $message->sender->name,
                        'role' => $message->sender->role,
                    ] : null,
                    'message' => $message->message,
                    'created_at' => $message->created_at?->toDateTimeString(),
                ];
            });

        return response()->json([
            'message' => 'Order chat messages',
            'data' => [
                'chat_room' => [
                    'id' => $chatRoom->id,
                    'order_type' => $chatRoom->order_type,
                    'order_id' => $chatRoom->order_id,
                    'chat_channel' => $chatRoom->chat_channel,
                ],
                'messages' => $messages,
            ],
        ], 200);
    }

    public function store(Request $request, string $orderType, int $orderId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'message' => ['required', 'string', 'max:2000'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $order = $this->resolveOrder($orderType, $orderId);
        if (!$order) {
            return response()->json(['message' => 'Pesanan tidak ditemukan'], 404);
        }

        if (!$this->currentUserCanAccessOrder($request, $order, $orderType)) {
            return response()->json(['message' => 'Akses ditolak'], 403);
        }

        $chatChannel = $this->resolveChatChannel($request, $order, $orderType);
        if (!$chatChannel) {
            return response()->json(['message' => 'Parameter chat channel tidak valid atau tidak tersedia'], 400);
        }

        if (!$this->currentUserCanAccessChannel($request, $order, $chatChannel)) {
            return response()->json(['message' => 'Akses chat ditolak'], 403);
        }

        [$participantA, $participantB] = $this->resolveParticipants($request, $order, $chatChannel);

        $chatRoom = OrderChatRoom::firstOrCreate([
            'order_type' => $orderType,
            'order_id' => $orderId,
            'chat_channel' => $chatChannel,
        ], [
            'participant_a_id' => $participantA,
            'participant_b_id' => $participantB,
        ]);

        if ($chatRoom->participant_a_id !== $participantA || $chatRoom->participant_b_id !== $participantB) {
            $chatRoom->update([
                'participant_a_id' => $participantA,
                'participant_b_id' => $participantB,
            ]);
        }

        $message = $chatRoom->messages()->create([
            'sender_id' => $request->user()->id,
            'message' => $request->input('message'),
        ]);

        return response()->json([
            'message' => 'Pesan chat berhasil dikirim',
            'data' => [
                'id' => $message->id,
                'sender' => [
                    'id' => $request->user()->id,
                    'name' => $request->user()->name,
                    'role' => $request->user()->role,
                ],
                'message' => $message->message,
                'created_at' => $message->created_at?->toDateTimeString(),
            ],
        ], 201);
    }

    private function resolveChatChannel(Request $request, $order, string $orderType): ?string
    {
        $channel = $request->query('channel') ?? $request->input('channel');

        if ($channel !== null && in_array($channel, self::VALID_CHAT_CHANNELS, true)) {
            return $channel;
        }

        return $this->determineDefaultChatChannel($request, $order, $orderType);
    }

    private function determineDefaultChatChannel(Request $request, $order, string $orderType): ?string
    {
        $userId = $request->user()->id;
        $hasFarmer = !empty($order->farmers_id ?? $order->farmer_id ?? null);
        $hasDelivery = !empty($order->delivery_id ?? $order->delivery_person_id ?? null);

        if ($userId === ($order->inhabitans_id ?? $order->receiver_id ?? null) || $userId === ($order->farmers_id ?? $order->farmer_id ?? null)) {
            if ($hasFarmer) {
                return 'warga_petani';
            }
        }

        if ($userId === ($order->delivery_id ?? $order->delivery_person_id ?? null)) {
            if ($hasFarmer) {
                return 'petani_pengantar';
            }

            return 'warga_pengantar';
        }

        if ($hasFarmer) {
            return 'warga_petani';
        }

        if ($hasDelivery) {
            return 'warga_pengantar';
        }

        return null;
    }

    private function currentUserCanAccessChannel(Request $request, $order, string $chatChannel): bool
    {
        if (!$request->user() || !$order) {
            return false;
        }

        return in_array($chatChannel, self::VALID_CHAT_CHANNELS, true);
    }

    private function resolveParticipants(Request $request, $order, string $chatChannel): array
    {
        $userId = $request->user()->id;
        $participantIds = [];

        switch ($chatChannel) {
            case 'warga_petani':
                $participantIds = [$order->inhabitans_id ?? $order->receiver_id ?? null, $order->farmers_id ?? $order->farmer_id ?? null];
                break;
            case 'warga_pengantar':
                $participantIds = [$order->inhabitans_id ?? $order->receiver_id ?? null, $order->delivery_id ?? $order->delivery_person_id ?? null];
                break;
            case 'petani_pengantar':
                $participantIds = [$order->farmers_id ?? $order->farmer_id ?? null, $order->delivery_id ?? $order->delivery_person_id ?? null];
                break;
        }

        $participantIds = array_filter($participantIds, fn ($id) => $id !== null);
        sort($participantIds);

        if (count($participantIds) !== 2) {
            return [$userId, $userId];
        }

        return [$participantIds[0], $participantIds[1]];
    }

    public function rooms(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $chatRooms = OrderChatRoom::with(['participantA', 'participantB', 'messages.sender'])
            ->where(function ($query) use ($userId) {
                $query->where('participant_a_id', $userId)
                      ->orWhere('participant_b_id', $userId);
            })
            ->get()
            ->map(function (OrderChatRoom $room) use ($userId) {
                $partner = $room->participant_a_id === $userId ? $room->participantB : $room->participantA;
                $lastMessage = $room->messages->sortByDesc('created_at')->first();

                return [
                    'id' => $room->id,
                    'chat_channel' => $room->chat_channel,
                    'partner' => $partner ? [
                        'id' => $partner->id,
                        'name' => $partner->name,
                        'role' => $partner->role,
                        'profile' => $partner->profile ?? $partner->profile_photo ?? null,
                    ] : null,
                    'last_message' => $lastMessage ? [
                        'text' => $lastMessage->message,
                        'sender_id' => $lastMessage->sender_id,
                        'sender_name' => $lastMessage->sender?->name,
                        'created_at' => $lastMessage->created_at?->toDateTimeString(),
                    ] : null,
                    'order_type' => $room->order_type,
                    'order_id' => $room->order_id,
                ];
            });

        return response()->json([
            'message' => 'Chat rooms',
            'data' => $chatRooms,
        ], 200);
    }

    private function resolveOrder(string $orderType, int $orderId)
    {
        if ($orderType === 'sharing_order') {
            return SharingOrder::with(['user', 'receiver', 'farmer', 'deliveryPerson'])->find($orderId)
                ?? Order::with(['user', 'farmerUser', 'deliveryPerson'])->find($orderId);
        }

        return Order::with(['user', 'farmerUser', 'deliveryPerson'])->find($orderId)
            ?? SharingOrder::with(['user', 'receiver', 'farmer', 'deliveryPerson'])->find($orderId);
    }

    private function currentUserCanAccessOrder(Request $request, $order, string $orderType): bool
    {
        $user = $request->user();
        if (!$user || !$order) {
            return false;
        }

        return true;
    }
}
