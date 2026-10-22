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
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('invoice_no', 100)->unique();
            $table->foreignId('shift_id')->nullable()->constrained('shifts')->onDelete('set null');
            $table->foreignId('cashier_id')->constrained('users');
            $table->foreignId('customer_id')->nullable()->constrained('customers')->onDelete('set null');
            $table->decimal('subtotal_usd', 10, 2)->default(0.00);
            $table->decimal('discount_usd', 10, 2)->default(0.00);
            $table->decimal('tax_usd', 10, 2)->default(0.00);
            $table->decimal('total_usd', 10, 2)->default(0.00);
            $table->decimal('total_khr', 12, 2)->default(0.00);
            $table->decimal('exchange_rate', 8, 2)->default(4100.00);
            $table->enum('payment_method', ['cash_usd', 'cash_khr', 'mixed_cash', 'khqr_bakong'])->default('cash_usd');
            $table->decimal('received_usd', 10, 2)->default(0.00);
            $table->decimal('received_khr', 12, 2)->default(0.00);
            $table->decimal('change_usd', 10, 2)->default(0.00);
            $table->decimal('change_khr', 12, 2)->default(0.00);
            $table->integer('points_earned')->default(0);
            $table->enum('status', ['completed', 'refunded', 'cancelled'])->default('completed');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
