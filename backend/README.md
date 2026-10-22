# ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត (Mart Sales Management System) - Backend API

ប្រព័ន្ធ Backend នេះបង្កើតឡើងដោយប្រើប្រាស់ **Laravel REST API** និង **MySQL Database** សម្រាប់ផ្គត់ផ្គង់ទិន្នន័យទៅកាន់ Flutter Mobile/Tablet App ក្នុងបរិបទម៉ាតនៅប្រទេសកម្ពុជា។

---

## លក្ខណៈពិសេសចម្បង (Features)

1. **ប្រព័ន្ធរូបិយប័ណ្ណពីរ (Dual Currency Engine)**: គណនាប្រាក់ដុល្លារ ($) និងប្រាក់រៀល (៛) ដោយស្វ័យប្រវត្តិតាមអត្រាប្តូរប្រាក់ជាក់ស្តែង (ឧទាហរណ៍៖ $1 = 4,100 ៛)។
2. **ការគ្រប់គ្រងទំនិញ និងស្តុក (Mart Inventory & Products)**: ស្វែងរកតាមបាកូដ (Barcode), តាមដានថ្ងៃផុតកំណត់ (Expiration date), និងជូនដំណឹងទំនិញជិតអស់ពីស្តុក (Low stock alerts)។
3. **ការគិតលុយ និងចេញវិក្កយបត្រ (POS Checkout & Invoicing)**: បង្កើតវិក្កយបត្រស្វ័យប្រវត្តិ, កាត់ស្តុកភ្លាមៗ, គណនាប្រាក់អាប់ជាដុល្លារ និងរៀល។
4. **ការទូទាត់តាម KHQR (Bakong Payment)**: បង្កើត QR កូដស្តង់ដារបាគងសម្រាប់ស្កេនទូទាត់ប្រាក់។
5. **ការគ្រប់គ្រងវេនការងារ និងប្រអប់លុយ (Shift & Cash Drawer)**: បើក/បិទវេន, កត់ត្រាចំនួនសាច់ប្រាក់ដើមគ្រា និងចុងគ្រា។
6. **ពិន្ទុសន្សំអតិថិជន (Customer Loyalty Points)**: ស្វែងរកតាមលេខទូរស័ព្ទ និងសន្ំពិន្ទុពីរាល់ការទិញ។

---

## របៀបតម្លើង និងដំណើរការ (Installation & Setup)

### ជំហានទី ១: បង្កើត Database ក្នុង MySQL
1. បើក XAMPP ឬ Laragon ហើយចុច Start **MySQL** (និង Apache)
2. ចូលទៅកាន់ phpMyAdmin (`http://localhost/phpmyadmin`)
3. បង្កើត Database ឈ្មោះ `mart_db`
4. Import ឯកសារ `backend/database/mart_db.sql` ចូលទៅក្នុង `mart_db`

### ជំហានទី ២: កំណត់ Configuration
1. ចម្លង `.env.example` ទៅជា `.env`:
   ```bash
   cp .env.example .env
   ```
2. បើកកែប្រែ `.env` ពិនិត្យមើល username/password របស់ MySQL:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=mart_db
   DB_USERNAME=root
   DB_PASSWORD=
   ```

### ជំហានទី ៣: ដំណើរការ Laravel API Server
ដំណើរការ Command:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```
Server នឹងដំណើរការនៅអាសយដ្ឋាន `http://127.0.0.1:8000` (ឬ `http://10.0.2.2:8000` សម្រាប់ Android Emulator)។

---

## បញ្ជី REST API Endpoints

| Method | Endpoint | ការពិពណ៌នា (Description) |
|---|---|---|
| `POST` | `/api/auth/login` | ចូលប្រព័ន្ធ (Admin / Cashier Login) |
| `GET` | `/api/products` | បញ្ជីទំនិញទាំងអស់ (អាច Filter តាម Category / Search) |
| `GET` | `/api/products/barcode/{code}` | ស្វែងរកទំនិញតាមបាកូដ |
| `GET` | `/api/products/alerts/low-stock` | ទំនិញដែលជិតអស់ពីស្តុក |
| `GET` | `/api/products/alerts/expiring` | ទំនិញដែលជិតផុតកំណត់កាលបរិច្ឆេទ |
| `POST` | `/api/products` | បន្ថែមទំនិញថ្មី |
| `PUT` | `/api/products/{id}` | កែប្រែព័ត៌មានទំនិញ |
| `GET` | `/api/categories` | ប្រភេទទំនិញម៉ាតទាំងអស់ |
| `POST` | `/api/orders` | គិតលុយលក់ទំនិញ (Checkout & Stock Deduction) |
| `GET` | `/api/orders` | ប្រវត្តិវិក្កយបត្រទាំងអស់ |
| `GET` | `/api/customers/search/{phone}` | ស្វែងរកអតិថិជនតាមលេខទូរស័ព្ទ |
| `POST` | `/api/shifts/open` | បើកវេនការងារបេឡាករ (Opening Cash) |
| `POST` | `/api/shifts/close` | បិទវេនការងារ និងផ្ទៀងផ្ទាត់សាច់ប្រាក់ |
| `GET` | `/api/reports/today` | សង្ខេបចំណូលលក់ប្រចាំថ្ងៃ ($ និង ៛) |
| `POST` | `/api/payment/khqr/generate` | បង្កើត QR កូដ KHQR បាគង |
