<?php

namespace App\Services;

use App\Models\DeliveryTask;
use App\Models\Farmer;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\SharingOrder;
use App\Models\SharingOrderItem;
use App\Models\User;
use App\Notifications\OrderStatusNotification;
use App\Services\PointService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class OrderService
{
    public function calculateShippingData(Product $product, User $user, float $subtotal, ?User $recipient = null): array
    {
        $farmer = $product->farmer;
        $farmerUser = $farmer?->user()->first();
        $farmerAddress = $farmerUser?->address()->first();
        $customerAddress = ($recipient ?? $user)->address()->first();

        $distanceKm = 0.0;
        if ($farmerAddress && $customerAddress && $farmerAddress->latitude !== null && $farmerAddress->longitude !== null && $customerAddress->latitude !== null && $customerAddress->longitude !== null) {
            $distanceKm = $this->calculateDistanceKm(
                (float) $farmerAddress->latitude,
                (float) $farmerAddress->longitude,
                (float) $customerAddress->latitude,
                (float) $customerAddress->longitude,
            );
        }

        $baseFee = 2000.0;
        $distanceFee = round($distanceKm * 2000.0, 2);
        $totalShipping = round($baseFee + $distanceFee, 2);

        $farmerSubsidy = 0.0;
        $customerShipping = $totalShipping;

        if ($distanceKm <= 3.0 && $subtotal >= 30000.0) {
            $customerShipping = $baseFee;
            $farmerSubsidy = $distanceFee;
        } elseif ($distanceKm > 3.0 && $distanceKm <= 5.0 && $subtotal >= 50000.0) {
            $customerShipping = $baseFee;
            $farmerSubsidy = $distanceFee;
        }

        $shippingNote = $distanceKm > 0
            ? "Jarak pengiriman sekitar {$distanceKm} km."
            : 'Biaya pengiriman dihitung otomatis berdasarkan jarak.';

        return [
            'base_fee' => $baseFee,
            'distance_fee' => $distanceFee,
            'total_shipping' => $totalShipping,
            'farmer_subsidy' => round($farmerSubsidy, 2),
            'customer_shipping' => round($customerShipping, 2),
            'shipping_distance_km' => round($distanceKm, 2),
            'shipping_note' => $shippingNote,
        ];
    }

    public function createOrder(User $user, int|array $productIdOrItems, int $quantity = 1): Order
    {
        if (is_array($productIdOrItems)) {
            return $this->createOrderFromItems($user, $productIdOrItems);
        }

        return $this->createOrderFromProduct($user, $productIdOrItems, $quantity);
    }

    public function createSharingOrder(User $user, int|array $productIdOrItems, ?int $receiverId, int $quantity = 1, array $receiverMeta = []): SharingOrder
    {
        if ($receiverId === null) {
            throw new \InvalidArgumentException('Receiver ID wajib untuk pesanan berbagi.');
        }

        if (is_array($productIdOrItems)) {
            return $this->createSharingOrderFromItems($user, $productIdOrItems, $receiverId, $receiverMeta);
        }

        return $this->createSharingOrderFromProduct($user, $productIdOrItems, $receiverId, $quantity, $receiverMeta);
    }

    private function createOrderFromProduct(User $user, int $productId, int $quantity = 1): Order
    {
        if ($quantity < 1) {
            throw new \InvalidArgumentException('Jumlah pesanan harus minimal 1.');
        }

        return DB::transaction(function () use ($user, $productId, $quantity) {
            $product = Product::with('farmer.user')
                ->where('id', $productId)
                ->where('status', 'available')
                ->lockForUpdate()
                ->first();

            if (!$product) {
                throw new ModelNotFoundException('Produk tidak ditemukan atau tidak tersedia.');
            }

            $farmerUser = $product->farmer?->user;
            if (!$farmerUser) {
                throw new ModelNotFoundException('Petani untuk produk tidak ditemukan.');
            }

            if ($product->stock < $quantity) {
                throw new \InvalidArgumentException('Stok produk tidak mencukupi.');
            }

            $totalAmount = round($product->price * $quantity, 2);
            $shippingData = $this->calculateShippingData($product, $user, $totalAmount);
            $finalAmount = round($totalAmount + $shippingData['customer_shipping'], 2);
            $orderData = $this->buildOrderData($user, $farmerUser, $totalAmount, $finalAmount, $shippingData, $product, $quantity);

            $order = Order::create($orderData);

            if (Schema::hasTable('order_items')) {
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'unit_price' => $product->price,
                    'subtotal' => $totalAmount,
                    'product_name' => $product->name,
                    'product_price' => $product->price,
                    'product_image' => $product->image,
                    'product_unit' => $product->unit,
                    'product_description' => $product->description,
                    'product_quantity' => $quantity,
                ]);
            }

            $product->stock -= $quantity;
            if ($product->stock <= 0) {
                $product->stock = 0;
                $product->status = 'sold_out';
            }
            $product->save();

            Notification::send($farmerUser, new OrderStatusNotification(
                title: 'Pesanan masuk',
                body: 'Ada pesanan baru dari warga yang menunggu proses Anda.',
                type: 'activity',
                orderId: (int) $order->id,
            ));

            return $order;
        });
    }

    private function createSharingOrderFromProduct(User $user, int $productId, int $receiverId, int $quantity = 1, array $receiverMeta = []): SharingOrder
    {
        if ($quantity < 1) {
            throw new \InvalidArgumentException('Jumlah pesanan harus minimal 1.');
        }

        return DB::transaction(function () use ($user, $productId, $receiverId, $quantity, $receiverMeta) {
            $product = Product::with('farmer.user')
                ->where('id', $productId)
                ->where('status', 'available')
                ->lockForUpdate()
                ->first();

            if (!$product) {
                throw new ModelNotFoundException('Produk tidak ditemukan atau tidak tersedia.');
            }

            $farmerUser = $product->farmer?->user;
            if (!$farmerUser) {
                throw new ModelNotFoundException('Petani untuk produk tidak ditemukan.');
            }

            if ($product->stock < $quantity) {
                throw new \InvalidArgumentException('Stok produk tidak mencukupi.');
            }

            $receiverUser = User::find($receiverId);
            if (!$receiverUser) {
                throw new ModelNotFoundException('Penerima pesanan berbagi tidak ditemukan.');
            }

            $receiverUser = User::find($receiverId);
            if (!$receiverUser) {
                throw new ModelNotFoundException('Penerima pesanan berbagi tidak ditemukan.');
            }

            $totalAmount = round($product->price * $quantity, 2);
            $shippingData = $this->calculateShippingData($product, $user, $totalAmount, $receiverUser);
            $finalAmount = round($totalAmount + $shippingData['customer_shipping'], 2);
            $orderData = $this->buildSharingOrderData($user, $farmerUser, $receiverId, $totalAmount, $finalAmount, $shippingData, $product, $quantity, $receiverMeta);

            $order = SharingOrder::create($orderData);

            if (Schema::hasTable('sharing_order_items')) {
                SharingOrderItem::create([
                    'sharing_order_id' => $order->id,
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'unit_price' => $product->price,
                    'subtotal' => $totalAmount,
                    'product_name' => $product->name,
                    'product_price' => $product->price,
                    'product_image' => $product->image,
                    'product_unit' => $product->unit,
                    'product_description' => $product->description,
                    'product_quantity' => $quantity,
                ]);
            }

            $product->stock -= $quantity;
            if ($product->stock <= 0) {
                $product->stock = 0;
                $product->status = 'sold_out';
            }
            $product->save();

            return $order;
        });
    }

    private function createSharingOrderFromItems(User $user, array $items, int $receiverId, array $receiverMeta = []): SharingOrder
    {
        if (empty($items)) {
            throw new \InvalidArgumentException('Daftar produk pesanan tidak boleh kosong.');
        }

        $normalizedItems = array_map(function ($item) {
            if (!is_array($item) || !isset($item['product_id']) || !isset($item['quantity'])) {
                throw new \InvalidArgumentException('Setiap item harus berisi product_id dan quantity.');
            }

            $productId = (int) $item['product_id'];
            $quantity = (int) $item['quantity'];

            if ($quantity < 1) {
                throw new \InvalidArgumentException('Jumlah pesanan harus minimal 1 untuk setiap produk.');
            }

            return [
                'product_id' => $productId,
                'quantity' => $quantity,
            ];
        }, $items);

        $productIds = array_unique(array_column($normalizedItems, 'product_id'));
        if (count($productIds) !== count($normalizedItems)) {
            throw new \InvalidArgumentException('Setiap produk hanya boleh dipilih satu kali dalam pesanan.');
        }

        if (count($productIds) > 1 && !Schema::hasTable('sharing_order_items')) {
            throw new \RuntimeException('Pesanan multi-produk memerlukan tabel sharing_order_items.');
        }

        return DB::transaction(function () use ($user, $normalizedItems, $productIds, $receiverId, $receiverMeta) {
            $products = Product::with('farmer.user')
                ->whereIn('id', $productIds)
                ->where('status', 'available')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            if ($products->count() !== count($productIds)) {
                throw new ModelNotFoundException('Beberapa produk tidak ditemukan atau tidak tersedia.');
            }

            $firstProduct = $products[$productIds[0]];
            $farmerUser = $firstProduct->farmer?->user;
            if (!$farmerUser) {
                throw new ModelNotFoundException('Petani untuk produk tidak ditemukan.');
            }

            $receiverUser = User::find($receiverId);
            if (!$receiverUser) {
                throw new ModelNotFoundException('Penerima pesanan berbagi tidak ditemukan.');
            }

            $totalAmount = 0.0;
            foreach ($normalizedItems as $item) {
                $product = $products[$item['product_id']];
                if ($product->farmer?->id !== $firstProduct->farmer?->id) {
                    throw new \InvalidArgumentException('Semua produk dalam satu pesanan harus berasal dari petani yang sama.');
                }

                if ($product->stock < $item['quantity']) {
                    throw new \InvalidArgumentException("Stok produk '{$product->name}' tidak mencukupi.");
                }

                $totalAmount += round($product->price * $item['quantity'], 2);
            }

            $shippingData = $this->calculateShippingData($firstProduct, $user, $totalAmount, $receiverUser);
            $finalAmount = round($totalAmount + $shippingData['customer_shipping'], 2);
            $orderData = $this->buildSharingOrderData(
                $user,
                $farmerUser,
                $receiverId,
                $totalAmount,
                $finalAmount,
                $shippingData,
                null,
                null,
                $receiverMeta
            );

            $order = SharingOrder::create($orderData);

            if (Schema::hasTable('sharing_order_items')) {
                foreach ($normalizedItems as $item) {
                    $product = $products[$item['product_id']];
                    SharingOrderItem::create([
                        'sharing_order_id' => $order->id,
                        'product_id' => $product->id,
                        'quantity' => $item['quantity'],
                        'unit_price' => $product->price,
                        'subtotal' => round($product->price * $item['quantity'], 2),
                        'product_name' => $product->name,
                        'product_price' => $product->price,
                        'product_image' => $product->image,
                        'product_unit' => $product->unit,
                        'product_description' => $product->description,
                        'product_quantity' => $item['quantity'],
                    ]);
                }
            }

            foreach ($normalizedItems as $item) {
                $product = $products[$item['product_id']];
                $product->stock -= $item['quantity'];
                if ($product->stock <= 0) {
                    $product->stock = 0;
                    $product->status = 'sold_out';
                }
                $product->save();
            }

            Notification::send($farmerUser, new OrderStatusNotification(
                title: 'Pesanan masuk',
                body: 'Ada pesanan baru dari warga yang menunggu proses Anda.',
                type: 'activity',
                orderId: (int) $order->id,
            ));

            return $order;
        });
    }

    private function createOrderFromItems(User $user, array $items): Order
    {
        if (empty($items)) {
            throw new \InvalidArgumentException('Daftar produk pesanan tidak boleh kosong.');
        }

        $normalizedItems = array_map(function ($item) {
            if (!is_array($item) || !isset($item['product_id']) || !isset($item['quantity'])) {
                throw new \InvalidArgumentException('Setiap item harus berisi product_id dan quantity.');
            }

            $productId = (int) $item['product_id'];
            $quantity = (int) $item['quantity'];

            if ($quantity < 1) {
                throw new \InvalidArgumentException('Jumlah pesanan harus minimal 1 untuk setiap produk.');
            }

            return [
                'product_id' => $productId,
                'quantity' => $quantity,
            ];
        }, $items);

        $productIds = array_unique(array_column($normalizedItems, 'product_id'));
        if (count($productIds) !== count($normalizedItems)) {
            throw new \InvalidArgumentException('Setiap produk hanya boleh dipilih satu kali dalam pesanan.');
        }

        if (count($productIds) > 1 && !Schema::hasTable('order_items')) {
            throw new \RuntimeException('Pesanan multi-produk memerlukan tabel order_items.');
        }

        return DB::transaction(function () use ($user, $normalizedItems, $productIds) {
            $products = Product::with('farmer.user')
                ->whereIn('id', $productIds)
                ->where('status', 'available')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            if ($products->count() !== count($productIds)) {
                throw new ModelNotFoundException('Beberapa produk tidak ditemukan atau tidak tersedia.');
            }

            $firstProduct = $products[$productIds[0]];
            $farmerUser = $firstProduct->farmer?->user;
            if (!$farmerUser) {
                throw new ModelNotFoundException('Petani untuk produk tidak ditemukan.');
            }

            $totalAmount = 0.0;
            $totalQuantity = 0;
            foreach ($normalizedItems as $item) {
                $product = $products[$item['product_id']];
                if ($product->farmer?->id !== $firstProduct->farmer?->id) {
                    throw new \InvalidArgumentException('Semua produk dalam satu pesanan harus berasal dari petani yang sama.');
                }

                if ($product->stock < $item['quantity']) {
                    throw new \InvalidArgumentException("Stok produk '{$product->name}' tidak mencukupi.");
                }

                $totalAmount += round($product->price * $item['quantity'], 2);
                $totalQuantity += $item['quantity'];
            }

            $shippingData = $this->calculateShippingData($firstProduct, $user, $totalAmount);
            $finalAmount = round($totalAmount + $shippingData['customer_shipping'], 2);
            $orderData = $this->buildOrderData(
                $user,
                $farmerUser,
                $totalAmount,
                $finalAmount,
                $shippingData,
                count($normalizedItems) === 1 ? $firstProduct : null,
                $totalQuantity,
            );

            $order = Order::create($orderData);

            if (Schema::hasTable('order_items')) {
                foreach ($normalizedItems as $item) {
                    $product = $products[$item['product_id']];
                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $product->id,
                        'quantity' => $item['quantity'],
                        'unit_price' => $product->price,
                        'subtotal' => round($product->price * $item['quantity'], 2),
                        'product_name' => $product->name,
                        'product_price' => $product->price,
                        'product_image' => $product->image,
                        'product_unit' => $product->unit,
                        'product_description' => $product->description,
                        'product_quantity' => $item['quantity'],
                    ]);
                }
            }

            foreach ($normalizedItems as $item) {
                $product = $products[$item['product_id']];
                $product->stock -= $item['quantity'];
                if ($product->stock <= 0) {
                    $product->stock = 0;
                    $product->status = 'sold_out';
                }
                $product->save();
            }

            return $order;
        });
    }

    private function buildOrderData(User $user, User $farmerUser, float $totalAmount, float $finalAmount, array $shippingData, ?Product $product = null, ?int $quantity = null): array
    {
        $orderData = [
            'inhabitans_id' => $user->id,
            'farmers_id' => $farmerUser->id,
        ];

        if (Schema::hasColumn('orders', 'delivery_id')) {
            $orderData['delivery_id'] = null;
        }

        if (Schema::hasColumn('orders', 'group_buying_id')) {
            $orderData['group_buying_id'] = null;
        }

        if (Schema::hasColumn('orders', 'total_amount')) {
            $orderData['total_amount'] = $totalAmount;
        }

        if (Schema::hasColumn('orders', 'discount_amount')) {
            $orderData['discount_amount'] = 0;
        }

        if (Schema::hasColumn('orders', 'final_amount')) {
            $orderData['final_amount'] = $finalAmount;
        }

        if (Schema::hasColumn('orders', 'status')) {
            $orderData['status'] = 'pending';
        }

        if (Schema::hasColumn('orders', 'payment_status')) {
            $orderData['payment_status'] = 'paid';
        }

        if (Schema::hasColumn('orders', 'delivery_status')) {
            $orderData['delivery_status'] = 'pending';
        }

        if (Schema::hasColumn('orders', 'base_fee')) {
            $orderData['base_fee'] = $shippingData['base_fee'];
        }
        if (Schema::hasColumn('orders', 'distance_fee')) {
            $orderData['distance_fee'] = $shippingData['distance_fee'];
        }
        if (Schema::hasColumn('orders', 'total_shipping')) {
            $orderData['total_shipping'] = $shippingData['total_shipping'];
        }
        if (Schema::hasColumn('orders', 'farmer_subsidy')) {
            $orderData['farmer_subsidy'] = $shippingData['farmer_subsidy'];
        }
        if (Schema::hasColumn('orders', 'customer_shipping')) {
            $orderData['customer_shipping'] = $shippingData['customer_shipping'];
        }
        if (Schema::hasColumn('orders', 'shipping_distance_km')) {
            $orderData['shipping_distance_km'] = $shippingData['shipping_distance_km'];
        }
        if (Schema::hasColumn('orders', 'shipping_note')) {
            $orderData['shipping_note'] = $shippingData['shipping_note'];
        }

        if (Schema::hasColumn('orders', 'product_quantity') && $quantity !== null) {
            $orderData['product_quantity'] = $quantity;
        }

        if ($product !== null) {
            if (Schema::hasColumn('orders', 'product_id')) {
                $orderData['product_id'] = $product->id;
            }
            if (Schema::hasColumn('orders', 'product_name')) {
                $orderData['product_name'] = $product->name;
            }
            if (Schema::hasColumn('orders', 'product_price')) {
                $orderData['product_price'] = $product->price;
            }
            if (Schema::hasColumn('orders', 'product_image')) {
                $orderData['product_image'] = $product->image;
            }
            if (Schema::hasColumn('orders', 'product_unit')) {
                $orderData['product_unit'] = $product->unit;
            }
            if (Schema::hasColumn('orders', 'product_description')) {
                $orderData['product_description'] = $product->description;
            }
        }

        return $orderData;
    }

    private function buildSharingOrderData(User $user, User $farmerUser, int $receiverId, float $totalAmount, float $finalAmount, array $shippingData, ?Product $product = null, ?int $quantity = null, array $receiverMeta = []): array
    {
        $orderData = [
            'inhabitans_id' => $user->id,
            'farmers_id' => $farmerUser->id,
            'receiver_id' => $receiverId,
            'receiver_name' => $receiverMeta['receiver_name'] ?? '',
            'receiver_phone' => $receiverMeta['receiver_phone'] ?? '',
            'receiver_address' => $receiverMeta['receiver_address'] ?? '',
            'receiver_detail_house' => $receiverMeta['receiver_detail_house'] ?? '',
        ];

        $orderData['delivery_id'] = null;
        $orderData['group_buying_id'] = null;
        $orderData['total_amount'] = $totalAmount;
        $orderData['discount_amount'] = 0;
        $orderData['final_amount'] = $finalAmount;
        $orderData['status'] = 'pending';
        $orderData['payment_status'] = 'paid';
        $orderData['delivery_status'] = 'pending';
        $orderData['base_fee'] = $shippingData['base_fee'];
        $orderData['distance_fee'] = $shippingData['distance_fee'];
        $orderData['total_shipping'] = $shippingData['total_shipping'];
        $orderData['farmer_subsidy'] = $shippingData['farmer_subsidy'];
        $orderData['customer_shipping'] = $shippingData['customer_shipping'];
        $orderData['shipping_distance_km'] = $shippingData['shipping_distance_km'];
        $orderData['shipping_note'] = $shippingData['shipping_note'];

        if ($product !== null) {
            $orderData['product_id'] = $product->id;
            $orderData['product_name'] = $product->name;
            $orderData['product_price'] = $product->price;
            $orderData['product_image'] = $product->image;
            $orderData['product_unit'] = $product->unit;
            $orderData['product_quantity'] = $quantity;
            $orderData['product_description'] = $product->description;
        }

        return $orderData;
    }

    public function processFarmerOrder(Farmer $farmer, Order|SharingOrder $order): DeliveryTask
    {
        if ($order instanceof SharingOrder) {
            $order->loadMissing(['product', 'items.product', 'user.address', 'receiver']);
        } else {
            $order->loadMissing(['product', 'items.product', 'user.address']);
        }

        if (!$order->product && $order->items->isEmpty()) {
            throw new \InvalidArgumentException('Pesanan belum memiliki produk yang dapat diproses.');
        }

        $containsFarmerProduct = false;
        if ($order->product) {
            $containsFarmerProduct = $order->product->farmer_id === $farmer->id;
        } else {
            $containsFarmerProduct = $order->items->contains(function ($item) use ($farmer) {
                return $item->product && $item->product->farmer_id === $farmer->id;
            });
        }

        if (!$containsFarmerProduct) {
            throw new \InvalidArgumentException('Pesanan tidak terkait dengan petani ini.');
        }

        if (!in_array($order->status, ['pending', 'confirmed'], true)) {
            throw new \InvalidArgumentException('Pesanan tidak dapat diproses.');
        }

        $farmerUser = $farmer->user()->first();
        $pickupAddress = $this->resolveUserAddress($farmerUser ?? $farmer->user);
        $pickupLatitude = $farmerUser?->address?->latitude;
        $pickupLongitude = $farmerUser?->address?->longitude;

        if ($order instanceof SharingOrder && $order->receiver) {
            $destinationAddress = $this->resolveUserAddress($order->receiver);
            $destinationLatitude = $order->receiver->address?->latitude;
            $destinationLongitude = $order->receiver->address?->longitude;
        } else {
            $destinationAddress = $this->resolveUserAddress($order->user);
            $destinationLatitude = $order->user->address?->latitude;
            $destinationLongitude = $order->user->address?->longitude;
        }

        $deliveryPerson = $this->findNearestDeliveryPerson($pickupLatitude, $pickupLongitude, $destinationLatitude, $destinationLongitude);

        if (!$deliveryPerson) {
            $message = $this->hasAnyDeliveryPerson()
                ? 'Semua pengantar sedang dalam tugas. Tunggu beberapa saat.'
                : 'Tidak ada pengantar tersedia saat ini. Silakan coba lagi.';
            throw new \InvalidArgumentException($message);
        }

        $status = 'assigned';

        // Build delivery task data defensively to handle different DB schemas
        $taskData = [
            'delivery_person_id' => $deliveryPerson?->id,
            'type' => 'agricultural_delivery',
            'order_id' => $order instanceof Order ? $order->id : null,
            'sharing_order_id' => $order instanceof SharingOrder ? $order->id : null,
            'pickup_address' => $pickupAddress,
            'pickup_latitude' => $pickupLatitude,
            'pickup_longitude' => $pickupLongitude,
            'destination_address' => $destinationAddress,
            'destination_latitude' => $destinationLatitude,
            'destination_longitude' => $destinationLongitude,
            'scheduled_at' => now(),
            'completed_at' => null,
            'status' => $status,
        ];

        // Only include waste-specific columns when they exist and this is a waste pickup task
        if (Schema::hasColumn('delivery_tasks', 'waste_pickup_id') && $order->waste_pickup_id ?? false) {
            $taskData['waste_pickup_id'] = $order->waste_pickup_id;
        }

        if (Schema::hasColumn('delivery_tasks', 'compost_order_id') && $order->compost_order_id ?? false) {
            $taskData['compost_order_id'] = $order->compost_order_id;
        }

        $task = DeliveryTask::create($taskData);

        $order->update([
            'status' => 'confirmed',
            'delivery_status' => $deliveryPerson ? 'shipped' : 'pending',
            'delivery_id' => $deliveryPerson?->id,
        ]);

        $customer = $order->user()->first();
        $farmerUser = $farmer->user()->first();
        if ($customer) {
            Notification::send($customer, new OrderStatusNotification(
                title: 'Pesanan diproses',
                body: 'Pesanan Anda sedang diproses oleh petani.',
                type: 'activity',
                orderId: (int) $order->id,
            ));
        }

        if ($farmerUser) {
            Notification::send($farmerUser, new OrderStatusNotification(
                title: 'Pesanan masuk',
                body: 'Ada pesanan baru masuk dari warga yang perlu Anda proses.',
                type: 'activity',
                orderId: (int) $order->id,
            ));
        }

        if ($deliveryPerson) {
            Notification::send($deliveryPerson, new OrderStatusNotification(
                title: 'Tugas antar masuk',
                body: 'Anda mendapat tugas pengiriman untuk pesanan ini.',
                type: 'activity',
                orderId: (int) $order->id,
            ));
        }

        return $task;
    }

    public function cancelFarmerOrder(Farmer $farmer, Order|SharingOrder $order): Order|SharingOrder
    {
        $order->loadMissing(['product', 'items.product']);
        if (Schema::hasTable('delivery_tasks')) {
            $order->loadMissing(['deliveryTask']);
        }

        if ($order->status === 'cancelled' || $order->delivery_status === 'cancelled') {
            throw new \InvalidArgumentException('Pesanan sudah dibatalkan.');
        }

        if (in_array($order->delivery_status, ['shipped', 'delivered'], true)) {
            throw new \InvalidArgumentException('Pesanan sudah dikirim dan tidak dapat dibatalkan.');
        }

        $farmerUser = $farmer->user()->first();
        if (!$farmerUser) {
            throw new \InvalidArgumentException('Petani tidak ditemukan.');
        }

        $containsFarmerProduct = false;
        if ($order->farmers_id !== null) {
            $containsFarmerProduct = $order->farmers_id === $farmerUser->id;
        } elseif (Schema::hasTable('order_items')) {
            $order->loadMissing(['items.product']);
            $containsFarmerProduct = $order->items->contains(function ($item) use ($farmer) {
                return $item->product && $item->product->farmer_id === $farmer->id;
            });
        }

        if (!$containsFarmerProduct) {
            throw new \InvalidArgumentException('Pesanan tidak terkait dengan petani ini.');
        }

        return DB::transaction(function () use ($farmer, $order, $farmerUser) {
            $pointService = app(PointService::class);

            if (Schema::hasTable('delivery_tasks') && $order->deliveryTask) {
                $order->deliveryTask->update(['status' => 'cancelled']);
            }

            $itemRecords = $order->items;
            if ($itemRecords && $itemRecords->isNotEmpty()) {
                foreach ($itemRecords as $item) {
                    $product = $item->product;
                    if (!$product) {
                        continue;
                    }

                    $returnedQuantity = (int) ($item->product_quantity ?? $item->quantity ?? 0);
                    if ($returnedQuantity <= 0) {
                        continue;
                    }

                    $product->stock = (int) $product->stock + $returnedQuantity;
                    if ($product->stock < 0) {
                        $product->stock = 0;
                    }
                    if ($product->stock > 0) {
                        $product->status = 'available';
                    }
                    $product->save();
                }
            } elseif ($order->product) {
                $returnedQuantity = (int) ($order->product_quantity ?? 1);
                if ($returnedQuantity > 0) {
                    $product = $order->product;
                    $product->stock = (int) $product->stock + $returnedQuantity;
                    if ($product->stock < 0) {
                        $product->stock = 0;
                    }
                    if ($product->stock > 0) {
                        $product->status = 'available';
                    }
                    $product->save();
                }
            }

            $order->update([
                'status' => 'cancelled',
                'delivery_status' => 'cancelled',
            ]);

            $customer = $order->user()->first();
            if ($customer) {
                Notification::send($customer, new OrderStatusNotification(
                    title: 'Pesanan dibatalkan',
                    body: 'Pesanan Anda dibatalkan oleh petani.',
                    type: 'warning',
                    orderId: (int) $order->id,
                ));
            }

            Notification::send($farmerUser, new OrderStatusNotification(
                title: 'Pesanan dibatalkan',
                body: 'Anda telah membatalkan pesanan yang masuk.',
                type: 'warning',
                orderId: (int) $order->id,
            ));

            if (Schema::hasColumn('orders', 'discount_amount') && $order->discount_amount > 0) {
                if ($customer) {
                    $usedPoints = (int) floor((float) $order->discount_amount / 10);
                    if ($usedPoints > 0) {
                        $pointWallet = $pointService->getOrCreatePointWallet($customer);
                        $pointService->addPoints(
                            $pointWallet,
                            $usedPoints,
                            'refund',
                            'Refund poin karena pesanan dibatalkan',
                            'Order',
                            $order->id,
                        );
                    }
                }
            }

            return $order->fresh();
        });
    }

    private function calculateDistanceKm(float $latitudeFrom, float $longitudeFrom, float $latitudeTo, float $longitudeTo): float
    {
        $earthRadiusKm = 6371;
        $latFrom = deg2rad($latitudeFrom);
        $lonFrom = deg2rad($longitudeFrom);
        $latTo = deg2rad($latitudeTo);
        $lonTo = deg2rad($longitudeTo);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $a = sin($latDelta / 2) * sin($latDelta / 2)
            + cos($latFrom) * cos($latTo) * sin($lonDelta / 2) * sin($lonDelta / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return round($earthRadiusKm * $c, 2);
    }

    private function resolveUserAddress(?User $user): string
    {
        if (!$user) {
            return 'Alamat tidak tersedia';
        }

        $addressRecord = $user->address()->first();
        if ($addressRecord && !blank($addressRecord->address)) {
            $parts = array_filter([
                $addressRecord->address,
                $addressRecord->detail_house,
            ], fn ($value) => !blank($value));
            return implode(', ', $parts);
        }

        return 'Alamat pelanggan tidak tersedia';
    }

    private function findNearestDeliveryPerson(?float $pickupLatitude, ?float $pickupLongitude, ?float $destinationLatitude, ?float $destinationLongitude): ?User
    {
        $candidates = [];

        if ($pickupLatitude !== null && $pickupLongitude !== null) {
            $candidates[] = $this->queryNearestDeliveryPerson($pickupLatitude, $pickupLongitude);
        }

        if ($destinationLatitude !== null && $destinationLongitude !== null) {
            $candidates[] = $this->queryNearestDeliveryPerson($destinationLatitude, $destinationLongitude);
        }

        $candidates = array_filter($candidates);

        if (!empty($candidates)) {
            usort($candidates, fn ($a, $b) => $a->distance <=> $b->distance);
            return $candidates[0];
        }

        return $this->queryAnyDeliveryPerson();
    }

    private function queryNearestDeliveryPerson(float $latitude, float $longitude): ?User
    {
        $haversine = "(
            6371 * acos(
                cos(radians(?)) * cos(radians(user_addresses.latitude)) * cos(radians(user_addresses.longitude) - radians(?))
                + sin(radians(?)) * sin(radians(user_addresses.latitude))
            )
        ) as distance";

        return User::query()
            ->selectRaw("users.*, {$haversine}", [$latitude, $longitude, $latitude])
            ->join('user_addresses', 'users.id', '=', 'user_addresses.user_id')
            ->where('users.role', 'pengantar')
            ->whereNotNull('user_addresses.latitude')
            ->whereNotNull('user_addresses.longitude')
            ->whereDoesntHave('deliveryTasks', fn ($query) => $query->whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit']))
            ->orderBy('distance', 'asc')
            ->first();
    }

    private function queryAnyDeliveryPerson(): ?User
    {
        return User::query()
            ->join('user_addresses', 'users.id', '=', 'user_addresses.user_id')
            ->where('users.role', 'pengantar')
            ->whereNotNull('user_addresses.latitude')
            ->whereNotNull('user_addresses.longitude')
            ->whereDoesntHave('deliveryTasks', fn ($query) => $query->whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit']))
            ->select('users.*')
            ->first();
    }

    private function hasAnyDeliveryPerson(): bool
    {
        return User::query()
            ->where('role', 'pengantar')
            ->exists();
    }
}