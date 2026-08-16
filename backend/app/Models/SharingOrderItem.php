<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['sharing_order_id', 'product_id', 'quantity', 'unit_price', 'subtotal', 'product_name', 'product_price', 'product_image', 'product_unit', 'product_description', 'product_quantity'])]
class SharingOrderItem extends Model
{
    use HasFactory;

    public function sharingOrder(): BelongsTo
    {
        return $this->belongsTo(SharingOrder::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class)->withTrashed();
    }
}
