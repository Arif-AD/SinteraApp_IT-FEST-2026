<?php

namespace Tests\Unit;

use App\Models\Farmer;
use App\Models\Product;
use App\Models\User;
use App\Services\OrderService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class OrderServiceShippingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->unique();
            $table->string('role')->default('warga');
            $table->string('password')->nullable();
            $table->timestamps();
        });

        Schema::create('farmers', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained('users');
            $table->string('farm_name')->nullable();
            $table->string('farm_address')->nullable();
            $table->string('verification_status')->default('pending');
            $table->timestamps();
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
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('products');
        Schema::dropIfExists('user_addresses');
        Schema::dropIfExists('farmers');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_warga_only_pays_base_fee_when_distance_is_small_and_subtotal_is_high_enough(): void
    {
        $service = new OrderService();

        $farmerUser = User::factory()->create(['role' => 'petani']);
        $farmerUser->farmer()->create(['farm_name' => 'Kebun', 'verification_status' => 'verified']);
        $farmerUser->address()->create([
            'address' => 'Bandung',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
        ]);

        $customerUser = User::factory()->create(['role' => 'warga']);
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
            'price' => 40000,
            'unit' => 'kg',
            'stock' => 10,
            'status' => 'available',
        ]);

        $shippingData = $service->calculateShippingData($product->fresh(), $customerUser, 40000.0);

        $this->assertSame(2000.0, $shippingData['base_fee']);
        $this->assertSame(4000.0, $shippingData['distance_fee']);
        $this->assertSame(6000.0, $shippingData['total_shipping']);
        $this->assertSame(4000.0, $shippingData['farmer_subsidy']);
        $this->assertSame(2000.0, $shippingData['customer_shipping']);
    }

    public function test_warga_pays_full_shipping_when_subtotal_is_below_threshold_for_small_distance(): void
    {
        $service = new OrderService();

        $farmerUser = User::factory()->create(['role' => 'petani']);
        $farmerUser->farmer()->create(['farm_name' => 'Kebun', 'verification_status' => 'verified']);
        $farmerUser->address()->create([
            'address' => 'Bandung',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
        ]);

        $customerUser = User::factory()->create(['role' => 'warga']);
        $customerUser->address()->create([
            'address' => 'Jakarta',
            'latitude' => -6.2000,
            'longitude' => 106.8166,
        ]);

        $farmer = Farmer::where('user_id', $farmerUser->id)->first();
        $product = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Kentang',
            'category' => 'sayur',
            'price' => 10000,
            'unit' => 'kg',
            'stock' => 10,
            'status' => 'available',
        ]);

        $shippingData = $service->calculateShippingData($product->fresh(), $customerUser, 10000.0);

        $this->assertSame(2000.0, $shippingData['base_fee']);
        $this->assertSame(4000.0, $shippingData['distance_fee']);
        $this->assertSame(6000.0, $shippingData['total_shipping']);
        $this->assertSame(0.0, $shippingData['farmer_subsidy']);
        $this->assertSame(6000.0, $shippingData['customer_shipping']);
    }

    public function test_no_subsidy_when_distance_is_more_than_five_km(): void
    {
        $service = new OrderService();

        $farmerUser = User::factory()->create(['role' => 'petani']);
        $farmerUser->farmer()->create(['farm_name' => 'Kebun', 'verification_status' => 'verified']);
        $farmerUser->address()->create([
            'address' => 'Bandung',
            'latitude' => -6.9175,
            'longitude' => 107.6191,
        ]);

        $customerUser = User::factory()->create(['role' => 'warga']);
        $customerUser->address()->create([
            'address' => 'Jakarta',
            'latitude' => -6.2000,
            'longitude' => 106.8166,
        ]);

        $farmer = Farmer::where('user_id', $farmerUser->id)->first();
        $product = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Sawi',
            'category' => 'sayur',
            'price' => 50000,
            'unit' => 'kg',
            'stock' => 10,
            'status' => 'available',
        ]);

        $shippingData = $service->calculateShippingData($product->fresh(), $customerUser, 50000.0);

        $this->assertSame(2000.0, $shippingData['base_fee']);
        $this->assertSame(14000.0, $shippingData['distance_fee']);
        $this->assertSame(16000.0, $shippingData['total_shipping']);
        $this->assertSame(0.0, $shippingData['farmer_subsidy']);
        $this->assertSame(16000.0, $shippingData['customer_shipping']);
    }
}
