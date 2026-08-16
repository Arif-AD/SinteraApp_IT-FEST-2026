<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE delivery_tasks DROP CONSTRAINT IF EXISTS delivery_tasks_status_check");
            DB::statement("ALTER TABLE delivery_tasks ADD CONSTRAINT delivery_tasks_status_check CHECK (status IN ('pending', 'assigned', 'accepted', 'picked_up', 'in_transit', 'delivered', 'cancelled'))");
            return;
        }

        DB::statement("UPDATE delivery_tasks SET status = 'pending' WHERE status = 'accepted'");
    }

    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE delivery_tasks DROP CONSTRAINT IF EXISTS delivery_tasks_status_check");
            DB::statement("ALTER TABLE delivery_tasks ADD CONSTRAINT delivery_tasks_status_check CHECK (status IN ('pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'cancelled'))");
            return;
        }

        DB::statement("UPDATE delivery_tasks SET status = 'pending' WHERE status = 'accepted'");
    }
};
