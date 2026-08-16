<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('users', 'address')) {
            $users = DB::table('users')->whereNotNull('address')->orWhereNotNull('latitude')->orWhereNotNull('longitude')->get();

            foreach ($users as $user) {
                DB::table('user_addresses')->updateOrInsert(
                    ['user_id' => $user->id],
                    [
                        'address' => $user->address,
                        'detail_house' => null,
                        'latitude' => $user->latitude,
                        'longitude' => $user->longitude,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }

            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn(['address', 'latitude', 'longitude']);
            });
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->text('address')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
        });
    }
};
