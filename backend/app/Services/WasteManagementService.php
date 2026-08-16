<?php

namespace App\Services;

use App\Models\WastePickup;
use Illuminate\Support\Facades\DB;

class WasteManagementService
{
    protected WalletService $walletService;
    protected PointService $pointService;
    protected EnvironmentalImpactService $impactService;

    public function __construct(
        WalletService $walletService,
        PointService $pointService,
        EnvironmentalImpactService $impactService
    ) {
        $this->walletService = $walletService;
        $this->pointService = $pointService;
        $this->impactService = $impactService;
    }

    /**
     * Complete waste pickup and calculate payment
     */
    public function completeWastePickup(WastePickup $wastePickup): void
    {
        if ($wastePickup->status === 'completed') {
            return; // Already completed
        }

        DB::transaction(function () use ($wastePickup) {
            // Calculate total weight and value
            $totalWeight = $wastePickup->items->sum('actual_weight') ?? 0;
            $totalValue = $wastePickup->items->sum('total_value') ?? 0;

            // Update pickup record
            $wastePickup->update([
                'status' => 'completed',
                'total_weight' => $totalWeight,
                'total_value' => $totalValue,
            ]);

            // Credit wallet
            $wallet = $this->walletService->getOrCreateWallet($wastePickup->user);
            $this->walletService->addBalance(
                $wallet,
                $totalValue,
                'waste_sale',
                "Waste pickup completed - {$totalWeight}kg",
                WastePickup::class,
                $wastePickup->id
            );

            // Award points per item category: organik = 150pt/kg, anorganik = 300pt/kg
            $pointWallet = $this->pointService->getOrCreatePointWallet($wastePickup->user);
            $pointsEarned = 0;
            foreach ($wastePickup->items as $item) {
                $catName = strtolower(trim((string) ($item->wasteCategory?->name ?? '')));
                $mult = ($catName === 'anorganik' || str_contains($catName, 'anorganik')) ? 300 : 150;
                $itemWeight = (float) ($item->actual_weight ?? 0);
                $pointsEarned += (int) floor($itemWeight * $mult);
            }
            if ($pointsEarned > 0) {
                $this->pointService->addPoints(
                    $pointWallet,
                    $pointsEarned,
                    'waste',
                    "Waste pickup - {$totalWeight}kg = {$pointsEarned} points",
                    WastePickup::class,
                    $wastePickup->id
                );
            }

            // Record environmental impact
            foreach ($wastePickup->items as $item) {
                $impact = $this->impactService->calculateImpact(
                    $item->wasteCategory->name,
                    $item->actual_weight ?? 0
                );

                $wastePickup->user->impactRecords()->create([
                    'type' => 'recyclable_waste',
                    'quantity' => $item->actual_weight ?? 0,
                    'unit' => 'kg',
                    'impact_value' => $impact['impact_value'],
                    'impact_unit' => $impact['impact_unit'],
                    'description' => "{$item->wasteCategory->name} waste recycling",
                ]);
            }
        });
    }
}
