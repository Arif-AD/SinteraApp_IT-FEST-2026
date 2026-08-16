<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class WargaOrderRatingTest extends TestCase
{
    use RefreshDatabase;

    public function test_warga_can_submit_rating_for_completed_order(): void
    {
        $farmerUser = User::factory()->create([
            'role' => 'petani',
            'email' => 'farmer-rating@example.com',
            'phone' => '081234567899',
        ]);
        $farmerUser->farmer()->create([
            'farm_name' => 'Kebun Rating',
            'farm_address' => 'Malang',
            'verification_status' => 'verified',
        ]);

        $product = Product::create([
            'farmer_id' => $farmerUser->farmer()->first()->id,
            'name' => 'Jeruk Manis',
            'category' => 'buah',
            'description' => 'Jeruk lokal manis',
            'price' => 12000,
            'unit' => 'kg',
            'stock' => 50,
            'status' => 'available',
        ]);

        $wargaUser = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-rating@example.com',
            'phone' => '081234567900',
        ]);
        $token = $wargaUser->createToken('test-token')->plainTextToken;

        $order = Order::create([
            'inhabitans_id' => $wargaUser->id,
            'farmers_id' => $farmerUser->id,
            'total_amount' => 12000,
            'subsidy' => 0,
            'final_amount' => 12000,
            'status' => 'delivered',
            'payment_status' => 'paid',
            'delivery_status' => 'delivered',
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'quantity' => 1,
            'unit_price' => 12000,
            'subtotal' => 12000,
            'product_name' => $product->name,
            'product_price' => $product->price,
            'product_image' => $product->image,
            'product_unit' => $product->unit,
            'product_description' => $product->description,
            'product_quantity' => 1,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/warga/orders/' . $order->id . '/rating', ['rating' => 5]);

        $response->assertStatus(200)
            ->assertJsonPath('data.product_rating', 5);

        $this->assertDatabaseHas('product_ratings', [
            'inhabitans_id' => $wargaUser->id,
            'product_id' => $product->id,
            'order_id' => $order->id,
            'rating' => 5,
        ]);
    }

    public function test_warga_cannot_rate_non_completed_order(): void
    {
        $farmerUser = User::factory()->create([
            'role' => 'petani',
            'email' => 'farmer-rating2@example.com',
            'phone' => '081234567901',
        ]);
        $farmerUser->farmer()->create([
            'farm_name' => 'Kebun Rating 2',
            'farm_address' => 'Malang',
            'verification_status' => 'verified',
        ]);

        $product = Product::create([
            'farmer_id' => $farmerUser->farmer()->first()->id,
            'name' => 'Mangga Manis',
            'category' => 'buah',
            'description' => 'Mangga lokal manis',
            'price' => 15000,
            'unit' => 'kg',
            'stock' => 20,
            'status' => 'available',
        ]);

        $wargaUser = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-rating2@example.com',
            'phone' => '081234567902',
        ]);
        $token = $wargaUser->createToken('test-token')->plainTextToken;

        $order = Order::create([
            'inhabitans_id' => $wargaUser->id,
            'farmers_id' => $farmerUser->id,
            'total_amount' => 15000,
            'subsidy' => 0,
            'final_amount' => 15000,
            'status' => 'pending',
            'payment_status' => 'paid',
            'delivery_status' => 'pending',
        ]);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'quantity' => 1,
            'unit_price' => 15000,
            'subtotal' => 15000,
            'product_name' => $product->name,
            'product_price' => $product->price,
            'product_image' => $product->image,
            'product_unit' => $product->unit,
            'product_description' => $product->description,
            'product_quantity' => 1,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/warga/orders/' . $order->id . '/rating', ['rating' => 4]);

        $response->assertStatus(422)
            ->assertJsonPath('message', 'Rating hanya dapat diberikan pada pesanan yang selesai atau telah terkirim.');

        $this->assertDatabaseMissing('products', [
            'id' => $product->id,
            'rating' => 4.0,
        ]);
    }
}
