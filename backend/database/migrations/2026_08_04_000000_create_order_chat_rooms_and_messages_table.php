<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('order_chat_rooms', function (Blueprint $table) {
            $table->id();
            $table->enum('order_type', ['order', 'sharing_order']);
            $table->unsignedBigInteger('order_id');
            $table->timestamps();

            $table->unique(['order_type', 'order_id']);
            $table->index(['order_type', 'order_id']);
        });

        Schema::create('order_chat_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_chat_room_id')->constrained('order_chat_rooms')->onDelete('cascade');
            $table->foreignId('sender_id')->constrained('users')->onDelete('cascade');
            $table->text('message');
            $table->timestamps();

            $table->index('sender_id');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_chat_messages');
        Schema::dropIfExists('order_chat_rooms');
    }
};
