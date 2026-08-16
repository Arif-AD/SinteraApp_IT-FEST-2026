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
        Schema::create('environmental_conversion_factors', function (Blueprint $table) {
            $table->id();
            $table->string('waste_category'); // plastic, paper, metal, organic_waste, etc - link to WasteCategory name
            $table->string('metric_type'); // co2e, etc
            $table->decimal('factor_value', 12, 4); // e.g., 2.5 kg CO2e per kg of plastic
            $table->string('unit'); // per kg, per liter, etc
            $table->text('description')->nullable();
            $table->timestamp('effective_from')->nullable();
            $table->timestamp('effective_to')->nullable();
            $table->timestamps();

            $table->unique(['waste_category', 'metric_type']);
            $table->index('waste_category');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('environmental_conversion_factors');
    }
};
