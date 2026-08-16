<?php

namespace App\Http\Middleware;

use App\Exceptions\InvalidRoleException;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        if (!$request->user()) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $userRole = strtolower(trim((string) $request->user()->role));
        $allowedRoles = array_map(fn (string $role): string => strtolower(trim($role)), $roles);

        if (!in_array($userRole, $allowedRoles, true)) {
            throw new InvalidRoleException("User role is not authorized for this action");
        }

        return $next($request);
    }
}

