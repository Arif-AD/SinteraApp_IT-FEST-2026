<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('delivery_tasks', 'waste_id')) {
            Schema::table('delivery_tasks', function (Blueprint $table) {
                $table->foreignId('waste_id')->nullable()->after('order_id')->constrained('wastes')->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('delivery_tasks', 'waste_id')) {
            Schema::table('delivery_tasks', function (Blueprint $table) {
                $table->dropConstrainedForeignId('waste_id');
            });
        }
    }
};
