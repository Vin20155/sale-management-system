-- ================================================================
-- ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត (Mart Sales Management System - Cambodia)
-- Database: mart_db (MySQL)
-- Currency: Dual Currency (USD & KHR, Exchange Rate default: 4,100 KHR / USD)
-- ================================================================

CREATE DATABASE IF NOT EXISTS `mart_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `mart_db`;

-- 1. Users Table (បុគ្គលិក / បេឡាករ / អ្នកគ្រប់គ្រង)
CREATE TABLE IF NOT EXISTS `users` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(191) NOT NULL,
  `name_kh` VARCHAR(191) NULL,
  `username` VARCHAR(100) NOT NULL UNIQUE,
  `email` VARCHAR(191) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('admin', 'manager', 'cashier') DEFAULT 'cashier',
  `phone` VARCHAR(50) NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Categories Table (ប្រភេទទំនិញម៉ាត)
CREATE TABLE IF NOT EXISTS `categories` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name_en` VARCHAR(150) NOT NULL,
  `name_kh` VARCHAR(150) NOT NULL,
  `code` VARCHAR(50) UNIQUE,
  `icon` VARCHAR(50) DEFAULT 'category',
  `color_hex` VARCHAR(20) DEFAULT '#00B4D8',
  `description` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Products Table (ទំនិញក្នុងម៉ាត)
CREATE TABLE IF NOT EXISTS `products` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `barcode` VARCHAR(100) NOT NULL UNIQUE,
  `name_en` VARCHAR(200) NOT NULL,
  `name_kh` VARCHAR(200) NOT NULL,
  `category_id` BIGINT UNSIGNED NOT NULL,
  `unit` VARCHAR(50) DEFAULT 'កំប៉ុង', -- កំប៉ុង, ដប, កញ្ចប់, កេស, គីឡូ, ប្រអប់
  `cost_price_usd` DECIMAL(10, 4) NOT NULL DEFAULT 0.0000,
  `cost_price_khr` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `selling_price_usd` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `selling_price_khr` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `stock_quantity` INT NOT NULL DEFAULT 0,
  `reorder_level` INT NOT NULL DEFAULT 10,
  `expiry_date` DATE NULL,
  `image_url` VARCHAR(255) NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Customers Table (អតិថិជន & ពិន្ទុសន្សំម៉ាត)
CREATE TABLE IF NOT EXISTS `customers` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(150) NOT NULL,
  `phone` VARCHAR(50) NOT NULL UNIQUE,
  `points` INT DEFAULT 0,
  `total_spent_usd` DECIMAL(12, 2) DEFAULT 0.00,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Shifts Table (វេនការងារ និងប្រអប់លុយបេឡាករ)
CREATE TABLE IF NOT EXISTS `shifts` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `cashier_id` BIGINT UNSIGNED NOT NULL,
  `opening_cash_usd` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `opening_cash_khr` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `closing_cash_usd` DECIMAL(10, 2) NULL,
  `closing_cash_khr` DECIMAL(12, 2) NULL,
  `total_sales_usd` DECIMAL(12, 2) DEFAULT 0.00,
  `total_sales_khr` DECIMAL(14, 2) DEFAULT 0.00,
  `total_orders_count` INT DEFAULT 0,
  `status` ENUM('open', 'closed') DEFAULT 'open',
  `opened_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `closed_at` TIMESTAMP NULL,
  `note` TEXT NULL,
  CONSTRAINT `fk_shifts_cashier` FOREIGN KEY (`cashier_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Orders / Sales Table (ការលក់ / វិក្កយបត្រ)
