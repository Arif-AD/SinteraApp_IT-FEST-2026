<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['farmer_id', 'name', 'category', 'description', 'price', 'unit', 'stock', 'image', 'available_until', 'status', 'rating'])]
class Product extends Model
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'price' => 'float',
            'available_until' => 'datetime',
            'rating' => 'float',
        ];
    }

    public function farmer(): BelongsTo
    {
        return $this->belongsTo(Farmer::class);
    }

    public function groupBuyings(): HasMany
    {
        return $this->hasMany(GroupBuying::class);
    }

    // Order items removed; orders now store `product_id` directly.
}
