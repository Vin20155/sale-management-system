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
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('barcode', 100)->unique();
            $table->string('name_en', 200);
            $table->string('name_kh', 200);
            $table->foreignId('category_id')->constrained('categories')->onDelete('cascade');
            $table->string('unit', 50)->default('កំប៉ុង');
            $table->decimal('cost_price_usd', 10, 4)->default(0.0000);
            $table->decimal('cost_price_khr', 12, 2)->default(0.00);
            $table->decimal('selling_price_usd', 10, 2)->default(0.00);
            $table->decimal('selling_price_khr', 12, 2)->default(0.00);
            $table->integer('stock_quantity')->default(0);
            $table->integer('reorder_level')->default(10);
            $table->date('expiry_date')->nullable();
            $table->string('image_url')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
