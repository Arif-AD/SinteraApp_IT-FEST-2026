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
        Schema::create('point_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('point_wallet_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['waste', 'organic_waste', 'environmental_activity', 'voucher_redemption', 'other']);
            $table->integer('amount');
            $table->integer('balance_before');
            $table->integer('balance_after');
            $table->string('reference_type')->nullable(); // WastePickup, VoucherRedemption, etc
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();

            $table->index('point_wallet_id');
            $table->index('type');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('point_transactions');
    }
};
