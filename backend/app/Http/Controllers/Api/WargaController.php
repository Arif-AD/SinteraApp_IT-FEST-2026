<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\OrderResource;
use App\Http\Resources\UserResource;
use App\Models\Order;
use App\Models\PointTransaction;
use App\Models\PointWallet;
use App\Models\Product;
use App\Models\ProductRating;
use App\Models\SharingOrder;
use App\Models\User;
use App\Models\Waste;
use App\Models\WasteOrder;
use App\Services\OrderService;
use App\Services\PointService;
use App\Exceptions\InsufficientPointsException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class WargaController extends Controller
{
    public function home(): JsonResponse
    {
        return response()->json(['message' => 'Warga home data'], 200);
    }

    public function products(Request $request, OrderService $orderService): JsonResponse
    {
        $products = Product::query()
            ->where('status', 'available')
            ->whereNull('deleted_at')
            ->with(['farmer.user.address'])
            ->latest()
            ->get();

        $user = $request->user();

        $products->each(function (Product $product) use ($user, $orderService): void {
            $farmerUser = $product->farmer?->user;
            $addressRecord = $farmerUser?->address;

            $farmerName = $farmerUser?->name
                ?? $product->farmer?->farm_name
                ?? '';

            $farmerProfile = $farmerUser?->profile
                ?? $farmerUser?->profile_photo
                ?? '';

            $productDescription = trim((string) ($product->description ?? ''));
            $farmerAddress = $addressRecord?->address ?: '';
            $farmerDetailHouse = $addressRecord?->detail_house ?: '';

            $shippingPreview = $user ? $orderService->calculateShippingData($product, $user, (float) $product->price) : [
                'base_fee' => 0,
                'distance_fee' => 0,
                'total_shipping' => 0,
                'farmer_subsidy' => 0,
                'customer_shipping' => 0,
                'shipping_distance_km' => 0,
                'shipping_note' => 'Biaya pengiriman dihitung otomatis berdasarkan jarak.',
            ];

            $product->setAttribute('farmer_name', $farmerName);
            $product->setAttribute('farmer_profile', $farmerProfile);
            $product->setAttribute('farmer_address', $farmerAddress);
            $product->setAttribute('farmer_detail_house', $farmerDetailHouse);
            $product->setAttribute('product_description', $productDescription);
            $product->setAttribute('shipping_preview', $shippingPreview);
        });

        return response()->json([
            'message' => 'Products list for warga',
            'data' => $products,
        ], 200);
    }

    public function groupBuyings(): JsonResponse
    {
        return response()->json(['message' => 'Group buying listings'], 200);
    }

    public function joinGroupBuying(int $id): JsonResponse
    {
        return response()->json(['message' => "Joined group buying {$id}"], 200);
    }

    public function orders(Request $request): JsonResponse
    {
        $user = $request->user();

        $orderEagerLoads = ['items.product', 'deliveryTask.deliveryPerson', 'user.address', 'productRatings'];
        if (Schema::hasColumn('orders', 'product_id')) {
            $orderEagerLoads[] = 'product';
        }

        $orders = $user->orders()
            ->with($orderEagerLoads)
            ->latest()
            ->get();

        $sharingOrders = $user->sharingOrders()
            ->with(['receiver', 'items.product', 'deliveryTask.deliveryPerson', 'user.address', 'product', 'productRatings'])
            ->latest()
            ->get();

        $combinedOrders = $orders->concat($sharingOrders)
            ->sortByDesc(fn ($order) => $order->created_at)
            ->values();

        return response()->json([
            'message' => 'Warga order history',
            'data' => OrderResource::collection($combinedOrders),
        ], 200);
    }

    public function createOrder(Request $request, OrderService $orderService): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'product_id' => ['sometimes', 'required_without:items', 'integer'],
            'quantity' => ['sometimes', 'required_with:product_id', 'integer', 'min:1'],
            'items' => ['sometimes', 'required_without:product_id', 'array', 'min:1'],
            'items.*.product_id' => ['required_with:items', 'integer'],
            'items.*.quantity' => ['required_with:items', 'integer', 'min:1'],
            'receiver_id' => ['sometimes', 'nullable', 'integer'],
            'receiver_name' => ['sometimes', 'nullable', 'string'],
            'receiver_phone' => ['sometimes', 'nullable', 'string'],
            'receiver_address' => ['sometimes', 'nullable', 'string'],
            'receiver_detail_house' => ['sometimes', 'nullable', 'string'],
            'use_points' => ['sometimes', 'integer', 'in:0,1'],
            'used_points' => ['sometimes', 'integer', 'min:1'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = $request->user();

            $receiverId = $request->input('receiver_id');
            $receiverMeta = [
                'receiver_name' => $request->input('receiver_name'),
                'receiver_phone' => $request->input('receiver_phone'),
                'receiver_address' => $request->input('receiver_address'),
                'receiver_detail_house' => $request->input('receiver_detail_house'),
            ];

            $usePoints = (int) $request->input('use_points', 0) === 1;
            $usedPoints = (int) $request->input('used_points', 0);

            if ($usePoints && $usedPoints <= 0) {
                return response()->json([
                    'message' => 'Jumlah poin yang digunakan harus lebih dari 0 ketika menggunakan poin.',
                ], 422);
            }

            $pointService = app(PointService::class);

            $order = DB::transaction(function () use ($user, $request, $orderService, $receiverId, $receiverMeta, $usePoints, $usedPoints, $pointService) {
                if ($receiverId !== null) {
                    if ($request->filled('items')) {
                        $order = $orderService->createSharingOrder($user, $request->input('items'), (int) $receiverId, 1, $receiverMeta);
                    } else {
                        $order = $orderService->createSharingOrder(
                            $user,
                            (int) $request->input('product_id'),
                            (int) $receiverId,
                            (int) $request->input('quantity'),
                            $receiverMeta,
                        );
                    }
                } else {
                    if ($request->filled('items')) {
                        $order = $orderService->createOrder($user, $request->input('items'));
                    } else {
                        $order = $orderService->createOrder(
                            $user,
                            (int) $request->input('product_id'),
                            (int) $request->input('quantity'),
                        );
                    }
                }

                if ($usePoints && $usedPoints > 0) {
                    $pointWallet = $pointService->getOrCreatePointWallet($user);
                    $pointService->deductPoints(
                        $pointWallet,
                        $usedPoints,
                        'other',
                        'Pembayaran pesanan dengan poin',
                        'Order',
                        $order->id,
                    );

                    if (Schema::hasColumn('orders', 'discount_amount')) {
                        $discountAmount = $usedPoints * 10;
                        $order->discount_amount = min($discountAmount, $order->final_amount);
                        $order->final_amount = max(0, $order->final_amount - $order->discount_amount);
                        $order->save();
                    }
                }

                return $order;
            });

            return response()->json([
                'message' => 'Order created successfully',
                'data' => OrderResource::make($order->load(['items.product'])),
            ], 201);
        } catch (\InvalidArgumentException | ModelNotFoundException $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
            ], 422);
        } catch (\Throwable $exception) {
            Log::error('CreateOrder error: ' . $exception->getMessage() . "\n" . $exception->getTraceAsString());
            return response()->json([
                'message' => 'Terjadi kesalahan saat membuat pesanan. Silakan coba kembali.',
            ], 500);
        }
    }

    public function rateOrder(int $id, Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $rating = (int) $request->input('rating');
        $user = $request->user();

        $orderQuery = Order::where('id', $id)
            ->where('inhabitans_id', $user->id)
            ->with(['items.product']);
        if (Schema::hasColumn('orders', 'product_id')) {
            $orderQuery->with('product');
        }
        $order = $orderQuery->first();

        $sharingOrder = SharingOrder::with(['product', 'items.product'])
            ->where('id', $id)
            ->where('inhabitans_id', $user->id)
            ->first();

        if (!$order && !$sharingOrder) {
            return response()->json([
                'message' => 'Pesanan tidak ditemukan atau tidak dimiliki oleh pengguna saat ini.',
            ], 404);
        }

        $selectedOrder = $order ?? $sharingOrder;
        $status = strtolower((string) $selectedOrder->status);
        $deliveryStatus = strtolower((string) $selectedOrder->delivery_status);
        $isCompleted = in_array($status, ['completed', 'delivered', 'selesai'], true)
            || in_array($deliveryStatus, ['completed', 'delivered', 'selesai'], true);

        if (!$isCompleted) {
            return response()->json([
                'message' => 'Rating hanya dapat diberikan pada pesanan yang selesai atau telah terkirim.',
            ], 422);
        }

        $product = $selectedOrder->product
            ?? $selectedOrder->items->first()?->product
            ?? null;

        if (!$product) {
            return response()->json([
                'message' => 'Produk untuk pesanan ini tidak tersedia.',
            ], 404);
        }

        $ratingData = [
            'inhabitans_id' => $user->id,
            'product_id' => $product->id,
            'rating' => $rating,
        ];

        if ($order !== null) {
            $ratingData['order_id'] = $order->id;
        }

        if ($sharingOrder !== null) {
            $ratingData['sharing_order_id'] = $sharingOrder->id;
        }

        /** @var ProductRating $productRating */
        $productRating = ProductRating::updateOrCreate(
            array_filter([
                'inhabitans_id' => $user->id,
                'product_id' => $product->id,
                'order_id' => $order?->id,
                'sharing_order_id' => $sharingOrder?->id,
            ]),
            $ratingData,
        );

        return response()->json([
            'message' => 'Rating produk berhasil disimpan.',
            'data' => [
                'rating_id' => $productRating->id,
                'product_rating' => $productRating->rating,
            ],
        ], 200);
    }

    public function recipients(Request $request): JsonResponse
    {
        $users = User::query()
            ->where('role', 'warga')
            ->where('id', '<>', $request->user()->id)
            ->whereHas('address')
            ->with('address')
            ->get();

        return response()->json([
            'message' => 'Warga recipients list',
            'data' => UserResource::collection($users),
        ], 200);
    }

    public function sharing(): JsonResponse
    {
        return response()->json(['message' => 'Sharing posts list'], 200);
    }

    public function createSharing(Request $request): JsonResponse
    {
        return response()->json(['message' => 'Sharing post created'], 201);
    }

    public function waste(Request $request): JsonResponse
    {
        $wastes = Waste::query()
            ->where('user_id', $request->user()->id)
            ->with(['wasteOrders.inhabitant.address', 'user.address'])
            ->latest()
            ->get();

        return response()->json([
            'message' => 'Waste submissions list',
            'data' => $wastes->map(function (Waste $waste) {
                return [
                    'id' => $waste->id,
                    'user_id' => $waste->user_id,
                    'waste_type' => $waste->waste_type,
                    'weight' => (float) $waste->weight,
                    'note' => $waste->note,
                    'address' => $this->resolveWasteAddressFromOrder($waste),
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

    private function resolveWasteAddressFromOrder(Waste $waste): string
    {
        $latestOrder = $waste->wasteOrders->sortByDesc('created_at')->first();
        $inhabitant = $latestOrder?->inhabitant;

        $addressRecord = $inhabitant?->address ?? $waste->user?->address;
        if ($addressRecord) {
            $parts = array_filter([
                $addressRecord->address ?? null,
                $addressRecord->detail_house ?? null,
            ], fn ($value) => !blank($value));

            if (!empty($parts)) {
                return trim(implode(', ', array_map('strval', $parts)));
            }
        }

        return 'Alamat belum diisi';
    }

    public function showWastePickup(int $id, Request $request): JsonResponse
    {
        $waste = Waste::query()
            ->with(['wasteOrders.inhabitant.address', 'user.address'])
            ->find($id);

        if (!$waste) {
            return response()->json(['message' => 'Limbah tidak ditemukan'], 404);
        }

        $latestOrder = $waste->wasteOrders()->latest()->first();
        $inhabitant = $latestOrder?->inhabitant;

        $residentName = $inhabitant?->name ?? $waste->user?->name ?? '';
        $residentPhone = $inhabitant?->phone ?? $waste->user?->phone ?? '';

        $addressRecord = $inhabitant?->address ?? $waste->user?->address;
        $resolvedAddress = 'Alamat belum diisi';
        if ($addressRecord) {
            $parts = array_filter([
                $addressRecord->address ?? null,
                $addressRecord->detail_house ?? null,
            ], fn ($v) => !blank($v));
            if (!empty($parts)) {
                $resolvedAddress = trim(implode(', ', array_map('strval', $parts)));
            }
        }

        return response()->json([
            'message' => 'Waste detail',
            'data' => [
                'id' => $waste->id,
                'resident' => [
                    'id' => $inhabitant?->id ?? $waste->user?->id,
                    'name' => $residentName,
                    'phone' => $residentPhone,
                    'address' => $resolvedAddress,
                ],
                'user_id' => $waste->user_id,
                'waste_type' => $waste->waste_type,
                'weight' => (float) $waste->weight,
                'note' => $waste->note,
                'address' => $resolvedAddress,
                'status' => $waste->status,
                'image_url' => $waste->image_url,
                'total_value' => (float) $waste->total_value,
                'shipping_cost' => (float) $waste->shipping_cost,
                'farmer_paid_freight' => (bool) $waste->farmer_paid_freight,
                'created_at' => $waste->created_at,
                'updated_at' => $waste->updated_at,
            ],
        ], 200);
    }

    public function createWastePickup(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'waste_type' => ['required', 'string', 'max:100'],
            'weight' => ['required', 'numeric', 'min:0.1'],
            'note' => ['nullable', 'string', 'max:1000'],
            'address' => ['nullable', 'string', 'max:500'],
            'image_url' => ['nullable', 'string', 'max:2048'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $wasteType = trim((string) $request->input('waste_type'));
        $weight = (float) $request->input('weight');
        $imageUrl = trim((string) $request->input('image_url', ''));
        $resolvedAddress = $this->resolvePickupAddress($user, $request->input('address'));
        $pricePerKg = $this->getDefaultPrice($wasteType);
        $totalValue = round($weight * $pricePerKg, 2);

        $waste = Waste::create([
            'user_id' => $user->id,
            'waste_type' => $wasteType,
            'weight' => $weight,
            'note' => $request->input('note'),
            'status' => 'requested',
            'image_url' => $imageUrl !== '' ? $imageUrl : null,
            'total_value' => $totalValue,
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        return response()->json([
            'message' => 'Waste submission created',
            'data' => [
                'id' => $waste->id,
                'user_id' => $waste->user_id,
                'waste_type' => $waste->waste_type,
                'weight' => (float) $waste->weight,
                'note' => $waste->note,
                'address' => $resolvedAddress,
                'status' => $waste->status,
                'image_url' => $waste->image_url,
                'total_value' => (float) $waste->total_value,
                'shipping_cost' => (float) $waste->shipping_cost,
                'farmer_paid_freight' => (bool) $waste->farmer_paid_freight,
                'created_at' => $waste->created_at,
                'updated_at' => $waste->updated_at,
            ],
        ], 201);
    }

    public function updateWastePickup(int $id, Request $request): JsonResponse
    {
        $waste = $request->user()->wastes()->whereKey($id)->first();

        if (!$waste) {
            return response()->json(['message' => 'Limbah tidak ditemukan'], 404);
        }

        $validator = Validator::make($request->all(), [
            'waste_type' => ['nullable', 'string', 'max:100'],
            'weight' => ['nullable', 'numeric', 'min:0.1'],
            'note' => ['nullable', 'string', 'max:1000'],
            'address' => ['nullable', 'string', 'max:500'],
            'image_url' => ['nullable', 'string', 'max:2048'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        $weight = $request->exists('weight') ? (float) $request->input('weight') : (float) $waste->weight;
        $wasteType = trim((string) $request->input('waste_type', $waste->waste_type));
        $pricePerKg = $this->getDefaultPrice($wasteType);
        $totalValue = round($weight * $pricePerKg, 2);
        $imageUrl = $request->exists('image_url') ? trim((string) $request->input('image_url', '')) : $waste->image_url;

        $waste->update([
            'waste_type' => $wasteType,
            'weight' => $weight,
            'note' => $request->exists('note') ? $request->input('note') : $waste->note,
            'image_url' => $imageUrl !== '' ? $imageUrl : null,
            'total_value' => $totalValue,
        ]);

        return response()->json([
            'message' => 'Waste submission updated',
            'data' => [
                'id' => $waste->id,
                'user_id' => $waste->user_id,
                'waste_type' => $waste->waste_type,
                'weight' => (float) $waste->weight,
                'note' => $waste->note,
                'address' => $this->resolvePickupAddress($request->user(), $request->exists('address') ? $request->input('address') : null),
                'status' => $waste->status,
                'image_url' => $waste->image_url,
                'total_value' => (float) $waste->total_value,
                'shipping_cost' => (float) $waste->shipping_cost,
                'farmer_paid_freight' => (bool) $waste->farmer_paid_freight,
                'created_at' => $waste->created_at,
                'updated_at' => $waste->updated_at,
            ],
        ], 200);
    }

    private function getDefaultPrice(string $wasteType): float
    {
        return match (strtolower($wasteType)) {
            'anorganik' => 50,
            default => 20,
        };
    }

    private function resolvePickupAddress(User $user, ?string $requestedAddress = null): string
    {
        if (!blank($requestedAddress)) {
            return trim($requestedAddress);
        }

        $addressRecord = $user->address()->first();
        $resolvedParts = array_filter([
            $addressRecord?->address,
            $addressRecord?->detail_house,
        ], fn ($value) => !blank($value));

        if (!empty($resolvedParts)) {
            return trim(implode(', ', array_map('strval', $resolvedParts)));
        }

        return 'Alamat belum diisi';
    }

    public function wallet(): JsonResponse
    {
        $user = request()->user();
        $pointService = app(PointService::class);
        $pointWallet = $pointService->getOrCreatePointWallet($user);

        return response()->json([
            'message' => 'Wallet balance',
            'data' => [
                'balance' => (int) $pointWallet->balance,
            ],
        ], 200);
    }

    public function walletTransactions(): JsonResponse
    {
        $user = request()->user();
        $pointWallet = PointWallet::firstWhere('user_id', $user?->id);
        $transactions = $pointWallet
            ? $pointWallet->transactions()->latest()->get()
            : collect([]);

        return response()->json([
            'message' => 'Wallet transactions',
            'data' => $transactions->toArray(),
        ], 200);
    }

    public function points(): JsonResponse
    {
        $user = request()->user();
        $pointService = app(PointService::class);
        $pointWallet = $pointService->getOrCreatePointWallet($user);

        return response()->json([
            'message' => 'Point balance',
            'data' => [
                'points' => (int) $pointWallet->balance,
            ],
        ], 200);
    }

    public function deductPoints(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'points' => ['required', 'integer', 'min:1'],
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validasi gagal', 'errors' => $validator->errors()], 422);
        }

        $user = $request->user();
        $points = (int) $request->input('points');
        $reason = $request->input('reason', 'purchase_order');

        $pointService = app(PointService::class);
        $pointWallet = $pointService->getOrCreatePointWallet($user);

        // Deduct points (amount is points value; service stores negative amount)
        $pointService->deductPoints(
            $pointWallet,
            $points,
            'purchase',
            $reason,
            'Order',
            null
        );

        return response()->json(['message' => 'Points deducted', 'data' => ['deducted' => $points]], 200);
    }

    public function pointTransactions(): JsonResponse
    {
        $user = request()->user();
        $pointWallet = PointWallet::firstWhere('user_id', $user?->id);
        $transactions = $pointWallet
            ? $pointWallet->transactions()->latest()->get()
            : collect([]);

        return response()->json([
            'message' => 'Point transactions',
            'data' => $transactions,
        ], 200);
    }

    public function impact(): JsonResponse
    {
        return response()->json(['message' => 'Environmental impact summary'], 200);
    }

    public function vouchers(): JsonResponse
    {
        return response()->json(['message' => 'Vouchers available'], 200);
    }

    public function redeemVoucher(int $id): JsonResponse
    {
        return response()->json(['message' => "Voucher {$id} redeemed"], 200);
    }
}
