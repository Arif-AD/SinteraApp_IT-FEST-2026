<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['product_id', 'farmer_id', 'target_quantity', 'current_quantity', 'minimum_quantity', 'price_per_unit', 'deadline', 'delivery_date', 'status'])]
class GroupBuying extends Model
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'price_per_unit' => 'float',
            'deadline' => 'datetime',
            'delivery_date' => 'datetime',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function farmer(): BelongsTo
    {
        return $this->belongsTo(Farmer::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
