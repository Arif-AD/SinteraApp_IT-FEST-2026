<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray($request): array
    {
        $address = $this->address()->first();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'profile' => $this->profile,
            'profile_photo' => $this->profile_photo,
            'address' => $address?->address,
            'detail_house' => $address?->detail_house,
            'latitude' => $address?->latitude,
            'longitude' => $address?->longitude,
            'is_verified' => $this->is_verified,
            'created_at' => $this->created_at?->toDateTimeString(),
            'updated_at' => $this->updated_at?->toDateTimeString(),
        ];
    }
}
