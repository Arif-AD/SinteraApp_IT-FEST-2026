<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('inhabitans_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('product_id')->constrained('products')->onDelete('cascade');
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->foreignId('sharing_order_id')->nullable()->constrained('sharing_orders')->nullOnDelete();
            $table->tinyInteger('rating');
            $table->text('comment')->nullable();
            $table->timestamps();

            $table->unique(['order_id', 'product_id', 'inhabitans_id'], 'product_rating_order_unique');
            $table->unique(['sharing_order_id', 'product_id', 'inhabitans_id'], 'product_rating_sharing_order_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_ratings');
    }
};
