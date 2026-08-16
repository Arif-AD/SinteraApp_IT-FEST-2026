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
            // Drop columns if they exist
            if (Schema::hasColumn('orders', 'deleted_at')) {
                $table->dropColumn('deleted_at');
            }
            if (Schema::hasColumn('orders', 'subsidy')) {
                $table->dropColumn('subsidy');
            }
            if (Schema::hasColumn('orders', 'discount_amount')) {
                $table->dropColumn('discount_amount');
            }

            // Add requested columns if they don't exist yet
            if (!Schema::hasColumn('orders', 'update_at')) {
                $table->timestamp('update_at')->nullable()->after('updated_at');
            }
            if (!Schema::hasColumn('orders', 'update_by')) {
                $table->unsignedBigInteger('update_by')->nullable()->after('update_at');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            // Remove added columns if present
            if (Schema::hasColumn('orders', 'update_by')) {
                $table->dropColumn('update_by');
            }
            if (Schema::hasColumn('orders', 'update_at')) {
                $table->dropColumn('update_at');
            }

            // Recreate dropped columns (best-effort defaults)
            if (!Schema::hasColumn('orders', 'discount_amount')) {
                $table->numeric('discount_amount', 12, 2)->default(0)->after('total_amount');
            }
            if (!Schema::hasColumn('orders', 'subsidy')) {
                $table->numeric('subsidy', 12, 2)->default(0)->after('shipping_note');
            }
            if (!Schema::hasColumn('orders', 'deleted_at')) {
                $table->timestamp('deleted_at')->nullable()->after('updated_at');
            }
        });
    }
};
