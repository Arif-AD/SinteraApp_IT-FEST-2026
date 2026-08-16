<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Models\ProductRating;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\BelongsTo as EloquentBelongsTo;

#[Fillable(['inhabitans_id', 'farmers_id', 'delivery_id', 'group_buying_id', 'product_id', 'product_name', 'product_price', 'product_image', 'product_unit', 'product_description', 'product_quantity', 'total_amount', 'discount_amount', 'final_amount', 'base_fee', 'distance_fee', 'total_shipping', 'farmer_subsidy', 'customer_shipping', 'shipping_distance_km', 'shipping_note', 'status', 'payment_status', 'delivery_status'])]
class Order extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'total_amount' => 'float',
            'discount_amount' => 'float',
            'final_amount' => 'float',
            'base_fee' => 'float',
            'distance_fee' => 'float',
            'total_shipping' => 'float',
            'farmer_subsidy' => 'float',
            'customer_shipping' => 'float',
            'shipping_distance_km' => 'float',
            'product_price' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'inhabitans_id');
    }

    public function inhabitant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'inhabitans_id');
    }

    public function farmerUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'farmers_id');
    }

    public function deliveryPerson(): BelongsTo
    {
        return $this->belongsTo(User::class, 'delivery_id');
    }

    public function groupBuying(): BelongsTo
    {
        return $this->belongsTo(GroupBuying::class);
    }

    public function product(): EloquentBelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id')->withTrashed();
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function productRatings(): HasMany
    {
        return $this->hasMany(ProductRating::class, 'order_id');
    }

    public function deliveryTask(): HasOne
    {
        return $this->hasOne(DeliveryTask::class);
    }
}
