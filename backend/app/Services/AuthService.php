<?php

namespace App\Services;

use App\Models\User;
use App\Exceptions\InvalidRoleException;
use Illuminate\Support\Facades\DB;

class AuthService
{
    /**
     * Register a new user
     */
    public function register(array $data): User
    {
        // Validate role
        $validRoles = ['warga', 'petani', 'pengantar'];
        if (!in_array($data['role'], $validRoles)) {
            throw new InvalidRoleException("Role {$data['role']} is not valid");
        }

        return DB::transaction(function () use ($data) {
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'phone' => $data['phone'],
                'password' => bcrypt($data['password']),
                'role' => $data['role'],
                'is_verified' => false,
            ]);

            if (!empty($data['address']) || array_key_exists('detail_house', $data) || array_key_exists('latitude', $data) || array_key_exists('longitude', $data)) {
                $user->address()->create([
                    'address' => $data['address'] ?? null,
                    'detail_house' => $data['detail_house'] ?? null,
                    'latitude' => $data['latitude'] ?? null,
                    'longitude' => $data['longitude'] ?? null,
                ]);
            }

            // Create associated wallets/records
            $user->wallet()->create(['balance' => 0]);
            $user->pointWallet()->create(['balance' => 0]);

            // If petani, create farmer record
            if ($data['role'] === 'petani') {
                $user->farmer()->create([
                    'farm_name' => $data['farm_name'] ?? 'Farm',
                    'farm_address' => $data['farm_address'] ?? $data['address'] ?? '',
                    'farm_description' => $data['farm_description'] ?? null,
                    'verification_status' => 'pending',
                ]);
            }

            return $user;
        });
    }

    /**
     * Authenticate user and create token
     */
    public function login(string $identifier, string $password, ?string $role = null): array
    {
        $user = User::where('email', $identifier)
            ->orWhere('name', $identifier)
            ->first();

        if (!$user || !password_verify($password, $user->password)) {
            throw new \Illuminate\Auth\AuthenticationException('Invalid email or password');
        }

        if ($role !== null && $user->role !== $role) {
            throw new InvalidRoleException('User role does not match');
        }

        $token = $user->createToken('api-token')->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
        ];
    }

    /**
     * Get current user data
     */
    public function getCurrentUser(User $user): array
    {
        $address = $user->address()->first();

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'profile_photo' => $user->profile_photo,
            'address' => $address?->address,
            'detail_house' => $address?->detail_house,
            'latitude' => $address?->latitude,
            'longitude' => $address?->longitude,
            'is_verified' => $user->is_verified,
            'created_at' => $user->created_at,
        ];
    }

    /**
     * Logout user (revoke token)
     */
    public function logout(User $user): void
    {
        $user->tokens()->delete();
    }

    /**
     * Update authenticated user profile
     */
    public function updateProfile(User $user, array $data): User
    {
        $user->update([
            'name' => $data['name'] ?? $user->name,
            'email' => $data['email'] ?? $user->email,
            'phone' => $data['phone'] ?? $user->phone,
            'profile' => array_key_exists('profile', $data) ? $data['profile'] : $user->profile,
        ]);

        if (array_key_exists('address', $data) || array_key_exists('detail_house', $data) || array_key_exists('latitude', $data) || array_key_exists('longitude', $data)) {
            $addressData = $user->address()->firstOrNew([]);
            $addressData->fill([
                'address' => $data['address'] ?? $addressData->address,
                'detail_house' => array_key_exists('detail_house', $data) ? $data['detail_house'] : $addressData->detail_house,
                'latitude' => array_key_exists('latitude', $data) ? $data['latitude'] : $addressData->latitude,
                'longitude' => array_key_exists('longitude', $data) ? $data['longitude'] : $addressData->longitude,
            ]);
            $addressData->user_id = $user->id;
            $addressData->save();
        }

        return $user->fresh();
    }
}
