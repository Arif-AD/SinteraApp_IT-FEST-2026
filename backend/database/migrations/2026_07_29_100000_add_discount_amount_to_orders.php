<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasColumn('orders', 'discount_amount')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->decimal('discount_amount', 15, 2)->default(0)->after('total_amount');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('orders', 'discount_amount')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropColumn('discount_amount');
            });
        }
    }
};
