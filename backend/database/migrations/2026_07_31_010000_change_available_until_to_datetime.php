<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('products') && Schema::hasColumn('products', 'available_until')) {
            Schema::table('products', function (Blueprint $table) {
                // change requires doctrine/dbal installed in the project
                $table->dateTime('available_until')->nullable()->change();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('products')) {
            Schema::table('products', function (Blueprint $table) {
                $table->date('available_until')->nullable()->change();
            });
        }
    }
};
