<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required|string',
            'password' => 'required|string',
            'role' => 'sometimes|required|string|in:admin,cashier,stock_controller',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'សូមបំពេញព័ត៌មានឱ្យបានត្រឹមត្រូវ',
                'errors' => $validator->errors()
            ], 422);
        }

        $login = trim($request->input('username'));
        $user = User::where('username', $login)
            ->orWhere('email', $login)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'ឈ្មោះគណនី ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវទេ',
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'គណនីនេះត្រូវបានផ្អាកដំណើរការ',
            ], 403);
        }

        if ($request->filled('role') && $request->input('role') !== $user->role) {
            return response()->json([
                'success' => false,
                'message' => 'ឈ្មោះគណនី ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវទេ',
            ], 401);
        }

        $token = $user->createToken('mart_pos_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'ចូលប្រព័ន្ធបានជោគជ័យ',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'name_kh' => $user->name_kh,
                'username' => $user->username,
                'email' => $user->email,
                'role' => $user->role,
                'phone' => $user->phone,
            ]
        ]);
    }

    public function profile(Request $request)
    {
        if (!$request->user()->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'This account has been deactivated.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'user' => $request->user()
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'ចាកចេញពីប្រព័ន្ធបានជោគជ័យ'
        ]);
    }
}
