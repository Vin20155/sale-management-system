class AppStrings {
  // Common / General
  static String appTitle(bool isEn) =>
      isEn ? 'Mart Sales Management System' : 'ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត';
  static String all(bool isEn) => isEn ? 'All' : 'ទាំងអស់';
  static String save(bool isEn) => isEn ? 'Save' : 'រក្សាទុក';
  static String cancel(bool isEn) => isEn ? 'Cancel' : 'បោះបង់';
  static String edit(bool isEn) => isEn ? 'Edit' : 'កែប្រែ';
  static String delete(bool isEn) => isEn ? 'Delete' : 'លុប';
  static String close(bool isEn) => isEn ? 'Close' : 'បិទ';
  static String success(bool isEn) => isEn ? 'Success' : 'ជោគជ័យ';
  static String error(bool isEn) => isEn ? 'Error' : 'កំហុស';
  static String viewDetail(bool isEn) => isEn ? 'View Detail' : 'មើលលម្អិត';
  static String total(bool isEn) => isEn ? 'Total' : 'សរុប';
  static String subtotal(bool isEn) => isEn ? 'Subtotal' : 'តម្លៃដើម';
  static String discount(bool isEn) => isEn ? 'Discount' : 'បញ្ចុះតម្លៃ';
  static String none(bool isEn) => isEn ? 'None' : 'គ្មាន';
  static String custom(bool isEn) => isEn ? 'Custom' : 'ផ្សេងៗ';
  static String search(bool isEn) => isEn ? 'Search' : 'ស្វែងរក';
  static String clear(bool isEn) => isEn ? 'Clear' : 'សម្អាត';
  static String confirm(bool isEn) => isEn ? 'Confirm' : 'យល់ព្រម';
  static String loading(bool isEn) => isEn ? 'Loading...' : 'កំពុងផ្ទុក...';
  static String saving(bool isEn) => isEn ? 'Saving...' : 'កំពុងរក្សាទុក...';
  static String active(bool isEn) => isEn ? 'Active' : 'សកម្ម';
  static String inactive(bool isEn) => isEn ? 'Inactive' : 'អសកម្ម';

  // POS & Terminal
  static String martPosTerminal(bool isEn) =>
      isEn ? 'Mart POS Terminal' : 'កន្លែងគិតលុយម៉ាត';
  static String exchangeRateLabel(bool isEn, double rate) =>
      isEn ? 'Exchange Rate: \$1 = ${rate.toStringAsFixed(0)} KHR' : 'អត្រាប្តូរប្រាក់: \$1 = ${rate.toStringAsFixed(0)} ៛';
  static String posSearchHint(bool isEn) =>
      isEn ? 'Search product name, item code, or barcode...' : 'ស្វែងរកឈ្មោះទំនិញ កូដទំនិញ ឬបាកូដ...';
  static String remainingStock(bool isEn, int qty) =>
      isEn ? 'Rem: $qty' : 'សល់ $qty';
  static String pay(bool isEn) => isEn ? 'Pay' : 'គិតលុយ';
  static String proceedToCheckout(bool isEn) =>
      isEn ? 'Proceed to Checkout' : 'បន្តទៅគិតលុយ';
  static String cartItems(bool isEn) =>
      isEn ? 'Cart Items' : 'កន្ត្រកទំនិញ';
  static String clearCart(bool isEn) =>
      isEn ? 'Clear Cart' : 'សម្អាតកន្ត្រក';
  static String emptyCartMsg(bool isEn) =>
      isEn ? 'Cart is empty. Tap products to add.' : 'កន្ត្រកនៅទទេនៅឡើយ។ សូមចុចលើទំនិញដើម្បីបន្ថែម។';
  static String quickScanner(bool isEn) =>
      isEn ? 'Quick Barcode Scanner' : 'ស្កេនបាកូដរហ័ស';
  static String customerSearch(bool isEn) =>
      isEn ? 'Customer Loyalty Search' : 'ស្វែងរកអតិថិជន';

  // Checkout Dialog
  static String checkoutTitle(bool isEn) =>
      isEn ? 'Payment & Checkout' : 'ការទូទាត់ប្រាក់ & គិតលុយ';
  static String paymentMethod(bool isEn) =>
      isEn ? 'Payment Method' : 'វិធីសាស្រ្តទូទាត់';
  static String cashUsd(bool isEn) =>
      isEn ? 'Cash (USD)' : 'សាច់ប្រាក់ (ដុល្លារ)';
  static String cashKhr(bool isEn) =>
      isEn ? 'Cash (KHR)' : 'សាច់ប្រាក់ (រៀល)';
  static String mixedCash(bool isEn) =>
      isEn ? 'Mixed Cash' : 'សាច់ប្រាក់ចម្រុះ';
  static String bakongKhqr(bool isEn) =>
      isEn ? 'Bakong KHQR' : 'បាគង KHQR';
  static String receivedAmount(bool isEn) =>
      isEn ? 'Received Amount' : 'ប្រាក់ទទួលបាន';
  static String changeAmount(bool isEn) =>
      isEn ? 'Change' : 'ប្រាក់អាប់';
  static String completeCheckout(bool isEn) =>
      isEn ? 'Complete Checkout' : 'បញ្ចប់ការទូទាត់';

  // Products & Inventory Screen
  static String manageProducts(bool isEn) =>
      isEn ? 'Manage Products' : 'គ្រប់គ្រងទំនិញម៉ាត';
  static String addNewProduct(bool isEn) =>
      isEn ? 'Add New Product' : 'បន្ថែមទំនិញថ្មី';
  static String editProduct(bool isEn) =>
      isEn ? 'Edit Product' : 'កែប្រែទំនិញ';
  static String productDetails(bool isEn) =>
      isEn ? 'Product Details' : 'ព័ត៌មានលម្អិតទំនិញ';
  static String productInformation(bool isEn) =>
      isEn ? 'Product Information' : 'ព័ត៌មានលម្អិតបច្ចេកទេស';
  static String itemCode(bool isEn) =>
      isEn ? 'Item Code' : 'កូដទំនិញ';
  static String barcode(bool isEn) =>
      isEn ? 'Barcode' : 'លេខបាកូដ';
  static String khmerName(bool isEn) =>
      isEn ? 'Khmer Name' : 'ឈ្មោះខ្មែរ';
  static String englishName(bool isEn) =>
      isEn ? 'English Name' : 'ឈ្មោះឡាតាំង';
  static String category(bool isEn) =>
      isEn ? 'Category' : 'ប្រភេទទំនិញ';
  static String sellingPrice(bool isEn) =>
      isEn ? 'Selling Price' : 'តម្លៃលក់';
  static String costPrice(bool isEn) =>
      isEn ? 'Cost Price' : 'តម្លៃដើម';
  static String currentStock(bool isEn) =>
      isEn ? 'Current Stock' : 'ចំនួនស្តុក';
  static String stockTotal(bool isEn) =>
      isEn ? 'Total Stock' : 'ចំនួនស្តុកសរុប';
  static String reorderLevel(bool isEn) =>
      isEn ? 'Reorder Level' : 'កម្រិតប្រកាសអាសន្ន';
  static String unit(bool isEn) =>
      isEn ? 'Unit' : 'ឯកតា';
  static String expiryDate(bool isEn) =>
      isEn ? 'Expiry Date' : 'ថ្ងៃផុតកំណត់';
  static String pickDate(bool isEn) =>
      isEn ? 'Select Date' : 'ជ្រើសរើសថ្ងៃ';
  static String addStock(bool isEn) =>
      isEn ? 'Add Stock' : 'បញ្ចូលស្តុក';
  static String stockIn(bool isEn) =>
      isEn ? 'Stock In' : 'បញ្ចូលស្តុក';
  static String inStock(bool isEn) =>
      isEn ? 'In Stock' : 'មានក្នុងស្តុក';
  static String lowStock(bool isEn) =>
      isEn ? 'Low Stock' : 'ជិតអស់ស្តុក';
  static String expiringSoon(bool isEn) =>
      isEn ? 'Expiring Soon' : 'ជិតផុតកំណត់';
  static String expired(bool isEn) =>
      isEn ? 'Expired' : 'ផុតកំណត់';
  static String selectQuickUnit(bool isEn) =>
      isEn ? 'Quick Select Unit' : 'ជ្រើសរើសឯកតារហ័ស';
  static String productSearchHint(bool isEn) =>
      isEn ? 'Search by name, item code, or barcode...' : 'ស្វែងរកតាមឈ្មោះ កូដទំនិញ ឬលេខបាកូដ...';

  // Category Screen
  static String categoriesTitle(bool isEn) =>
      isEn ? 'Product Categories' : 'ប្រភេទទំនិញម៉ាត';
  static String addCategory(bool isEn) =>
      isEn ? 'Add Category' : 'បន្ថែមប្រភេទទំនិញថ្មី';
  static String editCategory(bool isEn) =>
      isEn ? 'Edit Category' : 'កែប្រែប្រភេទទំនិញ';
  static String categoryCode(bool isEn) =>
      isEn ? 'Category Code' : 'កូដសម្គាល់';
  static String colorTheme(bool isEn) =>
      isEn ? 'Color Theme' : 'ពណ៌សម្គាល់';
  static String icon(bool isEn) =>
      isEn ? 'Icon' : 'រូបតំណាង';
  static String description(bool isEn) =>
      isEn ? 'Description' : 'ការពិពណ៌នា';
  static String unitsInCategory(bool isEn) =>
      isEn ? 'Units in this Category' : 'ឯកតារាប់ទំនិញក្នុងប្រភេទនេះ';
  static String addNewUnit(bool isEn) =>
      isEn ? 'Add new unit (e.g. Can, Bottle, Box)' : 'បញ្ចូលឯកតាថ្មី (ឧ. កំប៉ុង, ដប, កេស)';
  static String addUnitButton(bool isEn) =>
      isEn ? '+ Add' : '+ បន្ថែម';
  static String itemsCount(bool isEn, int count) =>
      isEn ? '$count items' : '$count មុខ';
  static String unitsCount(bool isEn, int count) =>
      isEn ? '$count units' : '$count ឯកតា';
  static String viewProducts(bool isEn) =>
      isEn ? 'View Products' : 'មើលទំនិញ';

  // Stock In / Batch Dialog
  static String stockInTitle(bool isEn) =>
      isEn ? 'Stock In (Goods Receipt)' : 'កត់ត្រាការបញ្ចូលស្តុក';
  static String currentTotalStock(bool isEn) =>
      isEn ? 'Current Total Stock' : 'ស្តុកសរុបបច្ចុប្បន្ន';
  static String activeBatches(bool isEn) =>
      isEn ? 'Active Batches' : 'ចំនួនឡូតិ៍សកម្ម';
  static String batchesCount(bool isEn, int count) =>
      isEn ? '$count batches' : '$count ឡូតិ៍';
  static String receivedQuantity(bool isEn, String unit) =>
      isEn ? 'Received Quantity ($unit) *' : 'ចំនួនទទួល ($unit) *';
  static String batchLotNumber(bool isEn) =>
      isEn ? 'Batch / Lot #' : 'លេខឡូតិ៍';
  static String receivedDate(bool isEn) =>
      isEn ? 'Received Date *' : 'កាលបរិច្ឆេទទទួលស្តុក *';
  static String batchExpiryDate(bool isEn) =>
      isEn ? 'Batch Expiry Date' : 'ថ្ងៃផុតកំណត់ឡូតិ៍នេះ';
  static String supplier(bool isEn) =>
      isEn ? 'Supplier / Source' : 'អ្នកផ្គត់ផ្គង់';
  static String note(bool isEn) =>
      isEn ? 'Note' : 'សម្គាល់';
  static String confirmStockIn(bool isEn) =>
      isEn ? 'Confirm & Receive Stock' : 'កត់ត្រាបញ្ចូលស្តុក';
  static String viewExistingBatches(bool isEn, int count) =>
      isEn ? 'View Existing Batches ($count)' : 'មើលបញ្ជីឡូតិ៍ដែលបានទទួលពីមុន ($count)';
  static String noBatchesYet(bool isEn) =>
      isEn ? 'No recorded batches yet for this product.' : 'មិនទាន់មានទិន្នន័យឡូតិ៍សម្រាប់ទំនិញនេះនៅឡើយទេ។';

  // Stock Screen (Alerts)
  static String stockTrackingTitle(bool isEn) =>
      isEn ? 'Inventory & Expiry Tracking' : 'គ្រប់គ្រងស្តុក & ផុតកំណត់';
  static String lowStockTab(bool isEn, int count) =>
      isEn ? 'Low Stock ($count)' : 'ជិតអស់ស្តុក ($count)';
  static String expiringTab(bool isEn, int count) =>
      isEn ? 'Expiring ($count)' : 'ជិតផុតកំណត់ ($count)';
  static String allWellStocked(bool isEn) =>
      isEn ? 'All products are well stocked!' : 'ស្តុកគ្រប់គ្រាន់ទាំងអស់ គ្មានទំនិញខ្វះខាតទេ!';
  static String noExpiringSoon(bool isEn) =>
      isEn ? 'No products are expiring soon!' : 'គ្មានទំនិញដែលជិតផុតកំណត់កាលបរិច្ឆេទទេ!';
  static String restock(bool isEn) =>
      isEn ? 'Restock' : 'បញ្ចូលស្តុក';

  // Navigation Menu / Dashboard
  static String dashboard(bool isEn) => isEn ? 'Dashboard' : 'ផ្ទាំងគ្រប់គ្រង';
  static String posCashier(bool isEn) => isEn ? 'POS Terminal' : 'កន្លែងគិតលុយ';
  static String products(bool isEn) => isEn ? 'Products' : 'ទំនិញ';
  static String categories(bool isEn) => isEn ? 'Categories' : 'ប្រភេទទំនិញ';
  static String inventory(bool isEn) => isEn ? 'Inventory' : 'ស្តុកទំនិញ';
  static String invoices(bool isEn) => isEn ? 'Invoices' : 'វិក្កយបត្រ';
  static String shifts(bool isEn) => isEn ? 'Shifts' : 'វេនលក់';
  static String customers(bool isEn) => isEn ? 'Customers' : 'អតិថិជន';
  static String reports(bool isEn) => isEn ? 'Reports' : 'របាយការណ៍';
  static String settings(bool isEn) => isEn ? 'Settings' : 'ការកំណត់';
  static String users(bool isEn) => isEn ? 'Users' : 'បុគ្គលិក';
  static String signOut(bool isEn) => isEn ? 'Sign Out' : 'ចាកចេញ';
}