CREATE TABLE IF NOT EXISTS `orders` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `invoice_no` VARCHAR(100) NOT NULL UNIQUE,
  `shift_id` BIGINT UNSIGNED NULL,
  `cashier_id` BIGINT UNSIGNED NOT NULL,
  `customer_id` BIGINT UNSIGNED NULL,
  `subtotal_usd` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `discount_usd` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `tax_usd` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `total_usd` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `total_khr` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `exchange_rate` DECIMAL(8, 2) NOT NULL DEFAULT 4100.00,
  `payment_method` ENUM('cash_usd', 'cash_khr', 'mixed_cash', 'khqr_bakong') NOT NULL DEFAULT 'cash_usd',
  `received_usd` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `received_khr` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `change_usd` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `change_khr` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `points_earned` INT DEFAULT 0,
  `status` ENUM('completed', 'refunded', 'cancelled') DEFAULT 'completed',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_orders_cashier` FOREIGN KEY (`cashier_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_orders_shift` FOREIGN KEY (`shift_id`) REFERENCES `shifts` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Order Items Table (ទំនិញក្នុងវិក្កយបត្រ)
CREATE TABLE IF NOT EXISTS `order_items` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `product_name` VARCHAR(200) NOT NULL,
  `barcode` VARCHAR(100) NULL,
  `unit_price_usd` DECIMAL(10, 2) NOT NULL,
  `unit_price_khr` DECIMAL(12, 2) NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `discount_usd` DECIMAL(10, 2) DEFAULT 0.00,
  `subtotal_usd` DECIMAL(10, 2) NOT NULL,
  `subtotal_khr` DECIMAL(12, 2) NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Settings Table (ការកំណត់ទូទៅរបស់ម៉ាត)
CREATE TABLE IF NOT EXISTS `settings` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `mart_name_en` VARCHAR(150) NOT NULL DEFAULT 'Lucky Express Mart',
  `mart_name_kh` VARCHAR(150) NOT NULL DEFAULT 'ឡាក់គី អិចប្រេស ម៉ាត',
  `branch_name` VARCHAR(150) NOT NULL DEFAULT 'សាខាទួលគោក, ភ្នំពេញ',
  `phone` VARCHAR(100) DEFAULT '012 345 678 / 098 765 432',
  `address_kh` TEXT NULL,
  `exchange_rate` DECIMAL(8, 2) DEFAULT 4100.00,
  `tax_percentage` DECIMAL(5, 2) DEFAULT 0.00,
  `bakong_account_id` VARCHAR(100) DEFAULT 'mart_bakong@aclb',
  `bakong_merchant_name` VARCHAR(150) DEFAULT 'LUCKY EXPRESS MART',
  `receipt_footer_kh` VARCHAR(255) DEFAULT 'សូមអរគុណ! សូមអញ្ជើញមកម្តងទៀត',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================
-- SAMPLE DATA (ទិន្នន័យគំរូជាក់ស្តែងសម្រាប់ម៉ាតនៅកម្ពុជា)
-- ================================================================

-- Default Admin & Cashier User (password is 'password' hashed with bcrypt)
INSERT INTO `users` (`id`, `name`, `name_kh`, `username`, `email`, `password`, `role`, `phone`) VALUES
(1, 'Sokha Mean', 'សោភា មាន', 'admin', 'admin@mart.com.kh', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', '012888999'),
(2, 'Dara Chan', 'តារា ចាន់', 'cashier1', 'cashier@mart.com.kh', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cashier', '098111222');

-- Categories in Cambodian Mart
INSERT INTO `categories` (`id`, `name_en`, `name_kh`, `code`, `icon`, `color_hex`, `description`) VALUES
(1, 'Beverages & Drinks', 'ភេសជ្ជៈ & ទឹក', 'BEV', 'local_drink', '#0284C7', 'ទឹកសុទ្ធ, ភេសជ្ជៈប៉ូវកម្លាំង, ទឹកផ្លែឈើ, ស្រាបៀរ'),
(2, 'Snacks & Confectionery', 'នំចំណី & ស្ករគ្រាប់', 'SNK', 'fastfood', '#F59E0B', 'ដំឡូងបារាំងបំពង, នំស្រួយ, ស្ករសូកូឡា, គ្រាប់ធញ្ញជាតិ'),
(3, 'Dairy & Ice Cream', 'ផលិតផលទឹកដោះគោ & ការ៉េម', 'DRY', 'icecream', '#10B981', 'ទឹកដោះគោស្រស់, យ៉ាអួ, ប័រ, ការ៉េម'),
(4, 'Instant & Canned Food', 'អាហារកំប៉ុង & មីកញ្ចប់', 'CND', 'lunch_dining', '#EF4444', 'មីកញ្ចប់, ត្រីខកំប៉ុង, សាច់ក្រក, អាហាររហ័ស'),
(5, 'Bakery & Fresh', 'នំប៉័ង & អាហារស្រស់', 'BKR', 'bakery_dining', '#8B5CF6', 'នំប៉័ងសាំងវិច, នំផ្អែម, ស៊ុតមាន់, ផ្លែឈើ'),
(6, 'Personal Care', 'សម្ភារៈថែរក្សាខ្លួន', 'PRS', 'clean_hands', '#EC4899', 'សាប៊ូកក់សក់, ថ្នាំដុសធ្មេញ, ក្រដាសអនាម័យ'),
(7, 'Household & Cleaning', 'របស់របរប្រើប្រាស់ក្នុងផ្ទះ', 'HSH', 'home', '#64748B', 'សាប៊ូបោកខោអាវ, ទឹកលាងចាន, ថង់សំរាម');

-- Realistic Products in Cambodian Minimarts
INSERT INTO `products` (`id`, `barcode`, `name_en`, `name_kh`, `category_id`, `unit`, `cost_price_usd`, `cost_price_khr`, `selling_price_usd`, `selling_price_khr`, `stock_quantity`, `reorder_level`, `expiry_date`, `image_url`) VALUES
(1, '8850124001111', 'Vital Mineral Water 500ml', 'ទឹកបរិសុទ្ធ វីតាល់ 500ml', 1, 'ដប', 0.20, 820.00, 0.35, 1400.00, 145, 20, '2027-05-15', 'vital_water.png'),
(2, '8850124002222', 'Angkor Beer Can 330ml', 'ស្រាបៀរ អង្គរ កំប៉ុង 330ml', 1, 'កំប៉ុង', 0.55, 2250.00, 0.75, 3100.00, 88, 24, '2026-12-30', 'angkor_beer.png'),
(3, '8850124003333', 'Carabao Energy Drink 250ml', 'ភេសជ្ជៈ ខារ៉ាបាវ 250ml', 1, 'កំប៉ុង', 0.40, 1640.00, 0.60, 2500.00, 64, 15, '2027-01-20', 'carabao.png'),
(4, '8850124004444', 'Sting Energy Drink Strawberry 330ml', 'ស្ទីង រសជាតិស្ត្របឺរី 330ml', 1, 'ដប', 0.45, 1845.00, 0.65, 2700.00, 92, 20, '2026-11-10', 'sting.png'),
(5, '8850124005555', 'Lays Potato Chips Classic 50g', 'ដំឡូងបារាំងបំពង Lays 50g', 2, 'កញ្ចប់', 0.70, 2870.00, 1.00, 4100.00, 40, 10, '2026-08-30', 'lays.png'),
(6, '8850124006666', 'Kirirom Dried Mango 100g', 'ដំណាប់ស្វាយ គិរីរម្យ 100g', 2, 'កញ្ចប់', 1.20, 4920.00, 1.75, 7200.00, 32, 10, '2026-10-15', 'kirirom_mango.png'),
(7, '8850124007777', 'Dutch Mill Fresh Milk 180ml', 'ទឹកដោះគោស្រស់ Dutch Mill 180ml', 3, 'ប្រអប់', 0.40, 1640.00, 0.60, 2500.00, 50, 12, '2026-06-25', 'dutch_mill.png'),
(8, '8850124008888', 'Mama Instant Noodle Pork 60g', 'មីម៉ាម៉ា រសជាតិសាច់ជ្រូកចិញ្ច្រាំ', 4, 'កញ្ចប់', 0.22, 900.00, 0.35, 1400.00, 210, 30, '2027-03-01', 'mama_noodle.png'),
(9, '8850124009999', 'Three Lady Canned Sardines 155g', 'ត្រីខកំប៉ុង ស្រីបីនាក់ 155g', 4, 'កំប៉ុង', 0.75, 3075.00, 1.10, 4500.00, 75, 15, '2027-09-10', 'canned_sardines.png'),
(10, '8850124010101', 'Tous Les Jours Sandwich Bread', 'នំប៉័ងសាំងវិចទន់ ពិសេស', 5, 'កញ្ចប់', 1.00, 4100.00, 1.50, 6150.00, 18, 5, '2026-05-02', 'sandwich_bread.png'),
(11, '8850124011112', 'Colgate Total Toothpaste 150g', 'ថ្នាំដុសធ្មេញ កូលហ្គេត 150g', 6, 'ប្រអប់', 1.30, 5330.00, 1.85, 7600.00, 28, 8, '2028-01-01', 'colgate.png'),
(12, '8850124012123', 'Sunlight Dishwashing Liquid 750ml', 'ទឹកលាងចាន សាន់ឡាយ 750ml', 7, 'ដប', 1.10, 4510.00, 1.60, 6500.00, 35, 10, '2028-06-01', 'sunlight.png');

-- Sample Customers
INSERT INTO `customers` (`id`, `name`, `phone`, `points`, `total_spent_usd`) VALUES
(1, 'Chea Vichea', '012987654', 125, 125.00),
(2, 'Sreyroth Keo', '098456123', 68, 68.50),
(3, 'Bora Heng', '088776655', 210, 210.00);

-- Settings record
INSERT INTO `settings` (`id`, `mart_name_en`, `mart_name_kh`, `branch_name`, `phone`, `address_kh`, `exchange_rate`, `tax_percentage`, `bakong_account_id`, `bakong_merchant_name`, `receipt_footer_kh`) VALUES
(1, 'Lucky Express Mart', 'ឡាក់គី អិចប្រេស ម៉ាត', 'សាខាទួលគោក, ភ្នំពេញ', '012 345 678 / 098 765 432', 'ផ្ទះលេខ 45A, ផ្លូវ 315, សង្កាត់បឹងកក់២, ខណ្ឌទួលគោក, រាជធានីភ្នំពេញ', 4100.00, 0.00, 'lucky_express@aclb', 'LUCKY EXPRESS MART CAMBODIA', 'ទំនិញដែលទិញរួចមិនអាចប្តូរប្រាក់វិញបានទេ! សូមអរគុណ!');
