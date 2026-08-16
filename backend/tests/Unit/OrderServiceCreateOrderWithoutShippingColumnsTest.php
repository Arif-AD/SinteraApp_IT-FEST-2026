<?php

namespace Tests\Unit;

use App\Models\Farmer;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use App\Services\OrderService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class OrderServiceCreateOrderWithoutShippingColumnsTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.database' => ':memory:',
        ]);
        app('db')->purge('sqlite');

        $this->dropTableCascade('order_items');
        $this->dropTableCascade('delivery_tasks');
        $this->dropTableCascade('group_buyings');
        $this->dropTableCascade('orders');
        $this->dropTableCascade('products');
        $this->dropTableCascade('user_addresses');
        $this->dropTableCascade('farmers');
        $this->dropTableCascade('users');

        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->unique();
            $table->string('role')->default('warga');
            $table->string('password')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('farmers', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained('users');
            $table->string('farm_name')->nullable();
            $table->string('farm_address')->nullable();
            $table->string('verification_status')->default('pending');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('user_addresses', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained('users');
            $table->string('address')->nullable();
            $table->string('detail_house')->nullable();
            $table->double('latitude')->nullable();
            $table->double('longitude')->nullable();
            $table->timestamps();
        });

        Schema::create('products', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('farmer_id')->constrained('farmers');
            $table->string('name');
            $table->string('category')->nullable();
            $table->string('description')->nullable();
            $table->decimal('price', 12, 2)->default(0);
            $table->string('unit')->nullable();
            $table->integer('stock')->default(0);
            $table->string('status')->default('available');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('orders', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('inhabitans_id')->constrained('users');
            $table->foreignId('farmers_id')->constrained('users');
            $table->foreignId('delivery_id')->nullable()->constrained('users');
            $table->foreignId('group_buying_id')->nullable();
            $table->decimal('total_amount', 12, 2);
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('final_amount', 12, 2);
            $table->string('status')->default('pending');
            $table->string('payment_status')->default('paid');
            $table->string('delivery_status')->default('pending');
            $table->integer('product_quantity')->default(1);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('order_items', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('order_id')->constrained('orders');
            $table->foreignId('product_id')->constrained('products');
            $table->integer('quantity')->default(1);
            $table->decimal('unit_price', 12, 2);
            $table->decimal('subtotal', 12, 2);
            $table->string('product_name')->nullable();
            $table->decimal('product_price', 12, 2)->nullable();
            $table->string('product_image')->nullable();
            $table->string('product_unit')->nullable();
            $table->text('product_description')->nullable();
            $table->integer('product_quantity')->default(1);
            $table->timestamps();
        });
    }

    protected function tearDown(): void
    {
        $this->dropTableCascade('order_items');
        $this->dropTableCascade('delivery_tasks');
        $this->dropTableCascade('group_buyings');
        $this->dropTableCascade('orders');
        $this->dropTableCascade('products');
        $this->dropTableCascade('user_addresses');
        $this->dropTableCascade('farmers');
        $this->dropTableCascade('users');

        parent::tearDown();
    }

    private function dropTableCascade(string $tableName): void
    {
        DB::statement("DROP TABLE IF EXISTS \"{$tableName}\"");
    }

    public function test_create_order_succeeds_when_shipping_columns_are_missing(): void
    {
        $service = new OrderService();

        $farmerUser = User::create(['name' => 'Petani', 'email' => 'petani@example.com', 'role' => 'petani']);
        $farmerUser->farmer()->create(['farm_name' => 'Kebun', 'verification_status' => 'verified']);
        $farmerUser->address()->create([
            'address' => 'Bandung',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
        ]);

        $customerUser = User::create(['name' => 'Warga', 'email' => 'warga@example.com', 'role' => 'warga']);
        $customerUser->address()->create([
            'address' => 'Jakarta',
            'latitude' => -6.2000,
            'longitude' => 106.8166,
        ]);

        $farmer = Farmer::where('user_id', $farmerUser->id)->first();
        $product = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Tomat',
            'category' => 'sayur',
            'price' => 20000,
            'unit' => 'kg',
            'stock' => 10,
            'status' => 'available',
        ]);

        $order = $service->createOrder($customerUser, $product->id, 1);

        $this->assertInstanceOf(Order::class, $order);
        $this->assertSame(1, Order::count());
        $this->assertSame(1, OrderItem::count());
        $this->assertSame('pending', $order->status);
        $this->assertSame(20000.0, (float) $order->total_amount);
    }

    public function test_create_order_from_multiple_items_creates_single_order_with_order_items(): void
    {
        $service = new OrderService();

        $farmerUser = User::create(['name' => 'Petani', 'email' => 'petanidua@example.com', 'role' => 'petani']);
        $farmerUser->farmer()->create(['farm_name' => 'Kebun Dua', 'verification_status' => 'verified']);
        $farmerUser->address()->create([
            'address' => 'Bandung',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
        ]);

        $customerUser = User::create(['name' => 'Warga', 'email' => 'wargadua@example.com', 'role' => 'warga']);
        $customerUser->address()->create([
            'address' => 'Jakarta',
            'latitude' => -6.2000,
            'longitude' => 106.8166,
        ]);

        $farmer = Farmer::where('user_id', $farmerUser->id)->first();
        $productA = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Tomat',
            'category' => 'sayur',
            'price' => 20000,
            'unit' => 'kg',
            'stock' => 10,
            'status' => 'available',
        ]);
        $productB = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Cabai',
            'category' => 'sayur',
            'price' => 10000,
            'unit' => 'kg',
            'stock' => 5,
            'status' => 'available',
        ]);

        $order = $service->createOrder($customerUser, [
            ['product_id' => $productA->id, 'quantity' => 2],
            ['product_id' => $productB->id, 'quantity' => 1],
        ]);

        $this->assertInstanceOf(Order::class, $order);
        $this->assertSame(1, Order::count());
        $this->assertSame(2, OrderItem::count());
        $this->assertSame(50000.0, (float) $order->total_amount);
        $this->assertSame(3, (int) $order->product_quantity);

        $this->assertDatabaseHas('order_items', [
            'order_id' => $order->id,
            'product_id' => $productA->id,
            'quantity' => 2,
            'unit_price' => 20000.00,
            'subtotal' => 40000.00,
        ]);
        $this->assertDatabaseHas('order_items', [
            'order_id' => $order->id,
            'product_id' => $productB->id,
            'quantity' => 1,
            'unit_price' => 10000.00,
            'subtotal' => 10000.00,
        ]);

        $this->assertSame(8, Product::find($productA->id)->stock);
        $this->assertSame(4, Product::find($productB->id)->stock);
    }

    public function test_cancel_order_restores_stock_for_each_order_item(): void
    {
        $service = new OrderService();

        $farmerUser = User::create(['name' => 'Petani', 'email' => 'petani-cancel@example.com', 'role' => 'petani']);
        $farmerUser->farmer()->create(['farm_name' => 'Kebun Cancel', 'verification_status' => 'verified']);
        $farmerUser->address()->create([
            'address' => 'Bandung',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
        ]);

        $customerUser = User::create(['name' => 'Warga', 'email' => 'warga-cancel@example.com', 'role' => 'warga']);
        $customerUser->address()->create([
            'address' => 'Jakarta',
            'latitude' => -6.2000,
            'longitude' => 106.8166,
        ]);

        $farmer = Farmer::where('user_id', $farmerUser->id)->first();
        $productA = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Tomat',
            'category' => 'sayur',
            'price' => 20000,
            'unit' => 'kg',
            'stock' => 10,
            'status' => 'available',
        ]);
        $productB = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Cabai',
            'category' => 'sayur',
            'price' => 10000,
            'unit' => 'kg',
            'stock' => 5,
            'status' => 'available',
        ]);

        $order = $service->createOrder($customerUser, [
            ['product_id' => $productA->id, 'quantity' => 2],
            ['product_id' => $productB->id, 'quantity' => 1],
        ]);

        $service->cancelFarmerOrder($farmer, $order);

        $this->assertSame('cancelled', $order->fresh()->status);
        $this->assertSame(10, Product::find($productA->id)->stock);
        $this->assertSame(5, Product::find($productB->id)->stock);
        $this->assertSame('available', Product::find($productA->id)->status);
        $this->assertSame('available', Product::find($productB->id)->status);
    }
}
