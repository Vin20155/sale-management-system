<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        try {
            DB::statement("ALTER TABLE users MODIFY COLUMN role VARCHAR(50) NOT NULL DEFAULT 'cashier'");
        } catch (\Throwable $e) {
            // In case driver doesn't support or already altered
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
    }
};
