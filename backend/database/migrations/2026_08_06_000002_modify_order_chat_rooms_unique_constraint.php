<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::transaction(function () {
            if (Schema::hasColumn('order_chat_rooms', 'chat_channel')) {
                DB::table('order_chat_rooms')
                    ->whereNull('chat_channel')
                    ->update(['chat_channel' => 'warga_petani']);
            }

            Schema::table('order_chat_rooms', function (Blueprint $table) {
                if (Schema::hasColumn('order_chat_rooms', 'order_type') && Schema::hasColumn('order_chat_rooms', 'order_id')) {
                    $table->dropUnique(['order_type', 'order_id']);
                }

                $table->unique(['order_type', 'order_id', 'chat_channel'], 'order_chat_rooms_order_type_order_id_chat_channel_unique');
            });
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('order_chat_rooms', function (Blueprint $table) {
            if (Schema::hasColumn('order_chat_rooms', 'order_type') && Schema::hasColumn('order_chat_rooms', 'order_id')) {
                $table->dropUnique('order_chat_rooms_order_type_order_id_chat_channel_unique');
                $table->unique(['order_type', 'order_id'], 'order_chat_rooms_order_type_order_id_unique');
            }
        });
    }
};
