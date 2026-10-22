<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::withCount('products')->get();

        return response()->json([
            'success' => true,
            'data' => $categories
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name_en' => 'required|string|max:150',
            'name_kh' => 'required|string|max:150',
            'code' => 'required|string|unique:categories,code|max:50',
            'icon' => 'nullable|string|max:50',
            'color_hex' => 'nullable|string|max:20',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'ទិន្នន័យមិនត្រឹមត្រូវ',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $request->all();
        if (empty($data['color_hex'])) {
            $data['color_hex'] = '#0F766E';
        }
        if (empty($data['icon'])) {
            $data['icon'] = 'category';
        }

        $category = Category::create($data);

        return response()->json([
            'success' => true,
            'message' => 'បានបង្កើតប្រភេទទំនិញថ្មីជោគជ័យ',
            'data' => $category
        ], 201);
    }

    public function show($id)
    {
        $category = Category::with('products')->find($id);

        if (!$category) {
            return response()->json(['success' => false, 'message' => 'រកមិនឃើញប្រភេទទំនិញ'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $category
        ]);
    }

    public function update(Request $request, $id)
    {
        $category = Category::find($id);

        if (!$category) {
            return response()->json(['success' => false, 'message' => 'រកមិនឃើញប្រភេទទំនិញ'], 404);
        }

        $validator = Validator::make($request->all(), [
            'name_en' => 'sometimes|string|max:150',
            'name_kh' => 'sometimes|string|max:150',
            'code' => 'sometimes|string|max:50|unique:categories,code,' . $id,
            'icon' => 'nullable|string|max:50',
            'color_hex' => 'nullable|string|max:20',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $category->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'បានកែប្រែប្រភេទទំនិញជោគជ័យ',
            'data' => $category
        ]);
    }

    public function destroy($id)
    {
        $category = Category::find($id);

        if (!$category) {
            return response()->json(['success' => false, 'message' => 'រកមិនឃើញប្រភេទទំនិញ'], 404);
        }

        $category->delete();

        return response()->json([
            'success' => true,
            'message' => 'បានលុបប្រភេទទំនិញជោគជ័យ'
        ]);
    }
}
