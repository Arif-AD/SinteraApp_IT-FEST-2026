<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['user_id', 'delivery_person_id', 'pickup_address', 'scheduled_at', 'status', 'total_weight', 'total_value'])]
class WastePickup extends Model
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'total_weight' => 'float',
            'total_value' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function deliveryPerson(): BelongsTo
    {
        return $this->belongsTo(User::class, 'delivery_person_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(WasteItem::class);
    }
}
