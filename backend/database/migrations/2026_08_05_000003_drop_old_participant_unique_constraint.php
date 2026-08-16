<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('order_chat_rooms')) {
            return;
        }

        DB::statement(
            'DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conrelid = \'order_chat_rooms\'::regclass
                      AND conname = \'order_chat_rooms_participants_chat_channel_unique\'
                      AND contype = \'u\'
                ) THEN
                    ALTER TABLE order_chat_rooms
                    DROP CONSTRAINT order_chat_rooms_participants_chat_channel_unique;
                END IF;
            END
            $$;'
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (!Schema::hasTable('order_chat_rooms')) {
            return;
        }

        DB::statement(
            'DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conrelid = \'order_chat_rooms\'::regclass
                      AND conname = \'order_chat_rooms_participants_chat_channel_unique\'
                      AND contype = \'u\'
                ) THEN
                    ALTER TABLE order_chat_rooms
                    ADD CONSTRAINT order_chat_rooms_participants_chat_channel_unique
                    UNIQUE (participant_a_id, participant_b_id, chat_channel);
                END IF;
            END
            $$;'
        );
    }
};
