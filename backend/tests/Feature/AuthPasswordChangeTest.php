<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthPasswordChangeTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_change_password_with_valid_current_password(): void
    {
        $user = User::create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'phone' => '08123456789',
            'role' => 'warga',
            'password' => Hash::make('old-password-123'),
            'is_verified' => false,
        ]);

        $this->actingAs($user, 'sanctum');

        $response = $this->postJson('/api/v1/me/password', [
            'current_password' => 'old-password-123',
            'new_password' => 'new-password-456',
            'new_password_confirmation' => 'new-password-456',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Password updated successfully');

        $this->assertTrue(Hash::check('new-password-456', $user->fresh()->password));
    }
}
