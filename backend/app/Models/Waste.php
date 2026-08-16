<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['user_id', 'waste_type', 'weight', 'note', 'status', 'image_url', 'total_value', 'shipping_cost', 'farmer_paid_freight'])]
class Waste extends Model
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'weight' => 'float',
            'total_value' => 'float',
            'shipping_cost' => 'float',
            'farmer_paid_freight' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function wasteOrders(): HasMany
    {
        return $this->hasMany(WasteOrder::class);
    }
}
