<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['name', 'code', 'description', 'discount_value', 'points_required', 'expires_at', 'status'])]
class Voucher extends Model
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'discount_value' => 'float',
            'expires_at' => 'datetime',
        ];
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(VoucherRedemption::class);
    }
}
