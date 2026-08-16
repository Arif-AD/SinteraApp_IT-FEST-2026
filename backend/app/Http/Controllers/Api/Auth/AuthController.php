<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    protected AuthService $authService;

    public function __construct(AuthService $authService)
    {
        $this->authService = $authService;
    }

    /**
     * Get current authenticated user
     */
    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'message' => 'Success',
            'data' => new UserResource($request->user()),
        ], 200);
    }

    /**
     * Logout user
     */
    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return response()->json([
            'message' => 'Logged out successfully',
        ], 200);
    }

    /**
     * Update authenticated user profile
     */
    public function aboutAppStats(Request $request): JsonResponse
    {
        $stats = User::query()
            ->selectRaw('COUNT(*) as total_users')
            ->selectRaw('SUM(CASE WHEN role = ? THEN 1 ELSE 0 END) as warga', ['warga'])
            ->selectRaw('SUM(CASE WHEN role = ? THEN 1 ELSE 0 END) as petani', ['petani'])
            ->selectRaw('SUM(CASE WHEN role = ? THEN 1 ELSE 0 END) as pengantar', ['pengantar'])
            ->first();

        return response()->json([
            'message' => 'Success',
            'data' => [
                'total_users' => (int) ($stats?->total_users ?? 0),
                'warga' => (int) ($stats?->warga ?? 0),
                'petani' => (int) ($stats?->petani ?? 0),
                'pengantar' => (int) ($stats?->pengantar ?? 0),
            ],
        ], 200);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|max:255|unique:users,email,' . $request->user()->id,
            'phone' => 'nullable|string|max:20',
            'profile' => 'nullable|string|max:2048',
            'address' => 'nullable|string|max:500',
            'detail_house' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        $user = $this->authService->updateProfile($request->user(), $validated);

        return response()->json([
            'message' => 'Profile updated successfully',
            'data' => new UserResource($user),
        ], 200);
    }

    /**
     * Change authenticated user password
     */
    public function changePassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
        ]);

        if (!Hash::check($validated['current_password'], $request->user()->password)) {
            return response()->json([
                'message' => 'Current password is incorrect',
            ], 422);
        }

        $request->user()->update([
            'password' => bcrypt($validated['new_password']),
        ]);

        return response()->json([
            'message' => 'Password updated successfully',
        ], 200);
    }
}
