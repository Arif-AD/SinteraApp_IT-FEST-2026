<?php

namespace App\Services;

use App\Models\EnvironmentalConversionFactor;
use Illuminate\Support\Facades\Cache;

class EnvironmentalImpactService
{
    private const CACHE_TTL = 3600; // 1 hour
    private const CACHE_KEY_PREFIX = 'env_conversion_factor:';

    /**
     * Calculate estimated environmental impact
     * 
     * Example: 1kg of plastic with factor 2.5 = 2.5 kg CO2e avoided
     */
    public function calculateImpact(string $wasteCategory, float $quantity, string $metricType = 'co2e'): array
    {
        $factor = $this->getConversionFactor($wasteCategory, $metricType);
        
        if (!$factor) {
            return [
                'impact_value' => 0,
                'impact_unit' => $metricType,
                'is_estimated' => true,
                'note' => "No conversion factor found for {$wasteCategory}",
            ];
        }

        $impactValue = $quantity * $factor->factor_value;

        return [
            'impact_value' => $impactValue,
            'impact_unit' => $factor->unit,
            'is_estimated' => true,
            'description' => $factor->description,
        ];
    }

    /**
     * Get conversion factor from cache or database
     */
    public function getConversionFactor(string $wasteCategory, string $metricType = 'co2e'): ?EnvironmentalConversionFactor
    {
        $cacheKey = self::CACHE_KEY_PREFIX . "{$wasteCategory}:{$metricType}";

        return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($wasteCategory, $metricType) {
            return EnvironmentalConversionFactor::where('waste_category', $wasteCategory)
                ->where('metric_type', $metricType)
                ->where(function ($query) {
                    $query->whereNull('effective_from')
                        ->orWhere('effective_from', '<=', now());
                })
                ->where(function ($query) {
                    $query->whereNull('effective_to')
                        ->orWhere('effective_to', '>=', now());
                })
                ->first();
        });
    }

    /**
     * Flush cache for specific waste category
     */
    public function flushCache(string $wasteCategory = null): void
    {
        if ($wasteCategory) {
            Cache::forget(self::CACHE_KEY_PREFIX . "{$wasteCategory}:*");
        } else {
            Cache::flush();
        }
    }
}
