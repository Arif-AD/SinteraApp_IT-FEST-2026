<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\Auth\RegisterController;
use App\Http\Controllers\Api\Auth\LoginController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\OrderChatController;

Route::prefix('v1')->group(function () {
    // Public Auth Routes
    Route::post('/auth/register', RegisterController::class)->name('auth.register');
    Route::post('/auth/login', LoginController::class)->name('auth.login');

    // Protected Auth Routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me'])->name('auth.me');
        Route::get('/about-app/stats', [AuthController::class, 'aboutAppStats'])->name('auth.aboutAppStats');
        Route::put('/me', [AuthController::class, 'update'])->name('auth.me.update');
        Route::post('/me/password', [AuthController::class, 'changePassword'])->name('auth.me.changePassword');
        Route::post('/auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
        Route::get('/notifications', [NotificationController::class, 'index'])->name('notifications.index');
        Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead'])->name('notifications.read');
        Route::delete('/notifications/{id}', [NotificationController::class, 'destroy'])->name('notifications.destroy');

        Route::get('/orders/{orderType}/{orderId}/chat', [OrderChatController::class, 'index'])
            ->where('orderType', 'order|sharing_order');
        Route::post('/orders/{orderType}/{orderId}/chat', [OrderChatController::class, 'store'])
            ->where('orderType', 'order|sharing_order');
    });

    // Warga (Consumer) Routes
    Route::middleware(['auth:sanctum'])->prefix('warga')->group(function () {
        Route::get('/home', [\App\Http\Controllers\Api\WargaController::class, 'home']);
        Route::get('/products', [\App\Http\Controllers\Api\WargaController::class, 'products']);
        Route::get('/recipients', [\App\Http\Controllers\Api\WargaController::class, 'recipients']);
        Route::get('/group-buyings', [\App\Http\Controllers\Api\WargaController::class, 'groupBuyings']);
        Route::post('/group-buyings/{id}/join', [\App\Http\Controllers\Api\WargaController::class, 'joinGroupBuying']);
        Route::get('/orders', [\App\Http\Controllers\Api\WargaController::class, 'orders']);
        Route::post('/orders', [\App\Http\Controllers\Api\WargaController::class, 'createOrder']);
        Route::post('/orders/{id}/rating', [\App\Http\Controllers\Api\WargaController::class, 'rateOrder']);
        Route::get('/sharing', [\App\Http\Controllers\Api\WargaController::class, 'sharing']);
        Route::post('/sharing', [\App\Http\Controllers\Api\WargaController::class, 'createSharing']);
        Route::get('/waste', [\App\Http\Controllers\Api\WargaController::class, 'waste']);
        Route::get('/waste/{id}', [\App\Http\Controllers\Api\WargaController::class, 'showWastePickup']);
        Route::post('/waste', [\App\Http\Controllers\Api\WargaController::class, 'createWastePickup']);
        Route::put('/waste/{id}', [\App\Http\Controllers\Api\WargaController::class, 'updateWastePickup']);
        Route::get('/wallet', [\App\Http\Controllers\Api\WargaController::class, 'wallet']);
        Route::get('/wallet/transactions', [\App\Http\Controllers\Api\WargaController::class, 'walletTransactions']);
        Route::get('/points', [\App\Http\Controllers\Api\WargaController::class, 'points']);
        Route::get('/points/transactions', [\App\Http\Controllers\Api\WargaController::class, 'pointTransactions']);
        Route::post('/points/deduct', [\App\Http\Controllers\Api\WargaController::class, 'deductPoints']);
        Route::get('/impact', [\App\Http\Controllers\Api\WargaController::class, 'impact']);
        Route::get('/vouchers', [\App\Http\Controllers\Api\WargaController::class, 'vouchers']);
        Route::post('/vouchers/{id}/redeem', [\App\Http\Controllers\Api\WargaController::class, 'redeemVoucher']);
    });

    // Petani (Farmer) Routes
    Route::middleware(['auth:sanctum'])->prefix('farmer')->group(function () {
        Route::get('/dashboard', [\App\Http\Controllers\Api\FarmerController::class, 'dashboard']);
        Route::get('/products', [\App\Http\Controllers\Api\FarmerController::class, 'products']);
        Route::post('/products', [\App\Http\Controllers\Api\FarmerController::class, 'createProduct']);
        Route::put('/products/{id}', [\App\Http\Controllers\Api\FarmerController::class, 'updateProduct']);
        Route::delete('/products/{id}', [\App\Http\Controllers\Api\FarmerController::class, 'deleteProduct']);
        Route::get('/orders', [\App\Http\Controllers\Api\FarmerController::class, 'orders']);
        Route::post('/orders/{id}/process', [\App\Http\Controllers\Api\FarmerController::class, 'processOrder']);
        Route::post('/orders/{id}/cancel', [\App\Http\Controllers\Api\FarmerController::class, 'cancelOrder']);
        Route::get('/income', [\App\Http\Controllers\Api\FarmerController::class, 'income']);
        Route::get('/compost', [\App\Http\Controllers\Api\FarmerController::class, 'compost']);
        Route::get('/waste', [\App\Http\Controllers\Api\FarmerController::class, 'waste']);
        Route::post('/waste/{id}/claim', [\App\Http\Controllers\Api\FarmerController::class, 'claimWastePickup']);
        Route::post('/compost/orders', [\App\Http\Controllers\Api\FarmerController::class, 'createCompostOrder']);
    });

    // Pengantar (Delivery) Routes
    Route::middleware(['auth:sanctum'])->prefix('delivery-person')->group(function () {
        Route::get('/dashboard', [\App\Http\Controllers\Api\DeliveryController::class, 'dashboard']);
        Route::get('/tasks', [\App\Http\Controllers\Api\DeliveryController::class, 'tasks']);
        Route::get('/tasks/{id}', [\App\Http\Controllers\Api\DeliveryController::class, 'taskDetail']);
        Route::post('/tasks/{id}/accept', [\App\Http\Controllers\Api\DeliveryController::class, 'acceptTask']);
        Route::post('/tasks/{id}/pickup', [\App\Http\Controllers\Api\DeliveryController::class, 'pickupTask']);
        Route::post('/tasks/{id}/complete', [\App\Http\Controllers\Api\DeliveryController::class, 'completeTask']);
    });

    // Health check
    Route::get('/health', function () {
        return response()->json(['status' => 'ok', 'timestamp' => now()]);
    });
});
