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
        Schema::create('sharing_order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sharing_order_id')->constrained('sharing_orders')->onDelete('cascade');
            $table->foreignId('product_id')->constrained()->onDelete('cascade');
            $table->integer('quantity');
            $table->decimal('unit_price', 12, 2);
            $table->decimal('subtotal', 12, 2);
            $table->string('product_name')->nullable();
            $table->decimal('product_price', 12, 2)->default(0);
            $table->text('product_image')->nullable();
            $table->string('product_unit')->nullable();
            $table->text('product_description')->nullable();
            $table->integer('product_quantity')->nullable();
            $table->timestamps();

            $table->index('sharing_order_id');
            $table->index('product_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sharing_order_items');
    }
};
