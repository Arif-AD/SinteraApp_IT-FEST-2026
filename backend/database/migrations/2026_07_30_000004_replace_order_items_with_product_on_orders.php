<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'product_id')) {
                $table->foreignId('product_id')->nullable()->constrained()->after('group_buying_id')->nullOnDelete();
            }
        });

        // Preserve `order_items` table to support multi-product orders.
        // Historically this migration dropped the `order_items` table
        // and moved to a single-product snapshot on `orders`. To
        // maintain multi-product support and avoid runtime errors
        // when `order_items` is missing, we no longer drop it here.
    }

    public function down(): void
    {
        // Recreate order_items table (best-effort)
        if (!Schema::hasTable('order_items')) {
            Schema::create('order_items', function (Blueprint $table) {
                $table->id();
                $table->foreignId('order_id')->constrained()->onDelete('cascade');
                $table->foreignId('product_id')->constrained()->onDelete('cascade');
                $table->integer('quantity');
                $table->decimal('unit_price', 12, 2);
                $table->decimal('subtotal', 12, 2);
                $table->timestamps();
            });
        }

        if (Schema::hasTable('orders')) {
            Schema::table('orders', function (Blueprint $table) {
                if (Schema::hasColumn('orders', 'product_id')) {
                    $table->dropForeign(['product_id']);
                    $table->dropColumn('product_id');
                }
            });
        }
    }
};
