<?php

namespace Tests\Feature;

use App\Models\DeliveryTask;
use App\Models\User;
use App\Models\WasteOrder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WastePickupApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_warga_can_create_and_list_waste_submissions_with_image(): void
    {
        $user = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-waste@example.com',
            'phone' => '081111111111',
        ]);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/warga/waste', [
                'waste_type' => 'Organik',
                'weight' => 3.5,
                'note' => 'Sisa sayur segar',
                'address' => 'Bandung',
                'image_url' => 'https://example.com/waste.jpg',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.weight', 3.5)
            ->assertJsonPath('data.image_url', 'https://example.com/waste.jpg');

        $this->assertDatabaseHas('wastes', [
            'user_id' => $user->id,
            'status' => 'requested',
            'image_url' => 'https://example.com/waste.jpg',
        ]);

        $listResponse = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/warga/waste');

        $listResponse->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_petani_can_view_and_claim_waste_submissions(): void
    {
        $warga = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-claim@example.com',
            'phone' => '081222222222',
        ]);
        $wargaToken = $warga->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $wargaToken)
            ->postJson('/api/v1/warga/waste', [
                'waste_type' => 'Anorganik',
                'weight' => 2,
                'note' => 'Botol plastik',
                'address' => 'Jakarta',
            ]);

        $petani = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-waste@example.com',
            'phone' => '081333333333',
        ]);
        $petaniToken = $petani->createToken('test-token')->plainTextToken;

        $listResponse = $this->withHeader('Authorization', 'Bearer ' . $petaniToken)
            ->getJson('/api/v1/farmer/waste');

        $listResponse->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $claimResponse = $this->withHeader('Authorization', 'Bearer ' . $petaniToken)
            ->postJson('/api/v1/farmer/waste/1/claim');

        $claimResponse->assertStatus(200)
            ->assertJsonPath('data.status', 'assigned');

        $this->assertDatabaseHas('waste_orders', [
            'waste_id' => 1,
            'farmer_id' => $petani->id,
            'status' => 'claimed',
        ]);

        $this->assertDatabaseHas('delivery_tasks', [
            'type' => 'waste_delivery',
            'waste_id' => 1,
            'status' => 'pending',
        ]);
    }

    public function test_delivery_person_can_list_waste_delivery_tasks(): void
    {
        $warga = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-list@example.com',
            'phone' => '081444444444',
        ]);
        $wargaToken = $warga->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $wargaToken)
            ->postJson('/api/v1/warga/waste', [
                'waste_type' => 'Organik',
                'weight' => 1.5,
                'note' => 'Sisa sayur',
                'address' => 'Yogyakarta',
            ]);

        $petani = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-list@example.com',
            'phone' => '081555555555',
        ]);
        $petaniToken = $petani->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $petaniToken)
            ->postJson('/api/v1/farmer/waste/1/claim');

        $deliveryPerson = User::factory()->create([
            'role' => 'pengantar',
            'email' => 'delivery-list@example.com',
            'phone' => '081666666666',
        ]);
        $deliveryToken = $deliveryPerson->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $deliveryToken)
            ->getJson('/api/v1/delivery-person/tasks');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_delivery_tasks_are_enriched_with_current_warga_and_farmer_addresses(): void
    {
        $warga = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-address@example.com',
            'phone' => '081777777777',
        ]);
        $warga->address()->create([
            'address' => 'Alamat Warga',
            'detail_house' => 'Rumah Warga',
        ]);

        $petani = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-address@example.com',
            'phone' => '081888888888',
        ]);
        $petani->address()->create([
            'address' => 'Alamat Petani',
            'detail_house' => 'Kebun Petani',
        ]);

        $waste = \App\Models\Waste::create([
            'user_id' => $warga->id,
            'waste_type' => 'Organik',
            'weight' => 2.5,
            'note' => 'Sisa sayur',
            'status' => 'assigned',
            'total_value' => 10000,
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        WasteOrder::create([
            'waste_id' => $waste->id,
            'farmer_id' => $petani->id,
            'status' => 'claimed',
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        $task = DeliveryTask::create([
            'type' => 'waste_delivery',
            'waste_id' => $waste->id,
            'delivery_person_id' => null,
            'pickup_address' => 'Alamat lama',
            'destination_address' => 'Alamat lama',
            'scheduled_at' => now(),
            'status' => 'pending',
        ]);

        $deliveryPerson = User::factory()->create([
            'role' => 'pengantar',
            'email' => 'delivery-address@example.com',
            'phone' => '081999999999',
        ]);
        $deliveryToken = $deliveryPerson->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $deliveryToken)
            ->getJson('/api/v1/delivery-person/tasks');

        $response->assertStatus(200)
            ->assertJsonPath('data.0.pickup_address', 'Alamat Warga, Rumah Warga')
            ->assertJsonPath('data.0.destination_address', 'Alamat Petani, Kebun Petani');
    }

    public function test_completing_waste_delivery_task_updates_related_waste_order_delivery_person(): void
    {
        $warga = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-complete@example.com',
            'phone' => '081101010101',
        ]);
        $wargaToken = $warga->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $wargaToken)
            ->postJson('/api/v1/warga/waste', [
                'waste_type' => 'Organik',
                'weight' => 1.2,
                'note' => 'Sisa daun',
                'address' => 'Solo',
            ]);

        $petani = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-complete@example.com',
            'phone' => '081202020202',
        ]);
        $petaniToken = $petani->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $petaniToken)
            ->postJson('/api/v1/farmer/waste/1/claim');

        $deliveryPerson = User::factory()->create([
            'role' => 'pengantar',
            'email' => 'delivery-complete@example.com',
            'phone' => '081303030303',
        ]);
        $deliveryToken = $deliveryPerson->createToken('test-token')->plainTextToken;

        $task = DeliveryTask::query()->where('waste_id', 1)->latest()->first();

        $this->withHeader('Authorization', 'Bearer ' . $deliveryToken)
            ->postJson('/api/v1/delivery-person/tasks/' . $task->id . '/accept');

        $response = $this->withHeader('Authorization', 'Bearer ' . $deliveryToken)
            ->postJson('/api/v1/delivery-person/tasks/' . $task->id . '/complete');

        $response->assertStatus(200);

        $taskFresh = DeliveryTask::query()->find($task->id);
        $this->assertSame($deliveryPerson->id, $taskFresh->delivery_person_id);

        $wasteOrder = \App\Models\WasteOrder::query()->where('waste_id', 1)->latest()->first();
        $this->assertNotNull($wasteOrder);
        $this->assertSame($deliveryPerson->id, $wasteOrder->delivery_person_id);
        $this->assertSame('delivered', $wasteOrder->status);
    }

    public function test_warga_points_endpoint_sums_delivered_waste_total_value(): void
    {
        $warga = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-points@example.com',
            'phone' => '081707070707',
        ]);
        $token = $warga->createToken('test-token')->plainTextToken;

        $wasteA = \App\Models\Waste::create([
            'user_id' => $warga->id,
            'waste_type' => 'Organik',
            'weight' => 1.0,
            'note' => 'Sisa buah',
            'status' => 'assigned',
            'total_value' => 15000,
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        $wasteB = \App\Models\Waste::create([
            'user_id' => $warga->id,
            'waste_type' => 'Anorganik',
            'weight' => 2.0,
            'note' => 'Botol',
            'status' => 'assigned',
            'total_value' => 20000,
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        WasteOrder::create([
            'waste_id' => $wasteA->id,
            'farmer_id' => 1,
            'inhabitans_id' => $warga->id,
            'status' => 'delivered',
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        WasteOrder::create([
            'waste_id' => $wasteB->id,
            'farmer_id' => 1,
            'inhabitans_id' => $warga->id,
            'status' => 'delivered',
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        WasteOrder::create([
            'waste_id' => $wasteB->id,
            'farmer_id' => 1,
            'inhabitans_id' => $warga->id,
            'status' => 'claimed',
            'shipping_cost' => 0,
            'farmer_paid_freight' => true,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/warga/points');

        $response->assertStatus(200)
            ->assertJsonPath('data.points', 35000);
    }

    public function test_delivery_person_can_accept_waste_delivery_task(): void
    {
        $warga = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-accept@example.com',
            'phone' => '081444444444',
        ]);
        $wargaToken = $warga->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $wargaToken)
            ->postJson('/api/v1/warga/waste', [
                'waste_type' => 'Organik',
                'weight' => 1.5,
                'note' => 'Sisa sayur',
                'address' => 'Yogyakarta',
            ]);

        $petani = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-accept@example.com',
            'phone' => '081555555555',
        ]);
        $petaniToken = $petani->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $petaniToken)
            ->postJson('/api/v1/farmer/waste/1/claim');

        $deliveryPerson = User::factory()->create([
            'role' => 'pengantar',
            'email' => 'delivery-accept@example.com',
            'phone' => '081666666666',
        ]);
        $deliveryToken = $deliveryPerson->createToken('test-token')->plainTextToken;

        $task = DeliveryTask::query()->where('waste_id', 1)->latest()->first();

        $response = $this->withHeader('Authorization', 'Bearer ' . $deliveryToken)
            ->postJson('/api/v1/delivery-person/tasks/' . $task->id . '/accept');

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'accepted');

        $this->assertDatabaseHas('delivery_tasks', [
            'id' => $task->id,
            'status' => 'accepted',
        ]);
    }

    public function test_delivery_person_can_accept_assigned_farmer_order_task(): void
    {
        $warga = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-assigned@example.com',
            'phone' => '081777777777',
        ]);
        $wargaToken = $warga->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $wargaToken)
            ->postJson('/api/v1/warga/waste', [
                'waste_type' => 'Organik',
                'weight' => 1.5,
                'note' => 'Sisa sayur',
                'address' => 'Yogyakarta',
            ]);

        $petani = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-assigned@example.com',
            'phone' => '081888888888',
        ]);
        $petaniToken = $petani->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $petaniToken)
            ->postJson('/api/v1/farmer/waste/1/claim');

        $task = DeliveryTask::query()->where('waste_id', 1)->latest()->first();
        $assignedDeliveryPerson = User::factory()->create([
            'role' => 'pengantar',
            'email' => 'assigned-delivery@example.com',
            'phone' => '081999999999',
        ]);
        $task->update(['status' => 'assigned', 'delivery_person_id' => $assignedDeliveryPerson->id]);

        $deliveryToken = $assignedDeliveryPerson->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $deliveryToken)
            ->postJson('/api/v1/delivery-person/tasks/' . $task->id . '/accept');

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'accepted');

        $this->assertDatabaseHas('delivery_tasks', [
            'id' => $task->id,
            'status' => 'accepted',
            'delivery_person_id' => $assignedDeliveryPerson->id,
        ]);
    }

    public function test_delivery_person_cannot_accept_second_active_task_while_first_is_unfinished(): void
    {
        $wargaA = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-first@example.com',
            'phone' => '081701010101',
        ]);
        $wargaAToken = $wargaA->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $wargaAToken)
            ->postJson('/api/v1/warga/waste', [
                'waste_type' => 'Organik',
                'weight' => 1.5,
                'note' => 'Sisa sayur',
                'address' => 'Yogyakarta',
            ]);

        $petaniA = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-first@example.com',
            'phone' => '081702020202',
        ]);
        $petaniAToken = $petaniA->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $petaniAToken)
            ->postJson('/api/v1/farmer/waste/1/claim');

        $wargaB = User::factory()->create([
            'role' => 'warga',
            'email' => 'warga-second@example.com',
            'phone' => '081703030303',
        ]);
        $wargaBToken = $wargaB->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $wargaBToken)
            ->postJson('/api/v1/warga/waste', [
                'waste_type' => 'Anorganik',
                'weight' => 2.0,
                'note' => 'Botol plastik',
                'address' => 'Bandung',
            ]);

        $petaniB = User::factory()->create([
            'role' => 'petani',
            'email' => 'petani-second@example.com',
            'phone' => '081704040404',
        ]);
        $petaniBToken = $petaniB->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer ' . $petaniBToken)
            ->postJson('/api/v1/farmer/waste/2/claim');

        $deliveryPerson = User::factory()->create([
            'role' => 'pengantar',
            'email' => 'delivery-multi@example.com',
            'phone' => '081705050505',
        ]);
        $deliveryToken = $deliveryPerson->createToken('test-token')->plainTextToken;

        $firstTask = DeliveryTask::query()->where('waste_id', 1)->latest()->first();
        $secondTask = DeliveryTask::query()->where('waste_id', 2)->latest()->first();

        $firstAccept = $this->withHeader('Authorization', 'Bearer ' . $deliveryToken)
            ->postJson('/api/v1/delivery-person/tasks/' . $firstTask->id . '/accept');

        $firstAccept->assertStatus(200)
            ->assertJsonPath('data.status', 'accepted');

        $secondAccept = $this->withHeader('Authorization', 'Bearer ' . $deliveryToken)
            ->postJson('/api/v1/delivery-person/tasks/' . $secondTask->id . '/accept');

        $secondAccept->assertStatus(409)
            ->assertJsonPath('message', 'Pengantar sedang dalam tugas. Silakan tunggu tugas saat ini selesai terlebih dahulu.');

        $this->assertDatabaseHas('delivery_tasks', [
            'id' => $firstTask->id,
            'status' => 'accepted',
            'delivery_person_id' => $deliveryPerson->id,
        ]);

        $this->assertDatabaseHas('delivery_tasks', [
            'id' => $secondTask->id,
            'status' => 'pending',
            'delivery_person_id' => null,
        ]);
    }
}
