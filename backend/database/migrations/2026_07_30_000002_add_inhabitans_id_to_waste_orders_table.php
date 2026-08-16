<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('waste_orders', function (Blueprint $table) {
            $table->foreignId('inhabitans_id')->nullable()->constrained('users')->nullOnDelete()->after('farmer_id');
        });
    }

    public function down(): void
    {
        Schema::table('waste_orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('inhabitans_id');
        });
    }
};
