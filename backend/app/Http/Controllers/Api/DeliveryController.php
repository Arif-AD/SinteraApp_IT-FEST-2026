<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeliveryTask;
use App\Models\SharingOrder;
use App\Models\WastePickup;
use App\Notifications\OrderStatusNotification;
use App\Services\PointService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Notification;
use Laravel\Sanctum\PersonalAccessToken;

class DeliveryController extends Controller
{
    public function dashboard(): JsonResponse
    {
        return response()->json(['message' => 'Delivery dashboard data'], 200);
    }

    public function tasks(): JsonResponse
    {
        $user = request()->user();

        $tasks = DeliveryTask::query()
            ->with(['waste.user', 'waste.wasteOrders.farmer', 'wastePickup.user', 'deliveryPerson', 'order.items.product', 'order.user', 'sharingOrder.items.product', 'sharingOrder.receiver'])
            ->where(function ($q) use ($user) {
                $q->where('status', 'pending')
                  ->orWhere('delivery_person_id', $user?->id);
            })
            ->latest()
            ->get();

        $tasks->each(fn (DeliveryTask $task) => $this->enrichTaskWithRecipient($task));

        return response()->json(['message' => 'Delivery tasks list', 'data' => $tasks], 200);
    }

    public function taskDetail(int $id): JsonResponse
    {
        $task = DeliveryTask::query()->with(['waste.user', 'waste.wasteOrders.farmer', 'wastePickup.user', 'deliveryPerson', 'order.items.product', 'order.user', 'sharingOrder.items.product', 'sharingOrder.receiver'])->find($id);
        if (!$task) {
            return response()->json(['message' => 'Task tidak ditemukan'], 404);
        }

        $this->enrichTaskWithRecipient($task);

        return response()->json(['message' => 'Task detail', 'data' => $task], 200);
    }

    private function enrichTaskWithRecipient(DeliveryTask $task): void
    {
        if (!$task->waste_id || !$task->waste) {
            return;
        }

        $wasteOrder = $task->waste->wasteOrders()->with('farmer')->latest()->first();
        $farmer = $wasteOrder?->farmer;
        $warga = $task->waste->user;

        if ($farmer) {
            $farmer->loadMissing(['address']);
            $warga?->loadMissing(['address']);

            $pickupAddress = $this->resolveWasteAddress($warga);
            $destinationAddress = $this->resolveWasteAddress($farmer);

            $addressRecord = $farmer->address()->first();
            $resolvedParts = array_filter([
                $addressRecord?->address,
                $addressRecord?->detail_house,
            ], fn ($value) => !blank($value));
            $resolvedAddress = !empty($resolvedParts)
                ? trim(implode(', ', array_map('strval', $resolvedParts)))
                : 'Alamat belum diisi';

            $recipientUser = $farmer->toArray();
            $recipientUser['address'] = $addressRecord?->address;
            $recipientUser['detail_house'] = $addressRecord?->detail_house;
            $recipientUser['latitude'] = $addressRecord?->latitude;
            $recipientUser['longitude'] = $addressRecord?->longitude;

            $task->waste->setAttribute('farmer', $recipientUser);
            $task->setAttribute('recipient_user', $recipientUser);
            $task->setAttribute('pickup_address', $pickupAddress);
            $task->setAttribute('destination_address', $destinationAddress ?: $resolvedAddress);
        }
    }

    private function resolveWasteAddress($user): string
    {
        $addressRecord = $user?->address()->first();
        $resolvedParts = array_filter([
            $addressRecord?->address,
            $addressRecord?->detail_house,
        ], fn ($value) => !blank($value));

        if (!empty($resolvedParts)) {
            return trim(implode(', ', array_map('strval', $resolvedParts)));
        }

        return 'Alamat belum diisi';
    }

