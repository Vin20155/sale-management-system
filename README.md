# ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត (Mart Sales Management System - Cambodia)

ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត ត្រូវបានអភិវឌ្ឍឡើងយ៉ាងពេញលេញស្របទៅតាមតម្រូវការជាក់ស្តែងនៃអាជីវកម្មម៉ាត (Minimart, Supermart, Convenience Store) នៅក្នុងប្រទេសកម្ពុជា។

---

## ស្ថាបត្យកម្មប្រព័ន្ធ (System Architecture)

```
sale-management-system/
├── backend/                       # Laravel REST API (PHP & MySQL)
│   ├── app/
│   │   ├── Http/Controllers/Api/  # Auth, Product, Category, Order, Shift, Khqr, Report, Setting
│   │   └── Models/                # Product, Category, Order, Shift, Customer, Setting, User
│   ├── database/
│   │   └── mart_db.sql            # MySQL Database Dump ពេញលេញ + ទិន្នន័យគំរូម៉ាតកម្ពុជា
│   ├── routes/
│   │   └── api.php                # REST API Endpoints
│   ├── .env.example
│   └── README.md
│
└── my_app/                        # Flutter Application (Android, iOS, Web, Windows)
    ├── lib/
    │   ├── config/
    │   │   └── app_colors.dart    # Theme ពណ៌ម៉ាតបែបទំនើប (Emerald & Navy & Gold)
    │   ├── models/
    │   │   └── mart_models.dart   # Product, Cart, Order, Shift, Category, Customer Models
    │   ├── services/
    │   │   └── mart_service.dart  # Laravel REST API Client + Offline Local Fallback Mode
    │   ├── screens/
    │   │   ├── main_screen.dart   # ផ្ទាំងគ្រប់គ្រងធំ (Mart Dashboard)
    │   │   └── cards/
    │   │       ├── pos_screen.dart       # កន្លែងគិតលុយរហ័ស (POS, Barcode, Cart, Pay)
    │   │       ├── product_screen.dart   # គ្រប់គ្រងទំនិញ (Products, Barcode, Add/Edit)
    │   │       ├── category_screen.dart  # ប្រភេទទំនិញម៉ាត (Categories)
    │   │       ├── stock_screen.dart     # ស្តុក & ទំនិញជិតផុតកំណត់ (Stock & Expiry)
    │   │       ├── invoice_screen.dart   # ប្រវត្តិវិក្កយបត្រ (Sales Invoices & Receipt)
    │   │       ├── shift_screen.dart     # វេនការងារ & ប្រអប់លុយបេឡាករ (Shift Drawer)
    │   │       ├── customer_screen.dart  # អតិថិជន & ពិន្ទុសន្សំ (Customer Loyalty)
    │   │       ├── report_screen.dart    # របាយការណ៍លក់ប្រចាំថ្ងៃ (Daily Analytics)
    │   │       └── setting_screen.dart   # កំណត់អត្រាប្តូរប្រាក់ & ភ្ជាប់ Backend API
    │   ├── menu/
    │   │   └── navigation_menu.dart # ម៉ឺនុយចំហៀង (Mart Navigation Drawer)
    │   └── main.dart
    └── pubspec.yaml
```

---

## លក្ខណៈពិសេសស្របតាមបរិបទម៉ាតនៅកម្ពុជា (Cambodian Mart Features)

1. **ប្រព័ន្ធរូបិយប័ណ្ណពីរ (Dual Currency USD & KHR)**:
   - បង្ហាញតម្លៃទំនិញជាប្រាក់ដុល្លារ ($) និងប្រាក់រៀល (៛) ទន្ទឹមគ្នា
   - គណនាតាមអត្រាប្តូរប្រាក់ជាក់ស្តែង (ឧទាហរណ៍៖ $1 = 4,100 ៛)
   - ទទួលប្រាក់ជាដុល្លារ សុទ្ធ ឬរៀលសុទ្ធ ឬចម្រុះ ($ + ៛) និងគណនាប្រាក់អាប់ជាដុល្លារ និងរៀលដោយស្វ័យប្រវត្តិ
2. **ការទូទាត់ប្រាក់តាម KHQR បាគង (NBC Bakong KHQR)**:
   - បង្កើត QR កូដទូទាត់ស្វ័យប្រវត្តិតាមស្តង់ដារ KHQR របស់ធនាគារជាតិនៃកម្ពុជា
   - អតិថិជនអាចស្កេនទូទាត់តាម Bakong App ឬ Mobile Banking គ្រប់ធនាគារក្នុងស្រុក
3. **កន្លែងគិតលុយរហ័ស (Mart POS Terminal)**:
   - ស្កេន ឬវាយបញ្ចូលបាកូដទំនិញរហ័ស
   - ច្រោះតាមប្រភេទ (ភេសជ្ជៈ, នំចំណី, អាហារកំប៉ុង, ទឹកដោះគោ, របស់ប្រើប្រាស់...)
   - កន្ត្រកទំនិញ, បញ្ចុះតម្លៃ, និងចេញវិក្កយបត្រម៉ាត
4. **ការគ្រប់គ្រងស្តុក & តាមដានថ្ងៃផុតកំណត់ (Stock & Expiry Tracking)**:
   - ជូនដំណឹងទំនិញជិតអស់ពីស្តុក (Low Stock Alert)
   - ជូនដំណឹងទំនិញជិតផុតកំណត់កាលបរិច្ឆេទ (Expiring Date Alert)
   - បញ្ចូលស្តុកបន្ថែមភ្លាមៗ (Restock)
5. **វេនការងារ & ប្រអប់លុយបេឡាករ (Cashier Shift & Drawer)**:
   - បើកវេនការងារដោយបញ្ចូលសាច់ប្រាក់ដើមគ្រា ($ និង ៛)
   - បិទវេន និងរាប់ផ្ទៀងផ្ទាត់សាច់ប្រាក់ចុងគ្រា
6. **អតិថិជន & ពិន្ទុសន្សំ (Customer Loyalty Points)**:
   - ស្វែងរកតាមលេខទូរស័ព្ទ និងសន្ំពិន្ទុពីរាល់ការទិញ ($1 = 1 ពិន្ទុ)
7. **របាយការណ៍លក់ និងវិភាគទិន្នន័យ (Sales Analytics)**:
   - ចំណូលលក់សរុបប្រចាំថ្ងៃ ($ និង ៛)
   - មុខទំនិញលក់ដាច់បំផុត (Top Selling Products)
8. **ដំណើរការដោយរលូនទាំង Online និង Offline (Live REST API & Local Fallback)**:
   - ភ្ជាប់ជាមួយ Laravel REST API ពេលមាន Network/Server
   - ដំណើរការលើ Local Offline Cache ដោយស្វ័យប្រវត្តិ មិនដែលគាំង ឬ error ឡើយ

---

## របៀបដំណើរការ (How to Run)

### ១. ដំណើរការ Laravel Backend & MySQL
1. បើក XAMPP/Laragon Start **MySQL**
2. ចូល phpMyAdmin បង្កើត Database `mart_db`
3. Import ឯកសារ `backend/database/mart_db.sql`
4. ចូលទៅ Folder `backend` រួច Run:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```

### ២. ដំណើរការ Flutter App
ចូលទៅ Folder `my_app` រួច Run:
```bash
flutter run
```
ឬបើកដំណើរការលើ Android Emulator, iOS Simulator, Chrome Web, ឬ Windows Desktop។
