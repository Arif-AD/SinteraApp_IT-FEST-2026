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
        Schema::create('impact_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('type'); // recyclable_waste, organic_waste, compost_distributed, etc
            $table->decimal('quantity', 12, 2);
            $table->string('unit'); // kg, L, pieces, etc
            $table->decimal('impact_value', 12, 4); // e.g., 2.5 (kg CO2e for 1kg plastic)
            $table->string('impact_unit'); // kg CO2e, etc
            $table->text('description')->nullable();
            $table->timestamps();

            $table->index('user_id');
            $table->index('type');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('impact_records');
    }
};
