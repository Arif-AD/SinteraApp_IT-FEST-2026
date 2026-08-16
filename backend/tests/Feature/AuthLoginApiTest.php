<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthLoginApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_without_sending_role(): void
    {
        $user = User::factory()->create([
            'name' => 'Warga Test',
            'email' => 'warga-login@example.com',
            'phone' => '081234567890',
            'password' => bcrypt('secret123'),
            'role' => 'warga',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'warga-login@example.com',
            'password' => 'secret123',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.user.role', 'warga');

        $this->assertDatabaseHas('personal_access_tokens', [
            'tokenable_id' => $user->id,
        ]);
    }
}
