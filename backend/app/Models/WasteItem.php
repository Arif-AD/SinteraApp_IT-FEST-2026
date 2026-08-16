<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['waste_pickup_id', 'waste_category_id', 'estimated_weight', 'actual_weight', 'price_per_kg', 'total_value'])]
class WasteItem extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'estimated_weight' => 'float',
            'actual_weight' => 'float',
            'price_per_kg' => 'float',
            'total_value' => 'float',
        ];
    }

    public function wastePickup(): BelongsTo
    {
        return $this->belongsTo(WastePickup::class);
    }

    public function wasteCategory(): BelongsTo
    {
        return $this->belongsTo(WasteCategory::class);
    }
}
