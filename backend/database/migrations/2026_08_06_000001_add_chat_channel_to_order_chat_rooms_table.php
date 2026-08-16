<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('order_chat_rooms', function (Blueprint $table) {
            if (!Schema::hasColumn('order_chat_rooms', 'chat_channel')) {
                $table->enum('chat_channel', ['warga_petani', 'warga_pengantar', 'petani_pengantar'])
                    ->nullable()
                    ->after('order_id');
                $table->index('chat_channel');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('order_chat_rooms', function (Blueprint $table) {
            if (Schema::hasColumn('order_chat_rooms', 'chat_channel')) {
                $table->dropIndex(['chat_channel']);
                $table->dropColumn('chat_channel');
            }
        });
    }
};
