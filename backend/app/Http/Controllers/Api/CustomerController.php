<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function index()
    {
        $customers = Customer::orderBy('total_spent_usd', 'desc')->get();
        return response()->json(['success' => true, 'data' => $customers]);
    }

    public function findByPhone($phone)
    {
        $customer = Customer::where('phone', $phone)->first();
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'រកមិនឃើញអតិថិជននេះទេ'], 404);
        }
        return response()->json(['success' => true, 'data' => $customer]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:150',
            'phone' => 'required|string|unique:customers,phone',
        ]);

        $customer = Customer::create($request->all());

        return response()->json([
            'success' => true,
            'message' => 'បានចុះឈ្មោះអតិថិជនជោគជ័យ',
            'data' => $customer
        ], 201);
    }
}
