<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['wallet_id', 'type', 'amount', 'balance_before', 'balance_after', 'reference_type', 'reference_id', 'description'])]
class WalletTransaction extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'amount' => 'float',
            'balance_before' => 'float',
            'balance_after' => 'float',
        ];
    }

    public function wallet(): BelongsTo
    {
        return $this->belongsTo(Wallet::class);
    }
}