    public function acceptTask(int $id): JsonResponse
    {
        $user = request()->user();
        $token = request()->bearerToken();
        if ($token) {
            $pat = PersonalAccessToken::findToken($token);
            if ($pat && $pat->tokenable) {
                $user = $pat->tokenable;
            }
        }
        $task = DeliveryTask::query()->find($id);
        if (!$task) {
            return response()->json(['message' => 'Task tidak ditemukan'], 404);
        }

        if (!in_array($task->status, ['pending', 'assigned'], true)) {
            return response()->json(['message' => 'Task tidak dapat diterima'], 409);
        }

        if ($task->status === 'assigned' && $task->delivery_person_id !== $user?->id) {
            return response()->json(['message' => 'Task tidak dapat diterima'], 403);
        }

        $hasActiveTask = DeliveryTask::query()
            ->where('delivery_person_id', $user?->id)
            ->where('id', '!=', $task->id)
            ->whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit'])
            ->exists();

        if ($hasActiveTask) {
            return response()->json([
                'message' => 'Pengantar sedang dalam tugas. Silakan tunggu tugas saat ini selesai terlebih dahulu.',
            ], 409);
        }

        $task->update([
            'delivery_person_id' => $user?->id,
            'status' => 'accepted',
            'scheduled_at' => now(),
        ]);

        Notification::send($user, new OrderStatusNotification(
            title: 'Pesanan masuk',
            body: 'Anda menerima tugas pengiriman baru.',
            type: 'activity',
            orderId: $task->order_id ?? $task->sharing_order_id,
        ));

        if ($task->order_id) {
            $order = \App\Models\Order::query()->find($task->order_id);
            if ($order) {
                $order->update(['delivery_id' => $user?->id]);

                $customer = $order->user()->first();
                if ($customer) {
                    Notification::send($customer, new OrderStatusNotification(
                        title: 'Pesanan dikirim',
                        body: 'Pengantar telah mengambil tugas pengiriman pesanan Anda.',
                        type: 'activity',
                        orderId: (int) $order->id,
                    ));
                }

                $farmerUser = $order->product?->farmer?->user()->first();
                if ($farmerUser) {
                    Notification::send($farmerUser, new OrderStatusNotification(
                        title: 'Pesanan dikirim',
                        body: 'Kurir telah menerima tugas pengiriman pesanan Anda.',
                        type: 'activity',
                        orderId: (int) $order->id,
                    ));
                }
            }
        }

        if ($task->sharing_order_id) {
            $sharingOrder = \App\Models\SharingOrder::query()->find($task->sharing_order_id);
            if ($sharingOrder) {
                $sharingOrder->update(['delivery_id' => $user?->id]);

                $customer = $sharingOrder->user()->first();
                if ($customer) {
                    Notification::send($customer, new OrderStatusNotification(
                        title: 'Pesanan dikirim',
                        body: 'Pengantar telah mengambil tugas pengiriman pesanan Anda.',
                        type: 'activity',
                        orderId: (int) $sharingOrder->id,
                    ));
                }

                $farmerUser = $sharingOrder->product?->farmer?->user()->first();
                if ($farmerUser) {
                    Notification::send($farmerUser, new OrderStatusNotification(
                        title: 'Pesanan dikirim',
                        body: 'Kurir telah menerima tugas pengiriman pesanan Anda.',
                        type: 'activity',
                        orderId: (int) $sharingOrder->id,
                    ));
                }
            }
        }

        // Also assign the delivery person on related waste order when a task is accepted
        if ($task->waste_id) {
            // Prefer the most recent waste_order that is not already delivered
            $wasteOrder = \App\Models\WasteOrder::query()
                ->where('waste_id', $task->waste_id)
                ->where('status', '!=', 'delivered')
                ->latest()
                ->first();
            if ($wasteOrder) {
                $wasteOrder->delivery_person_id = $user?->id;
                $wasteOrder->save();
                \Illuminate\Support\Facades\DB::table('waste_orders')->where('id', $wasteOrder->id)->update(['delivery_person_id' => $user?->id]);
                \Illuminate\Support\Facades\Log::info('wasteOrder after accept', ['waste_order_id' => $wasteOrder->id, 'delivery_person_id' => $wasteOrder->delivery_person_id]);
            }
        }

        return response()->json(['message' => 'Task diterima', 'data' => $task->fresh()], 200);
    }

    public function pickupTask(int $id): JsonResponse
    {
        $user = request()->user();
        $task = DeliveryTask::query()->find($id);
        if (!$task) {
            return response()->json(['message' => 'Task tidak ditemukan'], 404);
        }

        if ($task->delivery_person_id !== $user?->id) {
            return response()->json(['message' => 'Akses ditolak'], 403);
        }

        if ($task->status !== 'accepted') {
            return response()->json(['message' => 'Task belum dapat dipickup'], 409);
        }

        $task->update(['status' => 'picked_up']);

        return response()->json(['message' => 'Pickup dikonfirmasi', 'data' => $task->fresh()], 200);
    }

