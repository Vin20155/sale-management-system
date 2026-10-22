<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'app' => 'Mart Sales Management System API',
        'status' => 'online',
        'version' => '1.0.0',
        'currency' => 'Dual Currency (USD & KHR)',
        'country' => 'Cambodia'
    ]);
});
