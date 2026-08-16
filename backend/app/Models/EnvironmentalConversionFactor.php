<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['waste_category', 'metric_type', 'factor_value', 'unit', 'description', 'effective_from', 'effective_to'])]
class EnvironmentalConversionFactor extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'factor_value' => 'float',
            'effective_from' => 'datetime',
            'effective_to' => 'datetime',
        ];
    }
}
