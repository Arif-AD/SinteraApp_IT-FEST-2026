<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['order_type', 'order_id', 'participant_a_id', 'participant_b_id', 'chat_channel'])]
class OrderChatRoom extends Model
{
    use HasFactory;

    public function messages(): HasMany
    {
        return $this->hasMany(OrderChatMessage::class);
    }

    public function participantA(): BelongsTo
    {
        return $this->belongsTo(User::class, 'participant_a_id');
    }

    public function participantB(): BelongsTo
    {
        return $this->belongsTo(User::class, 'participant_b_id');
    }
}
