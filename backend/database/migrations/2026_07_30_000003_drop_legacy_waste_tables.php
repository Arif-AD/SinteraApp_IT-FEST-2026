<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // This migration previously removed legacy waste tables.
        // The current application still relies on waste_categories, waste_pickups,
        // and related tables, so this migration is preserved as a no-op.
    }

    public function down(): void
    {
        // Legacy waste tables are intentionally removed from the new architecture.
    }
};
