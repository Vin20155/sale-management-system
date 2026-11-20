<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::get('/', function () {
    return response()->json([
        'app' => 'Mart Sales Management System API',
        'status' => 'online',
        'version' => '1.0.0',
        'currency' => 'Dual Currency (USD & KHR)',
        'country' => 'Cambodia'
    ]);
})->withoutMiddleware('web');

Route::get('/storage/{path}', function (string $path) {
    if (str_contains($path, '..')) {
        abort(404);
    }

    $disk = Storage::disk('public');
    if (!$disk->exists($path)) {
        $path = 'products/default.jpg';
    }

    if (!$disk->exists($path)) {
        abort(404);
    }

    return response()->file($disk->path($path), [
        'Access-Control-Allow-Origin' => '*',
    ]);
})->where('path', '.*')->withoutMiddleware('web');
