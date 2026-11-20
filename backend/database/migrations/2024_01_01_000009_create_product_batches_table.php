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
        Schema::create('product_batches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('products')->onDelete('cascade');
            $table->string('batch_no', 50)->nullable();
            $table->date('received_date');
            $table->date('expiry_date')->nullable();
            $table->integer('quantity_received')->default(0);
            $table->integer('quantity_remaining')->default(0);
            $table->decimal('cost_price_usd', 10, 4)->default(0.0000);
            $table->decimal('cost_price_khr', 12, 2)->default(0.00);
            $table->string('supplier_name', 150)->nullable();
            $table->string('note', 255)->nullable();
            $table->timestamps();

            $table->index(['product_id', 'expiry_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('product_batches');
    }
};

