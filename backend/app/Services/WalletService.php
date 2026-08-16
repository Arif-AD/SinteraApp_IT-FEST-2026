<?php

namespace App\Services;

use App\Exceptions\InvalidTransactionException;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;

class WalletService
{
    /**
     * Add balance to wallet with transaction record
     */
    public function addBalance(Wallet $wallet, float $amount, string $type, ?string $description = null, ?string $referenceType = null, ?int $referenceId = null): void
    {
        DB::transaction(function () use ($wallet, $amount, $type, $description, $referenceType, $referenceId) {
            $balanceBefore = $wallet->balance;
            $wallet->increment('balance', $amount);
            $wallet->refresh();

            $wallet->transactions()->create([
                'type' => $type,
                'amount' => $amount,
                'balance_before' => $balanceBefore,
                'balance_after' => $wallet->balance,
                'reference_type' => $referenceType,
                'reference_id' => $referenceId,
                'description' => $description,
            ]);
        });
    }

    /**
     * Deduct balance from wallet with validation
     */
    public function deductBalance(Wallet $wallet, float $amount, string $type, ?string $description = null, ?string $referenceType = null, ?int $referenceId = null): void
    {
        if ($wallet->balance < $amount) {
            throw new InvalidTransactionException("Insufficient balance. Required: {$amount}, Available: {$wallet->balance}");
        }

        DB::transaction(function () use ($wallet, $amount, $type, $description, $referenceType, $referenceId) {
            $balanceBefore = $wallet->balance;
            $wallet->decrement('balance', $amount);
            $wallet->refresh();

            $wallet->transactions()->create([
                'type' => $type,
                'amount' => -$amount,
                'balance_before' => $balanceBefore,
                'balance_after' => $wallet->balance,
                'reference_type' => $referenceType,
                'reference_id' => $referenceId,
                'description' => $description,
            ]);
        });
    }

    /**
     * Get wallet or create if not exists
     */
    public function getOrCreateWallet(\App\Models\User $user): Wallet
    {
        return $user->wallet ?: $user->wallet()->create(['balance' => 0]);
    }
}
