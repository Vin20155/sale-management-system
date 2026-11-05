<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class UserController extends Controller
{
    /**
     * Get all users with optional search and role filtering.
     */
    public function index(Request $request)
    {
        if ($response = $this->adminOnly($request)) {
            return $response;
        }

        $query = User::query();

        // Search by name, email, phone, or username
        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('name_kh', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('username', 'like', "%{$search}%");
            });
        }

        // Filter by role
        if ($request->filled('role') && $request->role !== 'all') {
            $query->where('role', $request->role);
        }

        $users = $query->orderBy('id', 'asc')->get();

        return response()->json([
            'success' => true,
            'data' => $users
        ]);
    }

    /**
     * Create a new user account.
     */
    public function store(Request $request)
    {
        if ($response = $this->adminOnly($request)) {
            return $response;
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:150',
            'name_kh' => 'nullable|string|max:150',
            'email' => 'required|email|max:150|unique:users,email',
            'username' => 'nullable|string|max:100|unique:users,username',
            'password' => 'required|string|min:6',
            'role' => 'required|string|in:admin,cashier,stock_controller',
            'phone' => 'nullable|string|max:50',
            'is_active' => 'nullable',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'ទិន្នន័យមិនត្រឹមត្រូវ',
                'errors' => $validator->errors()
            ], 422);
        }

        // Generate username if not provided
        $username = $request->username;
        if (empty($username)) {
            $emailParts = explode('@', $request->email);
            $baseUsername = Str::slug($emailParts[0], '_');
            $username = $baseUsername;
            $counter = 1;
            while (User::where('username', $username)->exists()) {
                $username = $baseUsername . '_' . $counter;
                $counter++;
            }
        }

        $isActive = true;
        if ($request->has('is_active')) {
            $isActive = filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN);
        }

        $user = User::create([
            'name' => $request->name,
            'name_kh' => $request->name_kh ?? $request->name,
            'username' => $username,
            'email' => strtolower(trim($request->email)),
            'password' => Hash::make($request->input('password')),
            'role' => $request->role,
            'phone' => $request->phone ?? '',
            'is_active' => $isActive,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'បានបង្កើតគណនីអ្នកប្រើប្រាស់ជោគជ័យ',
            'data' => $user
        ], 201);
    }

    /**
     * Get a specific user by ID.
     */
    public function show(Request $request, $id)
    {
        if ($response = $this->adminOnly($request)) {
            return $response;
        }

        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញអ្នកប្រើប្រាស់នេះទេ'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $user
        ]);
    }

    /**
     * Update an existing user account.
     */
    public function update(Request $request, $id)
    {
        if ($response = $this->adminOnly($request)) {
            return $response;
        }

        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញអ្នកប្រើប្រាស់នេះទេ'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:150',
            'name_kh' => 'nullable|string|max:150',
            'email' => 'sometimes|required|email|max:150|unique:users,email,' . $id,
            'username' => 'nullable|string|max:100|unique:users,username,' . $id,
            'password' => 'nullable|string|min:6',
            'role' => 'sometimes|required|string|in:admin,cashier,stock_controller',
            'phone' => 'nullable|string|max:50',
            'is_active' => 'nullable',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'ទិន្នន័យមិនត្រឹមត្រូវ',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = [];

        if ($request->has('name')) {
            $data['name'] = trim($request->name);
        }

        if ($request->has('name_kh')) {
            $data['name_kh'] = trim($request->name_kh);
        }

        if ($request->has('email')) {
            $data['email'] = strtolower(trim($request->email));
        }

        if ($request->has('username') && !empty($request->username)) {
            $data['username'] = trim($request->username);
        }

        if ($request->has('role')) {
            $data['role'] = $request->role;
        }

        if ($request->has('phone')) {
            $data['phone'] = trim($request->phone ?? '');
        }

        if ($request->has('is_active')) {
            $data['is_active'] = filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN);
        }

        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $user->update($data);
        if ($request->filled('password') || !$user->is_active) {
            $user->tokens()->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'បានកែប្រែព័ត៌មានអ្នកប្រើប្រាស់ជោគជ័យ',
            'data' => $user->fresh()
        ]);
    }

    /**
     * Delete user or deactivate if foreign keys exist.
     */
    public function destroy(Request $request, $id)
    {
        if ($response = $this->adminOnly($request)) {
            return $response;
        }

        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញអ្នកប្រើប្រាស់នេះទេ'
            ], 404);
        }

        try {
            $user->delete();
            return response()->json([
                'success' => true,
                'message' => 'បានលុបអ្នកប្រើប្រាស់ជោគជ័យ'
            ]);
        } catch (\Throwable $e) {
            // If user has foreign key constraints (e.g. shifts or orders), deactivate instead
            $user->update(['is_active' => false]);
            return response()->json([
                'success' => true,
                'message' => 'អ្នកប្រើប្រាស់នេះមានទិន្នន័យលក់រួចហើយ ដូច្នេះប្រព័ន្ធបានកំណត់ជាអសកម្ម (Deactivated) ជំនួសវិញ'
            ]);
        }

    }

    private function adminOnly(Request $request): ?JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->is_active || $user->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Only administrators can manage users.',
            ], 403);
        }

        return null;
    }
}
