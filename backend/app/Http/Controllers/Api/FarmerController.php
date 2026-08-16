<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\OrderResource;
use App\Models\Farmer;
use App\Models\Order;
use App\Models\Product;
use App\Models\SharingOrder;
use App\Models\DeliveryTask;
use App\Models\User;
use App\Models\Waste;
use App\Models\WasteOrder;
use App\Services\OrderService;
use App\Services\PointService;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Laravel\Sanctum\PersonalAccessToken;

class FarmerController extends Controller
{
    public function dashboard(): JsonResponse
    {
        return response()->json(['message' => 'Farmer dashboard data'], 200);
    }

    public function products(Request $request): JsonResponse
    {
        $farmer = $request->user()?->farmer()->first();

        if (!$farmer) {
            return response()->json(['message' => 'Farmer products list', 'data' => []], 200);
        }

        $products = $farmer->products()
            ->with(['farmer.user.address'])
            ->latest()
            ->get();

        $products->each(function (Product $product): void {
            $farmerUser = $product->farmer?->user;
            $farmerName = $farmerUser?->name
                ?? $product->farmer?->farm_name
                ?? '';
            $farmerProfile = $farmerUser?->profile
                ?? $farmerUser?->profile_photo
                ?? '';
            $productDescription = trim((string) ($product->description ?? ''));

            $product->setAttribute('farmer_name', $farmerName);
            $product->setAttribute('farmer_profile', $farmerProfile);
            $product->setAttribute('product_description', $productDescription);
        });

        return response()->json(['message' => 'Farmer products list', 'data' => $products], 200);
    }

