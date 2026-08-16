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
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('inhabitans_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('farmers_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('delivery_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('group_buying_id')->nullable()->constrained()->onDelete('set null');
            $table->decimal('total_amount', 12, 2);
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('final_amount', 12, 2);
            $table->enum('status', ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'])->default('pending');
            $table->enum('payment_status', ['unpaid', 'paid', 'failed', 'refunded'])->default('unpaid');
            $table->enum('delivery_status', ['pending', 'shipped', 'delivered', 'cancelled'])->default('pending');
            $table->timestamps();
            $table->softDeletes();

            $table->index('inhabitans_id');
            $table->index('farmers_id');
            $table->index('delivery_id');
            $table->index('group_buying_id');
            $table->index('status');
            $table->index('payment_status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
