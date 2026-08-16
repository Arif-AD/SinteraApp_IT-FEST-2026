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
            if (!Schema::hasColumn('orders', 'product_name')) {
                $table->string('product_name')->nullable();
            }
            if (!Schema::hasColumn('orders', 'product_price')) {
                $table->decimal('product_price', 12, 2)->default(0);
            }
            if (!Schema::hasColumn('orders', 'product_image')) {
                $table->text('product_image')->nullable();
            }
            if (!Schema::hasColumn('orders', 'product_unit')) {
                $table->string('product_unit')->nullable();
            }
            if (!Schema::hasColumn('orders', 'product_description')) {
                $table->text('product_description')->nullable();
            }
        });

        if (Schema::hasColumn('orders', 'product_id') && Schema::hasTable('products')) {
            $products = DB::table('products')->select('id', 'name', 'price', 'image', 'unit', 'description')->get()->keyBy('id');
            DB::table('orders')->whereNotNull('product_id')->orderBy('id')->chunkById(100, function ($orders) use ($products): void {
                foreach ($orders as $order) {
                    $product = $products[$order->product_id] ?? null;
                    if (!$product) {
                        continue;
                    }

                    DB::table('orders')
                        ->where('id', $order->id)
                        ->update([
                            'product_name' => $product->name,
                            'product_price' => $product->price,
                            'product_image' => $product->image,
                            'product_unit' => $product->unit,
                            'product_description' => $product->description,
                        ]);
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
            if (Schema::hasColumn('orders', 'product_description')) {
                $table->dropColumn('product_description');
            }
            if (Schema::hasColumn('orders', 'product_unit')) {
                $table->dropColumn('product_unit');
            }
            if (Schema::hasColumn('orders', 'product_image')) {
                $table->dropColumn('product_image');
            }
            if (Schema::hasColumn('orders', 'product_price')) {
                $table->dropColumn('product_price');
            }
            if (Schema::hasColumn('orders', 'product_name')) {
                $table->dropColumn('product_name');
            }
        });
    }
};