    public function createProduct(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'category' => ['required', 'string', 'max:100'],
            'description' => ['nullable', 'string'],
            'price' => ['required', 'numeric', 'min:0'],
            'unit' => ['required', 'string', 'max:50'],
            'stock' => ['required', 'integer', 'min:0'],
            'image' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', 'in:available,sold_out,inactive'],
            'masa_simpan' => ['nullable', 'integer', 'min:0'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $farmer = $user?->farmer()->firstOrCreate(
            ['user_id' => $user?->id],
            [
                'farm_name' => 'Kebun ' . ($user?->name ?? 'Petani'),
                'farm_address' => $user?->address ?? '',
                'verification_status' => 'pending',
            ]
        );

        $productData = [
            'farmer_id' => $farmer->id,
            'name' => trim($request->input('name')),
            'category' => Str::lower(trim((string) $request->input('category', 'sayur'))),
            'description' => $request->input('description'),
            'price' => (float) $request->input('price', 0),
            'unit' => trim((string) $request->input('unit', 'kg')),
            'stock' => (int) $request->input('stock', 0),
            'image' => $request->input('image'),
            'status' => $request->input('status', 'available'),
        ];

        // compute available_until from masa_simpan (days) if provided
        if ($request->filled('masa_simpan')) {
            $days = (int) $request->input('masa_simpan', 0);
            if ($days > 0) {
                $productData['available_until'] = now()->addDays($days);
            }
        }

        $product = Product::create($productData);

        return response()->json([
            'message' => 'Produk berhasil ditambahkan',
            'data' => $product,
        ], 201);
    }

    public function updateProduct(int $id, Request $request): JsonResponse
    {
        $user = $request->user();
        $farmer = $user?->farmer()->first();

        if (!$farmer) {
            return response()->json(['message' => 'Petani tidak ditemukan'], 404);
        }

        $product = $farmer->products()->whereKey($id)->first();

        if (!$product) {
            return response()->json(['message' => 'Produk tidak ditemukan'], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => ['nullable', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string'],
            'price' => ['nullable', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:50'],
            'stock' => ['nullable', 'integer', 'min:0'],
            'image' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', 'in:available,sold_out,inactive'],
            'masa_simpan' => ['nullable', 'integer', 'min:0'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $product->fill([
            'name' => trim((string) $request->input('name', $product->name)),
            'category' => Str::lower(trim((string) $request->input('category', $product->category))),
            'description' => $request->exists('description') ? $request->input('description') : $product->description,
            'price' => (float) $request->input('price', $product->price),
            'unit' => trim((string) $request->input('unit', $product->unit)),
            'stock' => (int) $request->input('stock', $product->stock),
            'image' => $request->exists('image') ? $request->input('image') : $product->image,
            'status' => $request->input('status', $product->status),
        ]);

        $product->save();

        // If masa_simpan provided, compute available_until from the last update timestamp
        if ($request->filled('masa_simpan')) {
            $days = (int) $request->input('masa_simpan', 0);
            if ($days > 0 && $product->updated_at) {
                // use the updated_at timestamp which was set by save()
                $product->available_until = $product->updated_at->addDays($days);
                $product->save();
            }
        }

        return response()->json([
            'message' => 'Produk berhasil diperbarui',
            'data' => $product->fresh(),
        ], 200);
    }

    public function deleteProduct(int $id, Request $request): JsonResponse
    {
        $user = $request->user();
        $farmer = $user?->farmer()->first();

        if (!$farmer) {
            return response()->json(['message' => 'Petani tidak ditemukan'], 404);
        }

        $product = $farmer->products()->whereKey($id)->first();

        if (!$product) {
            return response()->json(['message' => 'Produk tidak ditemukan'], 404);
        }

        $product->delete();

        return response()->json([
            'message' => 'Produk berhasil dihapus',
            'data' => [
                'deleted' => true,
                'id' => $product->getKey(),
            ],
        ], 200);
    }

    public function waste(Request $request): JsonResponse
    {
        $wastes = Waste::query()
            ->whereIn('status', ['requested', 'assigned'])
            ->latest()
            ->get();

        return response()->json([
            'message' => 'Waste submissions for farmers',
            'data' => $wastes->map(function (Waste $waste) {
                return [
                    'id' => $waste->id,
                    'user_id' => $waste->user_id,
                    'waste_type' => $waste->waste_type,
                    'weight' => (float) $waste->weight,
                    'note' => $waste->note,
                    'status' => $waste->status,
                    'image_url' => $waste->image_url,
                    'total_value' => (float) $waste->total_value,
                    'shipping_cost' => (float) $waste->shipping_cost,
                    'farmer_paid_freight' => (bool) $waste->farmer_paid_freight,
                    'created_at' => $waste->created_at,
                    'updated_at' => $waste->updated_at,
                ];
            })->values(),
        ], 200);
    }

    public function claimWastePickup(int $id, Request $request, PointService $pointService, WalletService $walletService): JsonResponse
    {
        $waste = Waste::query()->find($id);

        if (!$waste) {
            return response()->json(['message' => 'Limbah tidak ditemukan'], 404);
        }

        $authenticatedUser = $request->user();
        $token = $request->bearerToken();
        if ($authenticatedUser && $token) {
            $personalAccessToken = PersonalAccessToken::findToken($token);
            if ($personalAccessToken && $personalAccessToken->tokenable) {
                $authenticatedUser = $personalAccessToken->tokenable;
            }
        }

        $farmer = $authenticatedUser?->farmer()->first();
        if (!$farmer && $authenticatedUser) {
            $farmer = $authenticatedUser->farmer()->firstOrCreate(
                ['user_id' => $authenticatedUser->id],
                [
                    'farm_name' => 'Kebun ' . ($authenticatedUser->name ?? 'Petani'),
                    'farm_address' => $authenticatedUser->address ?? '',
                    'verification_status' => 'pending',
                ]
            );
        }

        $waste->update([
            'status' => 'assigned',
        ]);

        $wasteOrder = WasteOrder::create([
            'waste_id' => $waste->id,
            'farmer_id' => $authenticatedUser?->id ?? $request->user()?->id,
            'inhabitans_id' => $waste->user_id,
            'delivery_person_id' => null,
            'status' => 'claimed',
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        $wallet = $walletService->getOrCreateWallet($waste->user);
        $walletService->addBalance(
            $wallet,
            (float) $waste->total_value,
            'waste_sale',
            "Waste sale - {$waste->weight}kg",
            Waste::class,
            $waste->id
        );

        $pointWallet = $pointService->getOrCreatePointWallet($waste->user);
        $wasteType = strtolower(trim((string) ($waste->waste_type ?? '')));
        $multiplier = $wasteType === 'anorganik' ? 300 : 150; // anorganik:300pt/kg, organik:150pt/kg
        $pointsEarned = (int) floor((float) $waste->weight * $multiplier);
        if ($pointsEarned > 0) {
            $pointService->addPoints(
                $pointWallet,
                $pointsEarned,
                'waste',
                "Waste sale - {$waste->weight}kg = {$pointsEarned} points",
                Waste::class,
                $waste->id
            );
        }

        $pickupAddress = $this->resolveWasteAddress($waste->user);
        $destinationAddress = $this->resolveWasteAddress($authenticatedUser);
        $destinationAddress = $this->resolveWasteAddress($wasteOrder->farmer()->first());

        DeliveryTask::create([
            'type' => 'waste_delivery',
            'waste_id' => $waste->id,
            'delivery_person_id' => null,
            'pickup_address' => $pickupAddress,
            'destination_address' => $destinationAddress,
            'scheduled_at' => now(),
            'status' => 'pending',
        ]);

        return response()->json([
            'message' => 'Limbah berhasil diklaim',
            'data' => [
                'id' => $waste->id,
                'user_id' => $waste->user_id,
                'waste_type' => $waste->waste_type,
                'weight' => (float) $waste->weight,
                'note' => $waste->note,
                'address' => $pickupAddress,
                'status' => $waste->status,
                'image_url' => $waste->image_url,
                'total_value' => (float) $waste->total_value,
                'shipping_cost' => (float) $waste->shipping_cost,
                'farmer_paid_freight' => (bool) $waste->farmer_paid_freight,
                'created_at' => $waste->created_at,
                'updated_at' => $waste->updated_at,
            ],
            'waste_order' => $wasteOrder->fresh(),
        ], 200);
    }

    private function resolveWasteAddress(?User $user): string
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

    public function orders(Request $request): JsonResponse
    {
        $farmer = $request->user()?->farmer()->first();

        if (!$farmer) {
            return response()->json(['message' => 'Petani tidak ditemukan'], 404);
        }

        $farmerUser = $farmer->user()->first();
        $orders = Order::query()
            ->where('farmers_id', $farmerUser?->id)
            ->with(['product', 'items.product', 'deliveryTask.deliveryPerson', 'user.address'])
            ->get();

        $sharingOrders = SharingOrder::query()
            ->where('farmers_id', $farmerUser?->id)
            ->with(['receiver', 'items.product', 'deliveryTask.deliveryPerson', 'user.address'])
            ->get();

        $combinedOrders = $orders->concat($sharingOrders)
            ->sortByDesc(fn ($order) => $order->created_at)
            ->values();

        return response()->json([
            'message' => 'Farmer order list',
            'data' => OrderResource::collection($combinedOrders),
        ], 200);
    }

    public function processOrder(int $id, Request $request, OrderService $orderService): JsonResponse
    {
        $farmer = $request->user()?->farmer()->first();

        if (!$farmer) {
            return response()->json(['message' => 'Petani tidak ditemukan'], 404);
        }

        $order = Order::with(['product', 'items.product', 'user.address'])->find($id);
        $sharingOrder = SharingOrder::with(['items.product', 'user.address', 'receiver'])->find($id);

        if (!$order && !$sharingOrder) {
            return response()->json(['message' => 'Pesanan tidak ditemukan'], 404);
        }

        $selectedOrder = null;
        if ($order && $sharingOrder) {
            if ($order->farmers_id === $farmer->user?->id && $sharingOrder->farmers_id !== $farmer->user?->id) {
                $selectedOrder = $order;
            } elseif ($sharingOrder->farmers_id === $farmer->user?->id && $order->farmers_id !== $farmer->user?->id) {
                $selectedOrder = $sharingOrder;
            } else {
                $selectedOrder = $sharingOrder;
            }
        } else {
            $selectedOrder = $order ?? $sharingOrder;
        }

        try {
            $task = $orderService->processFarmerOrder($farmer, $selectedOrder);
            $orderData = $selectedOrder->fresh()->load(['product', 'user.address']);
            if ($selectedOrder instanceof SharingOrder) {
                $orderData->load('receiver');
            }

            return response()->json([
                'message' => 'Pesanan diproses dan task pengiriman dibuat',
                'data' => [
                    'order' => $orderData,
                    'delivery_task' => $task->fresh(),
                ],
            ], 200);
        } catch (\InvalidArgumentException $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
            ], 422);
        } catch (\Throwable $exception) {
            return response()->json([
                'message' => 'Gagal memproses pesanan. Silakan coba kembali.',
                'error' => $exception->getMessage(),
            ], 500);
        }
    }

    public function cancelOrder(int $id, Request $request, OrderService $orderService): JsonResponse
    {
        $farmer = $request->user()?->farmer()->first();

        if (!$farmer) {
            return response()->json(['message' => 'Petani tidak ditemukan'], 404);
        }

        $order = Order::with(['product', 'items.product', 'deliveryTask', 'user.address'])->find($id);
        $sharingOrder = SharingOrder::with(['items.product', 'deliveryTask', 'user.address', 'receiver'])->find($id);

        if (!$order && !$sharingOrder) {
            return response()->json(['message' => 'Pesanan tidak ditemukan'], 404);
        }

        $selectedOrder = null;
        if ($order && $sharingOrder) {
            if ($order->farmers_id === $farmer->user?->id && $sharingOrder->farmers_id !== $farmer->user?->id) {
                $selectedOrder = $order;
            } elseif ($sharingOrder->farmers_id === $farmer->user?->id && $order->farmers_id !== $farmer->user?->id) {
                $selectedOrder = $sharingOrder;
            } else {
                $selectedOrder = $sharingOrder;
            }
        } else {
            $selectedOrder = $order ?? $sharingOrder;
        }

        try {
            $order = $orderService->cancelFarmerOrder($farmer, $selectedOrder);
            $orderData = $order->fresh()->load(['product', 'user.address', 'deliveryTask.deliveryPerson']);
            if ($order instanceof SharingOrder) {
                $orderData->load('receiver');
            }

            return response()->json([
                'message' => 'Pesanan dibatalkan oleh petani',
                'data' => OrderResource::make($orderData),
            ], 200);
        } catch (\InvalidArgumentException $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
            ], 422);
        } catch (\Throwable $exception) {
            return response()->json([
                'message' => 'Gagal membatalkan pesanan. Silakan coba kembali.',
                'error' => $exception->getMessage(),
            ], 500);
        }
    }

    public function income(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $wallet = $user->wallet()->first();
        if (!$wallet) {
            $wallet = $user->wallet()->create(['balance' => 0]);
        }

        return response()->json([
            'message' => 'Saldo bersih berhasil diambil',
            'data' => [
                'balance' => (int) round((float) $wallet->balance),
            ],
        ], 200);
    }

    public function compost(): JsonResponse
    {
        return response()->json(['message' => 'Compost order list'], 200);
    }

    public function createCompostOrder(Request $request): JsonResponse
    {
        return response()->json(['message' => 'Compost order created'], 201);
    }
}
