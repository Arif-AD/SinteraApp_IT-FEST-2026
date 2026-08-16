<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['waste_id', 'farmer_id', 'inhabitans_id', 'delivery_person_id', 'status', 'shipping_cost', 'farmer_paid_freight'])]
class WasteOrder extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'shipping_cost' => 'float',
            'farmer_paid_freight' => 'boolean',
        ];
    }

    public function waste(): BelongsTo
    {
        return $this->belongsTo(Waste::class);
    }

    public function farmer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'farmer_id');
    }

    public function inhabitant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'inhabitans_id');
    }

    public function deliveryPerson(): BelongsTo
    {
        return $this->belongsTo(User::class, 'delivery_person_id');
    }
}
