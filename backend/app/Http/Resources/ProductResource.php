<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'farmer_id' => $this->farmer_id,
            'name' => $this->name,
            'category' => $this->category,
            'description' => $this->description,
            'price' => $this->price,
            'unit' => $this->unit,
            'stock' => $this->stock,
            'image' => $this->image,
            'available_until' => $this->available_until?->toDateTimeString(),
            'status' => $this->status,
            'created_at' => $this->created_at?->toDateTimeString(),
        ];
    }
}