    public function completeTask(int $id): JsonResponse
    {
        $user = request()->user();
        $token = request()->bearerToken();
        if ($token) {
            $pat = PersonalAccessToken::findToken($token);
            if ($pat && $pat->tokenable) {
                $user = $pat->tokenable;
            }
        }
        $task = DeliveryTask::query()->find($id);
        if (!$task) {
            return response()->json(['message' => 'Task tidak ditemukan'], 404);
        }

        if ($task->delivery_person_id !== $user?->id) {
            return response()->json(['message' => 'Akses ditolak'], 403);
        }

        // Allow completion regardless of the current task status.
        // Previously required 'picked_up'; user expects direct completion on button press.

        $task->update([
            'status' => 'delivered',
            'completed_at' => now(),
        ]);

        // Also update related waste pickup status if present
        if ($task->waste_pickup_id) {
            $pickup = WastePickup::query()->find($task->waste_pickup_id);
            if ($pickup) {
                $pickup->update(['status' => 'collected']);
            }
        }

        // Also update related waste order assignment if present
        if ($task->waste_id) {
            // Prefer the most recent waste_order that is not already delivered
            $wasteOrder = \App\Models\WasteOrder::query()
                ->where('waste_id', $task->waste_id)
                ->where('status', '!=', 'delivered')
                ->latest()
                ->first();
            if ($wasteOrder) {
                $wasteOrder->delivery_person_id = $user?->id;
                $wasteOrder->status = 'delivered';
                $wasteOrder->save();
                \Illuminate\Support\Facades\DB::table('waste_orders')->where('id', $wasteOrder->id)->update([
                    'delivery_person_id' => $user?->id,
                    'status' => 'delivered',
                ]);
                \Illuminate\Support\Facades\Log::info('wasteOrder after complete', ['waste_order_id' => $wasteOrder->id, 'delivery_person_id' => $wasteOrder->delivery_person_id, 'status' => $wasteOrder->status]);
            }
        }

        // Also update related order status if present (agricultural deliveries)
        if ($task->order_id) {
            $order = \App\Models\Order::query()->find($task->order_id);
            if ($order) {
                $order->update([
                    'status' => 'delivered',
                    'delivery_status' => 'delivered',
                    'delivery_id' => $user?->id,
                ]);

                Notification::send($user, new OrderStatusNotification(
                    title: 'Pesanan selesai',
                    body: 'Tugas pengiriman Anda telah selesai.',
                    type: 'activity',
                    orderId: (int) $order->id,
                ));

                $customer = $order->user()->first();
                if ($customer) {
                    Notification::send($customer, new OrderStatusNotification(
                        title: 'Pesanan selesai',
                        body: 'Pesanan Anda telah sampai dan selesai dikirim.',
                        type: 'activity',
                        orderId: (int) $order->id,
                    ));
                }

                $farmerUser = $order->product?->farmer?->user()->first();
                if ($farmerUser) {
                    Notification::send($farmerUser, new OrderStatusNotification(
                        title: 'Pesanan selesai',
                        body: 'Pesanan Anda telah berhasil sampai ke tujuan.',
                        type: 'activity',
                        orderId: (int) $order->id,
                    ));
                }
            }
        }

        if ($task->sharing_order_id) {
            $sharingOrder = \App\Models\SharingOrder::query()->find($task->sharing_order_id);
            if ($sharingOrder) {
                $wasAlreadyDelivered = $sharingOrder->delivery_status === 'delivered' || $sharingOrder->status === 'delivered';

                $sharingOrder->update([
                    'status' => 'delivered',
                    'delivery_status' => 'delivered',
                    'delivery_id' => $user?->id,
                ]);

                Notification::send($user, new OrderStatusNotification(
                    title: 'Pesanan selesai',
                    body: 'Tugas pengiriman Anda telah selesai.',
                    type: 'activity',
                    orderId: (int) $sharingOrder->id,
                ));

                $customer = $sharingOrder->user()->first();
                if ($customer) {
                    Notification::send($customer, new OrderStatusNotification(
                        title: 'Pesanan selesai',
                        body: 'Pesanan berbagi Anda telah selesai dan diterima.',
                        type: 'activity',
                        orderId: (int) $sharingOrder->id,
                    ));
                }

                $farmerUser = $sharingOrder->product?->farmer?->user()->first();
                if ($farmerUser) {
                    Notification::send($farmerUser, new OrderStatusNotification(
                        title: 'Pesanan selesai',
                        body: 'Pesanan Anda telah berhasil sampai ke tujuan.',
                        type: 'activity',
                        orderId: (int) $sharingOrder->id,
                    ));
                }

                if (!$wasAlreadyDelivered) {
                    $pointService = app(PointService::class);
                    $inhabitant = $sharingOrder->inhabitant;
                    $orderAmount = $sharingOrder->total_amount ?? $sharingOrder->final_amount ?? 0;
                    $pointsEarned = (int) floor(($orderAmount / 1000) * 25);

                    if ($inhabitant && $pointsEarned > 0) {
                        $pointWallet = $pointService->getOrCreatePointWallet($inhabitant);
                        $pointService->addPoints(
                            $pointWallet,
                            $pointsEarned,
                            'other',
                            "Bonus poin berbagi untuk pesanan #{$sharingOrder->id} = {$pointsEarned} poin",
                            SharingOrder::class,
                            $sharingOrder->id
                        );
                    }
                }
            }
        }

        return response()->json(['message' => 'Task diselesaikan', 'data' => $task->fresh()], 200);
    }
}
