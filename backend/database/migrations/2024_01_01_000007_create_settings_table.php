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
        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('mart_name_en', 150)->default('Lucky Express Mart');
            $table->string('mart_name_kh', 150)->default('ឡាក់គី អិចប្រេស ម៉ាត');
            $table->string('branch_name', 150)->default('សាខាទួលគោក, ភ្នំពេញ');
            $table->string('phone', 100)->default('012 345 678');
            $table->text('address_kh')->nullable();
            $table->decimal('exchange_rate', 8, 2)->default(4100.00);
            $table->decimal('tax_percentage', 5, 2)->default(0.00);
            $table->string('bakong_account_id', 100)->default('lucky_express@aclb');
            $table->string('bakong_merchant_name', 150)->default('LUCKY EXPRESS MART');
            $table->string('receipt_footer_kh', 255)->default('សូមអរគុណ! សូមអញ្ជើញមកម្តងទៀត');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('settings');
    }
};
