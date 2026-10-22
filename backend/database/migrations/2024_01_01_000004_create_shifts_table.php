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
        Schema::create('shifts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cashier_id')->constrained('users');
            $table->decimal('opening_cash_usd', 10, 2)->default(0.00);
            $table->decimal('opening_cash_khr', 12, 2)->default(0.00);
            $table->decimal('closing_cash_usd', 10, 2)->nullable();
            $table->decimal('closing_cash_khr', 12, 2)->nullable();
            $table->decimal('total_sales_usd', 12, 2)->default(0.00);
            $table->decimal('total_sales_khr', 14, 2)->default(0.00);
            $table->integer('total_orders_count')->default(0);
            $table->enum('status', ['open', 'closed'])->default('open');
            $table->timestamp('opened_at')->useCurrent();
            $table->timestamp('closed_at')->nullable();
            $table->text('note')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('shifts');
    }
};
