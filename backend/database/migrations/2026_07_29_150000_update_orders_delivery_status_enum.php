<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        if (DB::getDriverName() === 'sqlite') {
            return;
        }

        DB::statement("ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_delivery_status_check;");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT orders_delivery_status_check CHECK (delivery_status IN ('pending', 'shipped', 'delivered', 'cancelled')); ");
    }

    public function down(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        if (DB::getDriverName() === 'sqlite') {
            return;
        }

        DB::statement("ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_delivery_status_check;");
        DB::statement("ALTER TABLE orders ADD CONSTRAINT orders_delivery_status_check CHECK (delivery_status IN ('pending', 'shipped', 'delivered')); ");
    }
};
