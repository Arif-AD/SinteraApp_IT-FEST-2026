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
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('farmer_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->string('category'); // vegetables, fruits, etc
            $table->text('description')->nullable();
            $table->decimal('price', 12, 2);
            $table->string('unit'); // kg, piece, bundle, etc
            $table->integer('stock')->default(0);
            $table->string('image')->nullable(); // stored via Laravel Storage
            $table->date('harvest_date')->nullable();
            $table->date('available_until')->nullable();
            $table->enum('status', ['available', 'sold_out', 'inactive'])->default('available');
            $table->timestamps();
            $table->softDeletes();

            $table->index('farmer_id');
            $table->index('status');
            $table->index('category');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
