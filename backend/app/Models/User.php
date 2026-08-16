<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;use App\Models\SharingOrder;use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'phone', 'role', 'profile', 'profile_photo', 'is_verified'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_verified' => 'boolean',
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }

    // Relationships
    public function farmer(): HasOne
    {
        return $this->hasOne(Farmer::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'inhabitans_id');
    }

    public function sharingOrders(): HasMany
    {
        return $this->hasMany(SharingOrder::class, 'inhabitans_id');
    }

    public function sharingPosts(): HasMany
    {
        return $this->hasMany(SharingPost::class);
    }

    public function wastePickups(): HasMany
    {
        return $this->hasMany(WastePickup::class);
    }

    public function wastes(): HasMany
    {
        return $this->hasMany(Waste::class);
    }

    public function wasteOrders(): HasMany
    {
        return $this->hasMany(WasteOrder::class, 'farmer_id');
    }

    public function organicWastes(): HasMany
    {
        return $this->hasMany(OrganicWaste::class);
    }

    public function compostOrders(): HasMany
    {
        return $this->hasMany(CompostOrder::class);
    }

    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class);
    }

    public function pointWallet(): HasOne
    {
        return $this->hasOne(PointWallet::class);
    }

    public function voucherRedemptions(): HasMany
    {
        return $this->hasMany(VoucherRedemption::class);
    }

    public function impactRecords(): HasMany
    {
        return $this->hasMany(ImpactRecord::class);
    }

    public function deliveryTasks(): HasMany
    {
        return $this->hasMany(DeliveryTask::class, 'delivery_person_id');
    }

    public function address(): HasOne
    {
        return $this->hasOne(UserAddress::class);
    }
}

