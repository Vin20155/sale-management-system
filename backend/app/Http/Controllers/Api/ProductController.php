<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductBatch;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with(['category', 'activeBatches'])->active();

        if ($request->has('category_id') && !empty($request->category_id)) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name_en', 'like', "%{$search}%")
                ->orWhere('name_kh', 'like', "%{$search}%")
                ->orWhere('barcode', 'like', "%{$search}%")
                ->orWhere('item_code', 'like', "%{$search}%");
            });
        }

        $products = $query->orderBy('name_kh', 'asc')->get();

        return response()->json([
            'success' => true,
            'count' => $products->count(),
            'data' => $products
        ]);
    }

    public function show($id)
    {
        $product = Product::with('category')->find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញទំនិញនេះទេ'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $product
        ]);
    }

    public function findByBarcode($barcode)
    {
        $product = Product::with('category')
            ->where('barcode', $barcode)
            ->where('is_active', 1)
            ->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'មិនមានទំនិញដែលមានបាកូដ ' . $barcode . ' នេះទេ'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $product
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'barcode' => 'required|string|unique:products,barcode',
            'item_code' => 'nullable|string|max:50',
            'name_kh' => 'required|string|max:200',
            'name_en' => 'required|string|max:200',
            'category_id' => 'required|exists:categories,id',
            'unit' => 'nullable|string',
            'cost_price_usd' => 'required|numeric|min:0',
            'selling_price_usd' => 'required|numeric|min:0',
            'stock_quantity' => 'required|integer|min:0',
            'reorder_level' => 'nullable|integer|min:0',
            'expiry_date' => 'nullable|date',
            'received_date' => 'nullable|date',
            'image_url' => 'nullable|string|max:255',
            'image' => 'nullable|image|mimes:jpeg,jpg,png,webp|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'ទិន្នន័យមិនត្រឹមត្រូវ',
                'errors' => $validator->errors()
            ], 422);
        }

        $exchangeRate = 4100; // Can be read from setting
        $data = $request->except(['image', 'remove_image', '_method']);
        $data['cost_price_khr'] = $request->cost_price_usd * $exchangeRate;
        $data['selling_price_khr'] = $request->selling_price_usd * $exchangeRate;
        $data['is_active'] = 1;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('products', 'public');
            if ($imagePath === false) {
                return response()->json([
                    'success' => false,
                    'message' => 'មិនអាចរក្សាទុករូបភាពទំនិញបានទេ'
                ], 500);
            }
            $data['image_url'] = $imagePath;
        }

        $product = Product::create($data);

        // Auto-create initial batch for tracking if stock is supplied
        if ($product->stock_quantity > 0) {
            ProductBatch::create([
                'product_id' => $product->id,
                'batch_no' => 'BATCH-' . date('Ymd') . '-01',
                'received_date' => $request->received_date ?? now()->toDateString(),
                'expiry_date' => $request->expiry_date,
                'quantity_received' => $product->stock_quantity,
                'quantity_remaining' => $product->stock_quantity,
                'cost_price_usd' => $product->cost_price_usd,
                'cost_price_khr' => $product->cost_price_khr,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'បានបញ្ចូលទំនិញថ្មីដោយជោគជ័យ',
            'data' => $product
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញទំនិញនេះទេ'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'barcode' => 'sometimes|string|unique:products,barcode,' . $id,
            'item_code' => 'sometimes|nullable|string|max:50',
            'name_kh' => 'sometimes|string|max:200',
            'name_en' => 'sometimes|string|max:200',
            'category_id' => 'sometimes|exists:categories,id',
            'selling_price_usd' => 'sometimes|numeric|min:0',
            'stock_quantity' => 'sometimes|integer|min:0',
            'expiry_date' => 'sometimes|nullable|date',
            'received_date' => 'sometimes|nullable|date',
            'image_url' => 'sometimes|nullable|string|max:255',
            'image' => 'nullable|image|mimes:jpeg,jpg,png,webp|max:5120',
            'remove_image' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $exchangeRate = 4100;
        $data = $request->except(['image', 'remove_image', '_method']);
        if (isset($data['selling_price_usd'])) {
            $data['selling_price_khr'] = $data['selling_price_usd'] * $exchangeRate;
        }
        if (isset($data['cost_price_usd'])) {
            $data['cost_price_khr'] = $data['cost_price_usd'] * $exchangeRate;
        }

        $previousImage = $product->image_url;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('products', 'public');
            if ($imagePath === false) {
                return response()->json([
                    'success' => false,
                    'message' => 'មិនអាចរក្សាទុករូបភាពទំនិញបានទេ'
                ], 500);
            }
            $data['image_url'] = $imagePath;
        } elseif ($request->boolean('remove_image')) {
            $data['image_url'] = null;
        }

        $product->update($data);
        if ($previousImage !== $product->image_url) {
            $this->deleteStoredProductImage($previousImage);
        }

        return response()->json([
            'success' => true,
            'message' => 'បានកែប្រែព័ត៌មានទំនិញដោយជោគជ័យ',
            'data' => $product
        ]);
    }

    public function destroy($id)
    {
        $product = Product::find($id);
        if (!$product) {
            return response()->json(['success' => false, 'message' => 'រកមិនឃើញទំនិញ'], 404);
        }

        $product->update(['is_active' => 0]);

        return response()->json([
            'success' => true,
            'message' => 'បានលុបទំនិញដោយជោគជ័យ'
        ]);
    }

    public function lowStock()
    {
        $products = Product::with('category')->lowStock()->active()->get();

        return response()->json([
            'success' => true,
            'count' => $products->count(),
            'data' => $products
        ]);
    }

    public function expiringSoon(Request $request)
    {
        $days = $request->get('days', 30);
        $products = Product::with('category')->expiringSoon($days)->active()->get();

        return response()->json([
            'success' => true,
            'count' => $products->count(),
            'data' => $products
        ]);
    }

    public function getBatches($id)
    {
        $product = Product::find($id);
        if (!$product) {
            return response()->json(['success' => false, 'message' => 'រកមិនឃើញទំនិញ'], 404);
        }

        $batches = ProductBatch::where('product_id', $id)
            ->orderByRaw('CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END, expiry_date ASC, id ASC')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $batches
        ]);
    }

    public function addBatch(Request $request, $id)
    {
        $product = Product::find($id);
        if (!$product) {
            return response()->json(['success' => false, 'message' => 'រកមិនឃើញទំនិញ'], 404);
        }

        $validator = Validator::make($request->all(), [
            'quantity' => 'required|integer|min:1',
            'received_date' => 'required|date',
            'expiry_date' => 'nullable|date',
            'batch_no' => 'nullable|string|max:50',
            'cost_price_usd' => 'nullable|numeric|min:0',
            'supplier_name' => 'nullable|string|max:150',
            'note' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'ទិន្នន័យមិនត្រឹមត្រូវ',
                'errors' => $validator->errors()
            ], 422);
        }

        $exchangeRate = 4100;
        $costUsd = (float)($request->cost_price_usd ?? $product->cost_price_usd);
        $costKhr = $costUsd * $exchangeRate;
        $qty = (int)$request->quantity;

        // Auto generate batch number if not given
        $batchNo = $request->batch_no;
        if (empty($batchNo)) {
            $batchNo = 'B' . date('ymd', strtotime($request->received_date)) . '-' . strtoupper(substr(uniqid(), -4));
        }

        $batch = ProductBatch::create([
            'product_id' => $product->id,
            'batch_no' => $batchNo,
            'received_date' => $request->received_date,
            'expiry_date' => $request->expiry_date,
            'quantity_received' => $qty,
            'quantity_remaining' => $qty,
            'cost_price_usd' => $costUsd,
            'cost_price_khr' => $costKhr,
            'supplier_name' => $request->supplier_name,
            'note' => $request->note,
        ]);

        // Increment total product stock
        $product->increment('stock_quantity', $qty);

        // Update nearest expiry date on product table for quick lookups
        $nearestBatch = ProductBatch::where('product_id', $product->id)
            ->where('quantity_remaining', '>', 0)
            ->whereNotNull('expiry_date')
            ->orderBy('expiry_date', 'asc')
            ->first();

        if ($nearestBatch) {
            $product->update(['expiry_date' => $nearestBatch->expiry_date]);
        }

        return response()->json([
            'success' => true,
            'message' => 'បានបញ្ចូលស្តុកថ្មីដោយជោគជ័យ (Batch ' . $batchNo . ')',
            'data' => [
                'batch' => $batch,
                'product' => $product->fresh(['category', 'activeBatches'])
            ]
        ], 201);
    }

    private function deleteStoredProductImage(?string $imagePath): void
    {
        if ($imagePath !== null && str_starts_with($imagePath, 'products/')) {
            Storage::disk('public')->delete($imagePath);
        }
    }
}
