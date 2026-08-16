<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wastes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('waste_type');
            $table->decimal('weight', 10, 2)->default(0);
            $table->text('note')->nullable();
            $table->string('status')->default('requested');
            $table->string('image_url')->nullable();
            $table->decimal('total_value', 12, 2)->default(0);
            $table->decimal('shipping_cost', 12, 2)->default(0);
            $table->boolean('farmer_paid_freight')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('waste_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('waste_id')->constrained('wastes')->cascadeOnDelete();
            $table->foreignId('farmer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('delivery_person_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status')->default('claimed');
            $table->decimal('shipping_cost', 12, 2)->default(0);
            $table->boolean('farmer_paid_freight')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('waste_orders');
        Schema::dropIfExists('wastes');
    }
};
