<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'code', 'price_per_kg', 'description'])]
class WasteCategory extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'price_per_kg' => 'float',
        ];
    }

    public function wasteItems(): HasMany
    {
        return $this->hasMany(WasteItem::class);
    }
}
