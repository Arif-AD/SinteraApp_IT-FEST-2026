<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'type', 'quantity', 'unit', 'impact_value', 'impact_unit', 'description'])]
class ImpactRecord extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'quantity' => 'float',
            'impact_value' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
