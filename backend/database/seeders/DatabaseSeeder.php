<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use App\Models\User;
use App\Models\Category;
use App\Models\Product;
use App\Models\Customer;
use App\Models\Setting;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Ensure users.role column can store 'stock_controller'
        try {
            DB::statement("ALTER TABLE users MODIFY COLUMN role VARCHAR(50) NOT NULL DEFAULT 'cashier'");
        } catch (\Throwable $e) {
            // Ignore if already altered or not supported
        }

        // 1. Users (Admin, Cashier, Stock Controller)
        $usersToSeed = [
            [
                'username' => 'admin',
                'name' => 'Ngam Vin (Admin)',
                'name_kh' => 'ង៉ាម​ ​វីន (Admin)',
                'email' => 'admin@gmail.com',
                'password' => Hash::make('123456'),
                'role' => 'admin',
                'phone' => '012888999',
                'is_active' => true,
            ],
            [
                'username' => 'cashier',
                'name' => 'Cashier',
                'name_kh' => 'អ្នកគិតលុយ (Cashier)',
                'email' => 'cashier@gmail.com',
                'password' => Hash::make('123456'),
                'role' => 'cashier',
                'phone' => '098111222',
                'is_active' => true,
            ],
            [
                'username' => 'stock',
                'name' => 'Vin (Stock Controller)',
                'name_kh' => 'វីន (Stock Controller)',
                'email' => 'stock@gmail.com',
                'password' => Hash::make('123456'),
                'role' => 'stock_controller',
                'phone' => '097333444',
                'is_active' => true,
            ],
        ];

        foreach ($usersToSeed as $userData) {
            $existing = User::where('username', $userData['username'])
                ->orWhere('email', $userData['email'])
                ->first();

            if ($existing) {
                $existing->update($userData);
            } else {
                User::create($userData);
            }
        }

        // 2. Settings
        Setting::firstOrCreate(
            ['id' => 1],
            [
                'mart_name_en' => 'Lucky Express Mart',
                'mart_name_kh' => 'ឡាក់គី អិចប្រេស ម៉ាត',
                'branch_name' => 'សាខាទួលគោក, ភ្នំពេញ',
                'phone' => '012 345 678 / 098 765 432',
                'address_kh' => 'ផ្ទះលេខ 45A, ផ្លូវ 315, សង្កាត់បឹងកក់២, ខណ្ឌទួលគោក, រាជធានីភ្នំពេញ',
                'exchange_rate' => 4100.00,
                'tax_percentage' => 0.00,
                'bakong_account_id' => 'lucky_express@aclb',
                'bakong_merchant_name' => 'LUCKY EXPRESS MART CAMBODIA',
                'receipt_footer_kh' => 'ទំនិញដែលទិញរួចមិនអាចប្តូរប្រាក់វិញបានទេ! សូមអរគុណ!',
            ]
        );

        // 3. Categories
        $categories = [
            ['id' => 1, 'name_en' => 'Beverages & Drinks', 'name_kh' => 'ភេសជ្ជៈ & ទឹក', 'code' => 'BEV', 'icon' => 'local_drink', 'color_hex' => '#0284C7', 'description' => 'ទឹកសុទ្ធ, ភេសជ្ជៈប៉ូវកម្លាំង, ទឹកផ្លែឈើ, ស្រាបៀរ'],
            ['id' => 2, 'name_en' => 'Snacks & Confectionery', 'name_kh' => 'នំចំណី & ស្ករគ្រាប់', 'code' => 'SNK', 'icon' => 'fastfood', 'color_hex' => '#F59E0B', 'description' => 'ដំឡូងបារាំងបំពង, នំស្រួយ, ស្ករសូកូឡា, គ្រាប់ធញ្ញជាតិ'],
            ['id' => 3, 'name_en' => 'Dairy & Ice Cream', 'name_kh' => 'ផលិតផលទឹកដោះគោ & ការ៉េម', 'code' => 'DRY', 'icon' => 'icecream', 'color_hex' => '#10B981', 'description' => 'ទឹកដោះគោស្រស់, យ៉ាអួ, ប័រ, ការ៉េម'],
            ['id' => 4, 'name_en' => 'Instant & Canned Food', 'name_kh' => 'អាហារកំប៉ុង & មីកញ្ចប់', 'code' => 'CND', 'icon' => 'lunch_dining', 'color_hex' => '#EF4444', 'description' => 'មីកញ្ចប់, ត្រីខកំប៉ុង, សាច់ក្រក, អាហាររហ័ស'],
            ['id' => 5, 'name_en' => 'Bakery & Fresh', 'name_kh' => 'នំប៉័ង & អាហារស្រស់', 'code' => 'BKR', 'icon' => 'bakery_dining', 'color_hex' => '#8B5CF6', 'description' => 'នំប៉័ងសាំងវិច, នំផ្អែម, ស៊ុតមាន់, ផ្លែឈើ'],
            ['id' => 6, 'name_en' => 'Personal Care', 'name_kh' => 'សម្ភារៈថែរក្សាខ្លួន', 'code' => 'PRS', 'icon' => 'clean_hands', 'color_hex' => '#EC4899', 'description' => 'សាប៊ូកក់សក់, ថ្នាំដុសធ្មេញ, ក្រដាសអនាម័យ'],
            ['id' => 7, 'name_en' => 'Household & Cleaning', 'name_kh' => 'របស់របរប្រើប្រាស់ក្នុងផ្ទះ', 'code' => 'HSH', 'icon' => 'home', 'color_hex' => '#64748B', 'description' => 'សាប៊ូបោកខោអាវ, ទឹកលាងចាន, ថង់សំរាម'],
        ];

        foreach ($categories as $cat) {
            Category::updateOrCreate(['id' => $cat['id']], $cat);
        }

        // 4. Products in Cambodian Mart
        $products = [
            [
                'barcode' => '8850124001111',
                'name_en' => 'Vital Mineral Water 500ml',
                'name_kh' => 'ទឹកបរិសុទ្ធ វីតាល់ 500ml',
                'category_id' => 1,
                'unit' => 'ដប',
                'cost_price_usd' => 0.20,
                'cost_price_khr' => 820.00,
                'selling_price_usd' => 0.35,
                'selling_price_khr' => 1400.00,
                'stock_quantity' => 145,
                'reorder_level' => 20,
                'expiry_date' => '2027-05-15',
            ],
            [
                'barcode' => '8850124002222',
                'name_en' => 'Angkor Beer Can 330ml',
                'name_kh' => 'ស្រាបៀរ អង្គរ កំប៉ុង 330ml',
                'category_id' => 1,
                'unit' => 'កំប៉ុង',
                'cost_price_usd' => 0.55,
                'cost_price_khr' => 2250.00,
                'selling_price_usd' => 0.75,
                'selling_price_khr' => 3100.00,
                'stock_quantity' => 8,
                'reorder_level' => 24,
                'expiry_date' => '2026-12-30',
            ],
            [
                'barcode' => '8850124003333',
                'name_en' => 'Carabao Energy Drink 250ml',
                'name_kh' => 'ភេសជ្ជៈ ខារ៉ាបាវ 250ml',
                'category_id' => 1,
                'unit' => 'កំប៉ុង',
                'cost_price_usd' => 0.40,
                'cost_price_khr' => 1640.00,
                'selling_price_usd' => 0.60,
                'selling_price_khr' => 2500.00,
                'stock_quantity' => 64,
                'reorder_level' => 15,
                'expiry_date' => '2027-01-20',
            ],
            [
                'barcode' => '8850124004444',
                'name_en' => 'Sting Energy Strawberry 330ml',
                'name_kh' => 'ស្ទីង រសជាតិស្ត្របឺរី 330ml',
                'category_id' => 1,
                'unit' => 'ដប',
                'cost_price_usd' => 0.45,
                'cost_price_khr' => 1845.00,
                'selling_price_usd' => 0.65,
                'selling_price_khr' => 2700.00,
                'stock_quantity' => 92,
                'reorder_level' => 20,
                'expiry_date' => '2026-11-10',
            ],
            [
                'barcode' => '8850124005555',
                'name_en' => 'Lays Potato Chips Classic 50g',
                'name_kh' => 'ដំឡូងបារាំងបំពង Lays 50g',
                'category_id' => 2,
                'unit' => 'កញ្ចប់',
                'cost_price_usd' => 0.70,
                'cost_price_khr' => 2870.00,
                'selling_price_usd' => 1.00,
                'selling_price_khr' => 4100.00,
                'stock_quantity' => 40,
                'reorder_level' => 10,
                'expiry_date' => '2026-08-30',
            ],
            [
                'barcode' => '8850124006666',
                'name_en' => 'Kirirom Dried Mango 100g',
                'name_kh' => 'ដំណាប់ស្វាយ គិរីរម្យ 100g',
                'category_id' => 2,
                'unit' => 'កញ្ចប់',
                'cost_price_usd' => 1.20,
                'cost_price_khr' => 4920.00,
                'selling_price_usd' => 1.75,
                'selling_price_khr' => 7200.00,
                'stock_quantity' => 32,
                'reorder_level' => 10,
                'expiry_date' => '2026-10-15',
            ],
            [
                'barcode' => '8850124007777',
                'name_en' => 'Dutch Mill Fresh Milk 180ml',
                'name_kh' => 'ទឹកដោះគោស្រស់ Dutch Mill 180ml',
                'category_id' => 3,
                'unit' => 'ប្រអប់',
                'cost_price_usd' => 0.40,
                'cost_price_khr' => 1640.00,
                'selling_price_usd' => 0.60,
                'selling_price_khr' => 2500.00,
                'stock_quantity' => 50,
                'reorder_level' => 12,
                'expiry_date' => '2026-06-25',
            ],
            [
                'barcode' => '8850124008888',
                'name_en' => 'Mama Instant Noodle Pork 60g',
                'name_kh' => 'មីម៉ាម៉ា រសជាតិសាច់ជ្រូកចិញ្ច្រាំ',
                'category_id' => 4,
                'unit' => 'កញ្ចប់',
                'cost_price_usd' => 0.22,
                'cost_price_khr' => 900.00,
                'selling_price_usd' => 0.35,
                'selling_price_khr' => 1400.00,
                'stock_quantity' => 210,
                'reorder_level' => 30,
                'expiry_date' => '2027-03-01',
            ],
            [
                'barcode' => '8850124009999',
                'name_en' => 'Three Lady Canned Sardines 155g',
                'name_kh' => 'ត្រីខកំប៉ុង ស្រីបីនាក់ 155g',
                'category_id' => 4,
                'unit' => 'កំប៉ុង',
                'cost_price_usd' => 0.75,
                'cost_price_khr' => 3075.00,
                'selling_price_usd' => 1.10,
                'selling_price_khr' => 4500.00,
                'stock_quantity' => 75,
                'reorder_level' => 15,
                'expiry_date' => '2027-09-10',
            ],
            [
                'barcode' => '8850124010101',
                'name_en' => 'Tous Les Jours Sandwich Bread',
                'name_kh' => 'នំប៉័ងសាំងវិចទន់ ពិសេស',
                'category_id' => 5,
                'unit' => 'កញ្ចប់',
                'cost_price_usd' => 1.00,
                'cost_price_khr' => 4100.00,
                'selling_price_usd' => 1.50,
                'selling_price_khr' => 6150.00,
                'stock_quantity' => 18,
                'reorder_level' => 5,
                'expiry_date' => '2026-05-02',
            ],
        ];

        foreach ($products as $prod) {
            Product::updateOrCreate(['barcode' => $prod['barcode']], $prod);
        }

        // 5. Customers
        Customer::updateOrCreate(
            ['phone' => '012987654'],
            ['name' => 'Chea Vichea', 'points' => 125, 'total_spent_usd' => 125.00]
        );
        Customer::updateOrCreate(
            ['phone' => '098456123'],
            ['name' => 'Sreyroth Keo', 'points' => 68, 'total_spent_usd' => 68.50]
        );
        Customer::updateOrCreate(
            ['phone' => '088776655'],
            ['name' => 'Bora Heng', 'points' => 210, 'total_spent_usd' => 210.00]
        );
    }
}
