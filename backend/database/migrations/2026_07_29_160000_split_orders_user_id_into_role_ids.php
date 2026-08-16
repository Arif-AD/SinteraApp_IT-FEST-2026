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

        if (!Schema::hasColumn('orders', 'inhabitans_id')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->unsignedBigInteger('inhabitans_id')->nullable()->after('id');
                $table->unsignedBigInteger('farmers_id')->nullable()->after('inhabitans_id');
                $table->unsignedBigInteger('delivery_id')->nullable()->after('farmers_id');
            });
        }

        if (Schema::hasColumn('orders', 'user_id') && Schema::hasColumn('orders', 'inhabitans_id')) {
            DB::statement('UPDATE orders SET inhabitans_id = user_id WHERE user_id IS NOT NULL');
        }

        if (DB::getDriverName() !== 'sqlite' && Schema::hasTable('products') && Schema::hasColumn('orders', 'product_id')) {
            DB::statement(<<<'SQL'
                UPDATE orders
                SET farmers_id = p.user_id
                FROM products p
                WHERE orders.product_id = p.id AND p.farmer_id IS NOT NULL;
            SQL
            );
        }

        if (DB::getDriverName() !== 'sqlite' && Schema::hasColumn('orders', 'user_id')) {
            Schema::table('orders', function (Blueprint $table) {
                if (!Schema::hasColumn('orders', 'inhabitans_id')) {
                    return;
                }

                $table->foreign('inhabitans_id')->references('id')->on('users')->onDelete('cascade');
                $table->foreign('farmers_id')->references('id')->on('users')->onDelete('cascade');
                $table->foreign('delivery_id')->references('id')->on('users')->nullOnDelete();
            });
        }

        if (Schema::hasColumn('orders', 'user_id')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropForeign(['user_id']);
                $table->dropIndex(['user_id']);
                $table->dropColumn('user_id');
            });
        }

        if (Schema::hasColumn('orders', 'inhabitans_id')) {
            Schema::table('orders', function (Blueprint $table) {
                if (!Schema::connection($this->getConnection())->hasIndex('orders', 'orders_inhabitans_id_index')) {
                    $table->index('inhabitans_id');
                }
                if (!Schema::connection($this->getConnection())->hasIndex('orders', 'orders_farmers_id_index')) {
                    $table->index('farmers_id');
                }
                if (!Schema::connection($this->getConnection())->hasIndex('orders', 'orders_delivery_id_index')) {
                    $table->index('delivery_id');
                }
            });
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        if (!Schema::hasColumn('orders', 'user_id')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->foreignId('user_id')->nullable()->after('id')->constrained('users')->onDelete('cascade');
            });

            if (Schema::hasColumn('orders', 'inhabitans_id')) {
                DB::statement('UPDATE orders SET user_id = inhabitans_id WHERE inhabitans_id IS NOT NULL');
            }
        }

        Schema::table('orders', function (Blueprint $table) {
            if (DB::getDriverName() !== 'sqlite' && Schema::hasColumn('orders', 'delivery_id')) {
                $table->dropForeign(['delivery_id']);
            }
            if (DB::getDriverName() !== 'sqlite' && Schema::hasColumn('orders', 'farmers_id')) {
                $table->dropForeign(['farmers_id']);
            }
            if (DB::getDriverName() !== 'sqlite' && Schema::hasColumn('orders', 'inhabitans_id')) {
                $table->dropForeign(['inhabitans_id']);
            }
            if (Schema::hasColumn('orders', 'delivery_id')) {
                $table->dropColumn('delivery_id');
            }
            if (Schema::hasColumn('orders', 'farmers_id')) {
                $table->dropColumn('farmers_id');
            }
            if (Schema::hasColumn('orders', 'inhabitans_id')) {
                $table->dropColumn('inhabitans_id');
            }
        });
    }
};
