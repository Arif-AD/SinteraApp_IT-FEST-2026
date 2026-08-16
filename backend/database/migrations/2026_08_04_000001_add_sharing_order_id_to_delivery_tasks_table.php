<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('delivery_tasks', 'sharing_order_id')) {
            Schema::table('delivery_tasks', function (Blueprint $table) {
                $table->foreignId('sharing_order_id')->nullable()->after('order_id')->constrained('sharing_orders')->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('delivery_tasks', 'sharing_order_id')) {
            Schema::table('delivery_tasks', function (Blueprint $table) {
                $table->dropConstrainedForeignId('sharing_order_id');
            });
        }
    }
};
