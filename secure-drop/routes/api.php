<?php

use App\Http\Controllers\Api\V1\SecretController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/secrets', [SecretController::class, 'store']);
    Route::get('/secrets/{id}', [SecretController::class, 'show']);
});
