<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\ShiftController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SettingController;
use App\Http\Controllers\Api\KhqrController;

/*
|--------------------------------------------------------------------------
| API Routes for Mart Sales Management System (Cambodia)
|--------------------------------------------------------------------------
*/

// Authentication
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
});

// Products & Inventory
Route::prefix('products')->group(function () {
    Route::get('/', [ProductController::class, 'index']);
    Route::post('/', [ProductController::class, 'store']);
    Route::get('/alerts/low-stock', [ProductController::class, 'lowStock']);
    Route::get('/alerts/expiring', [ProductController::class, 'expiringSoon']);
    Route::get('/barcode/{barcode}', [ProductController::class, 'findByBarcode']);
    Route::get('/{id}', [ProductController::class, 'show']);
    Route::put('/{id}', [ProductController::class, 'update']);
    Route::delete('/{id}', [ProductController::class, 'destroy']);
});

// Categories
Route::prefix('categories')->group(function () {
    Route::get('/', [CategoryController::class, 'index']);
    Route::post('/', [CategoryController::class, 'store']);
    Route::get('/{id}', [CategoryController::class, 'show']);
    Route::put('/{id}', [CategoryController::class, 'update']);
    Route::delete('/{id}', [CategoryController::class, 'destroy']);
});

// Orders & POS Checkout
Route::prefix('orders')->group(function () {
    Route::get('/', [OrderController::class, 'index']);
    Route::post('/', [OrderController::class, 'store']);
    Route::get('/{id}', [OrderController::class, 'show']);
});

// Customers & Loyalty
Route::prefix('customers')->group(function () {
    Route::get('/', [CustomerController::class, 'index']);
    Route::post('/', [CustomerController::class, 'store']);
    Route::get('/search/{phone}', [CustomerController::class, 'findByPhone']);
});

// Cash Drawer & Shift Management
Route::prefix('shifts')->group(function () {
    Route::get('/current', [ShiftController::class, 'current']);
    Route::post('/open', [ShiftController::class, 'open']);
    Route::post('/close', [ShiftController::class, 'close']);
});

// Reports & Dashboard
Route::prefix('reports')->group(function () {
    Route::get('/today', [ReportController::class, 'todaySummary']);
});

// Settings & Exchange Rate
Route::prefix('settings')->group(function () {
    Route::get('/', [SettingController::class, 'index']);
    Route::post('/', [SettingController::class, 'update']);
    Route::put('/', [SettingController::class, 'update']);
});

// Payment & KHQR
Route::prefix('payment')->group(function () {
    Route::post('/khqr/generate', [KhqrController::class, 'generate']);
});
