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
        Schema::create('delivery_tasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_person_id')->nullable()->constrained('users')->onDelete('cascade');
            $table->string('type'); // agricultural_delivery, waste_pickup, organic_waste_pickup, compost_delivery
            $table->foreignId('order_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('waste_pickup_id')->nullable()->constrained()->onDelete('set null');
            // compost_orders may be created later; create nullable column and add FK only if table exists
            $table->unsignedBigInteger('compost_order_id')->nullable();
            if (Schema::hasTable('compost_orders')) {
                $table->foreign('compost_order_id')->references('id')->on('compost_orders')->onDelete('set null');
            }
            $table->text('pickup_address')->nullable();
            $table->decimal('pickup_latitude', 10, 8)->nullable();
            $table->decimal('pickup_longitude', 11, 8)->nullable();
            $table->text('destination_address')->nullable();
            $table->decimal('destination_latitude', 10, 8)->nullable();
            $table->decimal('destination_longitude', 11, 8)->nullable();
            $table->dateTime('scheduled_at');
            $table->dateTime('completed_at')->nullable();
            $table->enum('status', ['pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'cancelled'])->default('pending');
            $table->timestamps();
            $table->softDeletes();

            $table->index('delivery_person_id');
            $table->index('status');
            $table->index('type');
            $table->index('scheduled_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delivery_tasks');
    }
};
