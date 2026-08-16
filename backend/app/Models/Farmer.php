<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['user_id', 'farm_name', 'farm_address', 'farm_latitude', 'farm_longitude', 'farm_description', 'verification_status'])]
class Farmer extends Model
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'farm_latitude' => 'float',
            'farm_longitude' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function groupBuyings(): HasMany
    {
        return $this->hasMany(GroupBuying::class);
    }
}
