<?php

namespace Tests\Feature;

use App\Models\Farmer;
use App\Models\Product;
use App\Models\User;
use Illuminate\Testing\Fluent\AssertableJson;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FarmerProductApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_petani_can_create_product_and_store_it_in_database(): void
    {
        $user = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani@example.com',
            'phone' => '081234567890',
        ]);
        $user->farmer()->create([
            'farm_name' => 'Kebun Cerdas',
            'farm_address' => 'Bandung',
            'verification_status' => 'verified',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/farmer/products', [
                'name' => 'Bayam Segar',
                'category' => 'Sayur',
                'description' => 'Bayam organik segar',
                'price' => 6000,
                'unit' => 'ikat',
                'stock' => 100,
                'status' => 'available',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.name', 'Bayam Segar');

        $this->assertDatabaseHas('products', [
            'name' => 'Bayam Segar',
            'category' => 'sayur',
            'stock' => 100,
        ]);
    }

    public function test_petani_can_update_product_and_persist_changes(): void
    {
        $user = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-update@example.com',
            'phone' => '081234567891',
        ]);
        $farmer = $user->farmer()->create([
            'farm_name' => 'Kebun Update',
            'farm_address' => 'Bandung',
            'verification_status' => 'verified',
        ]);
        $product = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Tomat Segar',
            'category' => 'sayur',
            'description' => 'Tomat lama',
            'price' => 5000,
            'unit' => 'kg',
            'stock' => 20,
            'status' => 'available',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->putJson('/api/v1/farmer/products/' . $product->id, [
                'name' => 'Tomat Premium',
                'price' => 7000,
                'stock' => 35,
                'status' => 'sold_out',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.name', 'Tomat Premium');

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'name' => 'Tomat Premium',
            'price' => 7000,
            'stock' => 35,
            'status' => 'sold_out',
        ]);
    }

    public function test_petani_can_delete_product_soft_deletes_it(): void
    {
        $user = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-delete@example.com',
            'phone' => '081234567892',
        ]);
        $farmer = $user->farmer()->create([
            'farm_name' => 'Kebun Delete',
            'farm_address' => 'Bandung',
            'verification_status' => 'verified',
        ]);
        $product = Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Cabe Merah',
            'category' => 'sayur',
            'description' => 'Cabe merah',
            'price' => 12000,
            'unit' => 'kg',
            'stock' => 10,
            'status' => 'available',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->deleteJson('/api/v1/farmer/products/' . $product->id);

        $response->assertStatus(200);
        $this->assertSoftDeleted('products', ['id' => $product->id]);
    }

    public function test_warga_can_fetch_available_products_from_database(): void
    {
        $farmerUser = User::factory()->create([
            'role' => 'petani',
            'name' => 'Pak Budi',
            'email' => 'budi@example.com',
            'phone' => '081234567890',
        ]);
        $farmer = $farmerUser->farmer()->create([
            'farm_name' => 'Kebun Budi',
            'farm_address' => 'Bandung',
            'verification_status' => 'verified',
        ]);
        Product::create([
            'farmer_id' => $farmer->id,
            'name' => 'Tomat Lokal',
            'category' => 'buah',
            'description' => 'Tomat segar',
            'price' => 9000,
            'unit' => 'kg',
            'stock' => 25,
            'status' => 'available',
        ]);

        $wargaUser = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga@example.com',
            'phone' => '081234567891',
        ]);
        $token = $wargaUser->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/warga/products');

        $response->assertStatus(200)
            ->assertJson(fn (AssertableJson $json) => $json
                ->has('data', 1)
                ->where('data.0.name', 'Tomat Lokal')
                ->where('data.0.category', 'buah')
                ->etc()
            );
    }
}
