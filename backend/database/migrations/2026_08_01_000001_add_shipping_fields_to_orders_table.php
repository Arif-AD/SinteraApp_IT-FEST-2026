<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $columns = [
            'base_fee' => fn (Blueprint $table) => $table->decimal('base_fee', 12, 2)->default(0),
            'distance_fee' => fn (Blueprint $table) => $table->decimal('distance_fee', 12, 2)->default(0),
            'total_shipping' => fn (Blueprint $table) => $table->decimal('total_shipping', 12, 2)->default(0),
            'farmer_subsidy' => fn (Blueprint $table) => $table->decimal('farmer_subsidy', 12, 2)->default(0),
            'customer_shipping' => fn (Blueprint $table) => $table->decimal('customer_shipping', 12, 2)->default(0),
            'shipping_distance_km' => fn (Blueprint $table) => $table->decimal('shipping_distance_km', 8, 2)->default(0),
            'shipping_note' => fn (Blueprint $table) => $table->text('shipping_note')->nullable(),
        ];

        foreach ($columns as $column => $definition) {
            if (!Schema::hasColumn('orders', $column)) {
                Schema::table('orders', $definition);
            }
        }

        if (Schema::hasColumn('orders', 'discount_amount')) {
            if (!Schema::hasColumn('orders', 'subsidy')) {
                Schema::table('orders', function (Blueprint $table): void {
                    $table->decimal('subsidy', 12, 2)->default(0)->after('final_amount');
                });
            }

            DB::statement('UPDATE orders SET subsidy = COALESCE(discount_amount, 0) WHERE subsidy IS NULL OR subsidy = 0');
            Schema::table('orders', function (Blueprint $table): void {
                $table->dropColumn('discount_amount');
            });
        } elseif (!Schema::hasColumn('orders', 'subsidy')) {
            Schema::table('orders', function (Blueprint $table): void {
                $table->decimal('subsidy', 12, 2)->default(0)->after('final_amount');
            });
        }
    }

    public function down(): void
    {
        $columns = [
            'base_fee',
            'distance_fee',
            'total_shipping',
            'farmer_subsidy',
            'customer_shipping',
            'shipping_distance_km',
            'shipping_note',
        ];

        foreach ($columns as $column) {
            if (Schema::hasColumn('orders', $column)) {
                Schema::table('orders', function (Blueprint $table) use ($column): void {
                    $table->dropColumn($column);
                });
            }
        }
    }
};
