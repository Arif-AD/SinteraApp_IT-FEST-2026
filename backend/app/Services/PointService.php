<?php

namespace App\Services;

use App\Exceptions\InsufficientPointsException;
use App\Models\PointWallet;
use Illuminate\Support\Facades\DB;

class PointService
{
    /**
     * Add points to wallet with transaction record
     */
    public function addPoints(PointWallet $pointWallet, int $amount, string $type, ?string $description = null, ?string $referenceType = null, ?int $referenceId = null): void
    {
        DB::transaction(function () use ($pointWallet, $amount, $type, $description, $referenceType, $referenceId) {
            $balanceBefore = $pointWallet->balance;
            $pointWallet->increment('balance', $amount);
            $pointWallet->refresh();

            $pointWallet->transactions()->create([
                'type' => $type,
                'amount' => $amount,
                'balance_before' => $balanceBefore,
                'balance_after' => $pointWallet->balance,
                'reference_type' => $referenceType,
                'reference_id' => $referenceId,
                'description' => $description,
            ]);
        });
    }

    /**
     * Deduct points from wallet with validation
     */
    public function deductPoints(PointWallet $pointWallet, int $amount, string $type, ?string $description = null, ?string $referenceType = null, ?int $referenceId = null): void
    {
        if ($pointWallet->balance < $amount) {
            throw new InsufficientPointsException("Insufficient points. Required: {$amount}, Available: {$pointWallet->balance}");
        }

        DB::transaction(function () use ($pointWallet, $amount, $type, $description, $referenceType, $referenceId) {
            $balanceBefore = $pointWallet->balance;
            $pointWallet->decrement('balance', $amount);
            $pointWallet->refresh();

            $pointWallet->transactions()->create([
                'type' => $type,
                'amount' => -$amount,
                'balance_before' => $balanceBefore,
                'balance_after' => $pointWallet->balance,
                'reference_type' => $referenceType,
                'reference_id' => $referenceId,
                'description' => $description,
            ]);
        });
    }

    /**
     * Get point wallet or create if not exists
     */
    public function getOrCreatePointWallet(\App\Models\User $user): PointWallet
    {
        return $user->pointWallet ?: $user->pointWallet()->create(['balance' => 0]);
    }
}
