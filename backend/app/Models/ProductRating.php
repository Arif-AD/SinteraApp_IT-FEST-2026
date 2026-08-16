<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use App\Models\Order;
use App\Models\Product;
use App\Models\SharingOrder;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['inhabitans_id', 'product_id', 'order_id', 'sharing_order_id', 'rating', 'comment'])]
class ProductRating extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'rating' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::saved(function (ProductRating $rating) {
            self::recalculateProductRating($rating->product_id);
        });

        static::deleted(function (ProductRating $rating) {
            self::recalculateProductRating($rating->product_id);
        });
    }

    public static function recalculateProductRating(int $productId): void
    {
        $average = self::where('product_id', $productId)
            ->avg('rating');

        $newRating = $average !== null ? round($average, 1) : null;

        Product::where('id', $productId)
            ->update(['rating' => $newRating]);
    }

    public function inhabitant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'inhabitans_id');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function sharingOrder(): BelongsTo
    {
        return $this->belongsTo(SharingOrder::class);
    }
}
