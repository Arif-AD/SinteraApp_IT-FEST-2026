<?php

namespace App\Models;

use App\Models\CompostOrder;
use App\Models\Order;
use App\Models\SharingOrder;
use App\Models\User;
use App\Models\Waste;
use App\Models\WastePickup;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['delivery_person_id', 'type', 'order_id', 'sharing_order_id', 'waste_id', 'waste_pickup_id', 'compost_order_id', 'pickup_address', 'pickup_latitude', 'pickup_longitude', 'destination_address', 'destination_latitude', 'destination_longitude', 'scheduled_at', 'completed_at', 'status'])]
class DeliveryTask extends Model
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'pickup_latitude' => 'float',
            'pickup_longitude' => 'float',
            'destination_latitude' => 'float',
            'destination_longitude' => 'float',
            'scheduled_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function deliveryPerson(): BelongsTo
    {
        return $this->belongsTo(User::class, 'delivery_person_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function sharingOrder(): BelongsTo
    {
        return $this->belongsTo(SharingOrder::class, 'sharing_order_id');
    }

    public function waste(): BelongsTo
    {
        return $this->belongsTo(Waste::class);
    }

    public function wastePickup(): BelongsTo
    {
        return $this->belongsTo(WastePickup::class);
    }

    public function compostOrder(): BelongsTo
    {
        return $this->belongsTo(CompostOrder::class);
    }
}
