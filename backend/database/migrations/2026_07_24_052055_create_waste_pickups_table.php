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
        Schema::create('waste_pickups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('delivery_person_id')->nullable()->constrained('users')->onDelete('set null');
            $table->text('pickup_address');
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->dateTime('scheduled_at');
            $table->enum('status', ['requested', 'assigned', 'picked_up', 'weighed', 'completed', 'cancelled'])->default('requested');
            $table->decimal('total_weight', 10, 2)->nullable(); // in kg
            $table->decimal('total_value', 12, 2)->nullable(); // calculated from weight & prices
            $table->timestamps();
            $table->softDeletes();

            $table->index('user_id');
            $table->index('delivery_person_id');
            $table->index('status');
            $table->index('scheduled_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('waste_pickups');
    }
};
