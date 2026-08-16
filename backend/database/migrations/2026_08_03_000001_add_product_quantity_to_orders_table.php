<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table): void {
            if (!Schema::hasColumn('orders', 'product_quantity')) {
                $table->integer('product_quantity')->default(1);
            }
        });

        // Migrate existing quantities from order_items if present
        if (Schema::hasTable('order_items')) {
            DB::table('orders')->orderBy('id')->chunkById(100, function ($orders) {
                foreach ($orders as $order) {
                    $item = DB::table('order_items')->where('order_id', $order->id)->first();
                    if ($item && isset($item->quantity)) {
                        DB::table('orders')->where('id', $order->id)->update(['product_quantity' => (int)$item->quantity]);
                    }
                }
            });
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table): void {
            if (Schema::hasColumn('orders', 'product_quantity')) {
                $table->dropColumn('product_quantity');
            }
        });
    }
};
