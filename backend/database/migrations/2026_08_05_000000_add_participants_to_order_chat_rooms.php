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
            if (!Schema::hasColumn('order_chat_rooms', 'participant_a_id')) {
                $table->unsignedBigInteger('participant_a_id')->nullable()->after('order_id');
            }
            if (!Schema::hasColumn('order_chat_rooms', 'participant_b_id')) {
                $table->unsignedBigInteger('participant_b_id')->nullable()->after('participant_a_id');
            }
            if (!Schema::hasColumn('order_chat_rooms', 'chat_channel')) {
                $table->enum('chat_channel', ['warga_petani', 'warga_pengantar', 'petani_pengantar'])->nullable()->after('order_id');
            }
            if (!Schema::hasIndex('order_chat_rooms', 'order_chat_rooms_participants_chat_channel_unique')) {
                $table->unique(['participant_a_id', 'participant_b_id', 'chat_channel'], 'order_chat_rooms_participants_chat_channel_unique');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('order_chat_rooms', function (Blueprint $table) {
            if (Schema::hasIndex('order_chat_rooms', 'order_chat_rooms_participants_chat_channel_unique')) {
                $table->dropUnique('order_chat_rooms_participants_chat_channel_unique');
            }
            if (Schema::hasColumn('order_chat_rooms', 'participant_a_id')) {
                $table->dropColumn('participant_a_id');
            }
            if (Schema::hasColumn('order_chat_rooms', 'participant_b_id')) {
                $table->dropColumn('participant_b_id');
            }
        });
    }
};
