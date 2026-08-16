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
        Schema::create('group_buyings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->onDelete('cascade');
            $table->foreignId('farmer_id')->constrained()->onDelete('cascade');
            $table->integer('target_quantity');
            $table->integer('current_quantity')->default(0);
            $table->integer('minimum_quantity');
            $table->decimal('price_per_unit', 12, 2);
            $table->dateTime('deadline');
            $table->dateTime('delivery_date')->nullable();
            $table->enum('status', ['open', 'target_reached', 'confirmed', 'shipping', 'completed', 'cancelled'])->default('open');
            $table->timestamps();
            $table->softDeletes();

            $table->index('product_id');
            $table->index('farmer_id');
            $table->index('status');
            $table->index('deadline');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('group_buyings');
    }
};
