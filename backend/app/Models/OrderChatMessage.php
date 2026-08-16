<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['order_chat_room_id', 'sender_id', 'message'])]
class OrderChatMessage extends Model
{
    use HasFactory;

    public function room(): BelongsTo
    {
        return $this->belongsTo(OrderChatRoom::class, 'order_chat_room_id');
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
