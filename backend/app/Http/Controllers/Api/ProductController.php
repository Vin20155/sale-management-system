<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with('category')->active();

        if ($request->has('category_id') && !empty($request->category_id)) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name_en', 'like', "%{$search}%")
                ->orWhere('name_kh', 'like', "%{$search}%")
                ->orWhere('barcode', 'like', "%{$search}%");
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

    public function image($id)
    {
        $product = Product::find($id);
        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញរូបភាពទំនិញនេះទេ'
            ], 404);
        }

        $disk = Storage::disk('public');
        $imagePath = $product->image_url;
        if ($imagePath && str_contains($imagePath, '..')) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញរូបភាពទំនិញនេះទេ'
            ], 404);
        }

        if (!$imagePath || !$disk->exists($imagePath)) {
            $imagePath = 'products/default.jpg';
        }

        if (!$disk->exists($imagePath)) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញរូបភាពទំនិញនេះទេ'
            ], 404);
        }

        return response()->file($disk->path($imagePath));
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
            'name_kh' => 'required|string|max:200',
            'name_en' => 'required|string|max:200',
            'category_id' => 'required|exists:categories,id',
            'unit' => 'nullable|string',
            'cost_price_usd' => 'required|numeric|min:0',
            'selling_price_usd' => 'required|numeric|min:0',
            'stock_quantity' => 'required|integer|min:0',
            'reorder_level' => 'nullable|integer|min:0',
            'expiry_date' => 'nullable|date',
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
            'name_kh' => 'sometimes|string|max:200',
            'name_en' => 'sometimes|string|max:200',
            'category_id' => 'sometimes|exists:categories,id',
            'selling_price_usd' => 'sometimes|numeric|min:0',
            'stock_quantity' => 'sometimes|integer|min:0',
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

    private function deleteStoredProductImage(?string $imagePath): void
    {
        if ($imagePath !== null && str_starts_with($imagePath, 'products/')) {
            Storage::disk('public')->delete($imagePath);
        }
    }
}
