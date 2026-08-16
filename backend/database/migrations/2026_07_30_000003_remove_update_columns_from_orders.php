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
            if (Schema::hasColumn('orders', 'update_at')) {
                $table->dropColumn('update_at');
            }

            if (Schema::hasColumn('orders', 'update_by')) {
                $table->dropColumn('update_by');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'update_at')) {
                $table->timestamp('update_at')->nullable()->after('updated_at');
            }

            if (!Schema::hasColumn('orders', 'update_by')) {
                $table->unsignedBigInteger('update_by')->nullable()->after('update_at');
            }
        });
    }
};
