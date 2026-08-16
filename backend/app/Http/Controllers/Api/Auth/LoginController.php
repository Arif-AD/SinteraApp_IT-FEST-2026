<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Http\Requests\Auth\LoginRequest;
use App\Exceptions\InvalidRoleException;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;

class LoginController extends Controller
{
    protected AuthService $authService;

    public function __construct(AuthService $authService)
    {
        $this->authService = $authService;
    }

    /**
     * Login user
     */
    public function __invoke(LoginRequest $request): JsonResponse
    {
        try {
            $response = $this->authService->login(
                $request->email,
                $request->password,
                $request->input('role'),
            );

            return response()->json([
                'message' => 'Login successful',
                'data' => [
                    'user' => new UserResource($response['user']),
                    'token' => $response['token'],
                ],
            ], 200);
        } catch (\Illuminate\Auth\AuthenticationException $e) {
            return response()->json([
                'message' => 'Login failed',
                'error' => 'Invalid email or password',
            ], 401);
        } catch (InvalidRoleException $e) {
            return response()->json([
                'message' => 'Login failed',
                'error' => 'Role tidak sesuai dengan akun ini',
            ], 403);
        }
    }
}
