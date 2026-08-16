<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('products', 'harvest_date')) {
            Schema::table('products', function (Blueprint $table) {
                $table->dropColumn('harvest_date');
            });
        }
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->date('harvest_date')->nullable();
        });
    }
};
