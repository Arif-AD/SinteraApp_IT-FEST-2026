<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Schema;

class OrderResource extends JsonResource
{
    public function toArray($request): array
    {
        $productSnapshot = [
            'id' => $this->product_id,
            'name' => $this->product_name,
            'price' => $this->product_price,
            'image' => $this->product_image,
            'unit' => $this->product_unit,
            'description' => $this->product_description,
        ];

        $hasSnapshot = !empty($productSnapshot['name']) || $productSnapshot['price'] !== null || !empty($productSnapshot['image']) || !empty($productSnapshot['unit']) || !empty($productSnapshot['description']);
        if (!$hasSnapshot && $this->product) {
            $productSnapshot = [
                'id' => $this->product->id,
                'name' => $this->product->name,
                'price' => $this->product->price,
                'image' => $this->product->image,
                'unit' => $this->product->unit,
                'description' => $this->product->description,
            ];
            $hasSnapshot = true;
        }

        $items = $this->whenLoaded('items', function () {
            return $this->items->map(function ($item) {
                $product = $item->product;

                return [
                    'id' => $item->product_id,
                    'name' => $item->product_name ?? $product?->name,
                    'price' => $item->product_price ?? $item->unit_price,
                    'image' => $item->product_image ?? $product?->image,
                    'unit' => $item->product_unit ?? $product?->unit,
                    'description' => $item->product_description ?? $product?->description,
                    'quantity' => $item->product_quantity ?? $item->quantity,
                    'subtotal' => $item->subtotal,
                ];
            })->all();
        });

        return [
            'items' => $items,
            'id' => $this->id,
            'inhabitans_id' => $this->inhabitans_id,
            'farmers_id' => $this->farmers_id,
            'delivery_id' => $this->delivery_id,
            'group_buying_id' => $this->group_buying_id,
            'total_amount' => $this->total_amount,
            //'discount_amount' => $this->discount_amount,
            'final_amount' => $this->final_amount,
            'status' => $this->status,
            'payment_status' => $this->payment_status,
            'delivery_status' => $this->delivery_status,
            'base_fee' => $this->base_fee,
            'distance_fee' => $this->distance_fee,
            'total_shipping' => $this->total_shipping,
            'farmer_subsidy' => $this->farmer_subsidy,
            'customer_shipping' => $this->customer_shipping,
            'shipping_distance_km' => $this->shipping_distance_km,
            'shipping_note' => $this->shipping_note,
            'created_at' => $this->created_at?->toDateTimeString(),
            'product_name' => $this->product_name,
            'product_price' => $this->product_price,
            'product_image' => $this->product_image,
            'product_unit' => $this->product_unit,
            'product_description' => $this->product_description,
            'product_quantity' => $this->product_quantity,
            'product_rating' => $this->whenLoaded('productRatings') ? $this->productRatings->first()?->rating : null,
            'product' => $hasSnapshot ? $productSnapshot : null,
            'receiver' => $this->when($this->receiver_id !== null, function () {
                return [
                    'id' => $this->receiver_id,
                    'name' => $this->receiver_name,
                    'phone' => $this->receiver_phone,
                    'address' => $this->receiver_address,
                    'detail_house' => $this->receiver_detail_house,
                ];
            }),
            'delivery_task' => $this->whenLoaded('deliveryTask', function () {
                return $this->deliveryTask ? [
                    'id' => $this->deliveryTask->id,
                    'type' => $this->deliveryTask->type,
                    'status' => $this->deliveryTask->status,
                    'pickup_address' => $this->deliveryTask->pickup_address,
                    'destination_address' => $this->deliveryTask->destination_address,
                    'delivery_person' => $this->deliveryTask->deliveryPerson ? [
                        'id' => $this->deliveryTask->deliveryPerson->id,
                        'name' => $this->deliveryTask->deliveryPerson->name,
                    ] : null,
                ] : null;
            }),
            'user' => $this->whenLoaded('user', function () {
                if ($this->user) {
                    return [
                        'id' => $this->user->id,
                        'name' => $this->user->name,
                        'email' => $this->user->email,
                        'address' => $this->user->address?->address,
                        'detail_house' => $this->user->address?->detail_house,
                    ];
                }
                return null;
            }),
        ];
    }
}
