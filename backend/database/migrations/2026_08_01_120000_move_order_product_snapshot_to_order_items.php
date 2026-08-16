<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('orders') || !Schema::hasTable('order_items')) {
            return;
        }

        // Make product_id nullable on order_items to allow snapshot-only rows
        $driver = Schema::getConnection()->getDriverName();
        if ($driver === 'pgsql') {
            try {
                DB::statement('ALTER TABLE order_items ALTER COLUMN product_id DROP NOT NULL;');
            } catch (\Throwable) {
                // ignore if cannot alter
            }
        }

        Schema::table('order_items', function (Blueprint $table) {
            if (!Schema::hasColumn('order_items', 'product_name')) {
                $table->string('product_name')->nullable()->after('product_id');
            }
            if (!Schema::hasColumn('order_items', 'product_price')) {
                $table->decimal('product_price', 12, 2)->default(0)->after('product_name');
            }
            if (!Schema::hasColumn('order_items', 'product_image')) {
                $table->text('product_image')->nullable()->after('product_price');
            }
            if (!Schema::hasColumn('order_items', 'product_unit')) {
                $table->string('product_unit')->nullable()->after('product_image');
            }
            if (!Schema::hasColumn('order_items', 'product_description')) {
                $table->text('product_description')->nullable()->after('product_unit');
            }
            if (!Schema::hasColumn('order_items', 'product_quantity')) {
                $table->integer('product_quantity')->default(1)->after('product_description');
            }
        });

        // Migrate existing single-product order snapshots into order_items when those columns still exist.
        $snapshotColumns = array_values(array_filter([
            'product_id',
            'product_name',
            'product_price',
            'product_image',
            'product_unit',
            'product_description',
            'product_quantity',
        ], fn ($column) => Schema::hasColumn('orders', $column)));

        if (!empty($snapshotColumns)) {
            $orders = DB::table('orders')->select(array_merge(['id'], $snapshotColumns))->get();

            foreach ($orders as $order) {
                $hasSnapshot = false;
                foreach ($snapshotColumns as $column) {
                    $value = $order->{$column} ?? null;
                    if ($value !== null && $value !== '' && $value !== false) {
                        $hasSnapshot = true;
                        break;
                    }
                }

                if (!$hasSnapshot) {
                    continue;
                }

                $existing = DB::table('order_items')->where('order_id', $order->id)->first();
                if ($existing) {
                    continue;
                }

                $quantity = (int) ($order->product_quantity ?? 1);
                $unitPrice = (float) ($order->product_price ?? 0);
                $subtotal = $unitPrice * $quantity;

                $insertData = [
                    'order_id' => $order->id,
                    'quantity' => $quantity,
                    'unit_price' => $unitPrice,
                    'subtotal' => $subtotal,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                if (Schema::hasColumn('order_items', 'product_id')) {
                    $insertData['product_id'] = $order->product_id ?? null;
                }
                if (Schema::hasColumn('order_items', 'product_name')) {
                    $insertData['product_name'] = $order->product_name ?? null;
                }
                if (Schema::hasColumn('order_items', 'product_price')) {
                    $insertData['product_price'] = $unitPrice;
                }
                if (Schema::hasColumn('order_items', 'product_image')) {
                    $insertData['product_image'] = $order->product_image ?? null;
                }
                if (Schema::hasColumn('order_items', 'product_unit')) {
                    $insertData['product_unit'] = $order->product_unit ?? null;
                }
                if (Schema::hasColumn('order_items', 'product_description')) {
                    $insertData['product_description'] = $order->product_description ?? null;
                }
                if (Schema::hasColumn('order_items', 'product_quantity')) {
                    $insertData['product_quantity'] = $quantity;
                }

                DB::table('order_items')->insert($insertData);
            }
        }

        // Now drop snapshot columns from orders
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'product_id')) {
                try {
                    $table->dropForeign(['product_id']);
                } catch (\Throwable) {
                    // ignore if foreign not exists
                }
                $table->dropColumn('product_id');
            }
            foreach (['product_name','product_price','product_image','product_unit','product_description','product_quantity'] as $col) {
                if (Schema::hasColumn('orders', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('orders') || !Schema::hasTable('order_items')) {
            return;
        }

        // Add snapshot columns back to orders (best-effort)
        Schema::table('orders', function (Blueprint $table) {
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
            if (!Schema::hasColumn('orders', 'product_quantity')) {
                $table->integer('product_quantity')->default(1);
            }
        });

        // remove snapshot columns from order_items
        Schema::table('order_items', function (Blueprint $table) {
            foreach (['product_name','product_price','product_image','product_unit','product_description','product_quantity'] as $col) {
                if (Schema::hasColumn('order_items', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
