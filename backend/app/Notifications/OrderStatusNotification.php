<?php

namespace App\Notifications;

use Illuminate\Notifications\Notification;

class OrderStatusNotification extends Notification
{
    public function __construct(
        private readonly string $title,
        private readonly string $body,
        private readonly string $type = 'activity',
        private readonly ?int $orderId = null,
    ) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'title' => $this->title,
            'body' => $this->body,
            'type' => $this->type,
            'order_id' => $this->orderId,
            'created_at' => now()->toIso8601String(),
        ];
    }

    public function toArray(object $notifiable): array
    {
        return $this->toDatabase($notifiable);
    }
}
