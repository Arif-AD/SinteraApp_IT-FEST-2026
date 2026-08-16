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
        Schema::create('waste_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('waste_pickup_id')->constrained()->onDelete('cascade');
            $table->foreignId('waste_category_id')->constrained()->onDelete('cascade');
            $table->decimal('estimated_weight', 10, 2); // in kg
            $table->decimal('actual_weight', 10, 2)->nullable(); // in kg - final value for payment
            $table->decimal('price_per_kg', 12, 4);
            $table->decimal('total_value', 12, 2)->nullable(); // actual_weight * price_per_kg
            $table->timestamps();

            $table->index('waste_pickup_id');
            $table->index('waste_category_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('waste_items');
    }
};
