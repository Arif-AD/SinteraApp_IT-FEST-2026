<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('delivery_tasks', 'waste_pickup_id')) {
            DB::statement('ALTER TABLE "delivery_tasks" DROP COLUMN IF EXISTS "waste_pickup_id" CASCADE');
        }
    }

    public function down(): void
    {
        if (!Schema::hasColumn('delivery_tasks', 'waste_pickup_id')) {
            Schema::table('delivery_tasks', function (Blueprint $table) {
                $table->foreignId('waste_pickup_id')->nullable()->after('waste_id')->constrained()->nullOnDelete();
            });
        }
    }
};
