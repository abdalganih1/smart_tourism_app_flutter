 MULTIPART POST /experiences | Status: 404 | Body: {
I/flutter ( 2244):     "message": "The route api/experiences could not be found.",
I/flutter ( 2244):     "exception": "Symfony\\Component\\HttpKernel\\Exception\\NotFoundHttpException",
I/flutter ( 2244):     "file": "/home/u582443422/domains/lightyellow-porcupine-230777.hostingersite.com/public_html/vendor/laravel/framework/src/Illuminate/Routing/AbstractRouteCollection.php",
I/flutter ( 2244):     "line": 45,
I/flutter ( 2244):     "trace": [
I/flutter ( 2244):         {
I/flutter ( 2244):             "file": "/home/u582443422/domains/lightyellow-porcupine-230777.hostingersite.com/public_html/vendor/laravel/framework/src/Illuminate/Routing/RouteCollection.php",
I/flutter ( 2244):             "line": 162,
I/flutter ( 2244):             "function": "handleMatchedRoute",
I/flutter ( 2244):             "class": "Illuminate\\Routing\\AbstractRouteCollection",
I/flutter ( 2244):             "type": "->"
I/flutter ( 2244):         },
I/flutter ( 2244):         {
I/flutter ( 2244):             "file": "/home/u582443422/domains/lightyellow-porcupine-230777.hostingersite.com/public_html/vendor/laravel/framework/src/Illuminate/Routing/Router.php",
I/flutter ( 2244):             "line": 763,
I/flutter ( 2244):             "function": "match",
I/flutter ( 2244):             "class": 


قم بحل المشكلة علماً انه لدي الروابط ضمن api  هي
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api; // Import the API controllers namespace
use App\Http\Resources\UserResource; // Import UserResource for consistency

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
| Note: The "api" middleware group is automatically applied to all routes
| defined in this file by the RouteServiceProvider.
|
*/

// --- Publicly Accessible Routes ---
// These routes do NOT require a Sanctum token. Users can access them without logging in.

// Authentication (Login & Registration) - Handled by AuthController
Route::post('/register', [Api\AuthController::class, 'register']);
Route::post('/login', [Api\AuthController::class, 'login']);

// Browse Tourist Information
Route::get('/tourist-sites', [Api\TouristSiteController::class, 'index']);
Route::get('/tourist-sites/{touristSite}', [Api\TouristSiteController::class, 'show']);
Route::get('/site-categories', [Api\SiteCategoryController::class, 'index']);

// Browse Tourist Activities
Route::get('/tourist-activities', [Api\TouristActivityController::class, 'index']);
Route::get('/tourist-activities/{touristActivity}', [Api\TouristActivityController::class, 'show']);

// Browse Hotels
Route::get('/hotels', [Api\HotelController::class, 'index']);
Route::get('/hotels/{hotel}', [Api\HotelController::class, 'show']);
// Get rooms for a specific hotel (often public or contextually authorized)
Route::get('/hotels/{hotel}/rooms', [Api\HotelController::class, 'rooms']);


// Browse Products (Crafts) & Categories
Route::get('/products', [Api\ProductController::class, 'index']);
Route::get('/products/{product}', [Api\ProductController::class, 'show']);
Route::get('/product-categories', [Api\ProductCategoryController::class, 'index']);

// Browse Articles (Blog)
Route::get('/articles', [Api\ArticleController::class, 'index']);
Route::get('/articles/{article}', [Api\ArticleController::class, 'show']);


// --- Public Routes to Fetch Polymorphic Data FOR a Target ---
// These endpoints retrieve comments/ratings/experiences *for* a specific item.
// They can be public to allow browsing.
// Note: These call custom methods in the respective Controllers.

// Get comments for a specific target (e.g., /api/articles/1/comments)
// {targetType} and {targetId} are route parameters that map to arguments in indexForTarget method
Route::get('/{targetType}/{targetId}/comments', [Api\CommentController::class, 'indexForTarget']);

// Get ratings for a specific target (e.g., /api/products/5/ratings)
Route::get('/{targetType}/{targetId}/ratings', [Api\RatingController::class, 'indexForTarget']);

// Get experiences for a specific tourist site (e.g., /api/tourist-sites/1/experiences)
// Note: This is a specific endpoint for experiences under a site, not a generic polymorphic route
Route::get('/tourist-sites/{touristSite}/experiences', [Api\TouristSiteController::class, 'experiences']);


// --- Protected Routes ---
// These routes require a valid Sanctum token in the Authorization header.
// The 'auth:sanctum' middleware checks for the token and populates Auth::user().

Route::middleware('auth:sanctum')->group(function () {

    // Authentication (Logout & Get Authenticated User)
    Route::post('/logout', [Api\AuthController::class, 'logout']);
    // Get authenticated user details - includes profile & phone numbers via UserResource
    // The UserResource will load these relationships when $request->user() is passed to it.
    Route::get('/user', function (Request $request) {
        return new App\Http\Resources\UserResource($request->user()->load(['profile', 'phoneNumbers']));
    });


    // --- Profile Information ---
    // GET: /api/profile -> Fetches the user's profile information
    // PUT/PATCH: /api/profile -> Updates user's textual profile information
    Route::get('/profile', [Api\UserProfileController::class, 'show']);
    Route::put('/profile', [Api\UserProfileController::class, 'update']); // Use PUT for full replacement, or PATCH for partial update


    // --- Profile Picture Management ---
    // POST: /api/profile/picture -> Uploads a new profile picture
    // DELETE: /api/profile/picture -> Removes the current profile picture
    Route::post('/profile/picture', [Api\UserProfileController::class, 'updateProfilePicture']); // POST is standard for file uploads
    Route::delete('/profile/picture', [Api\UserProfileController::class, 'removeProfilePicture']);


    // --- Password Management ---
    // PUT/PATCH: /api/profile/password -> Updates the user's password
    Route::put('/profile/password', [Api\UserProfileController::class, 'updatePassword']); // Use PUT or PATCH for password updates


    // Shopping Cart Management
    // Accessible at /api/cart (list user's cart items)
    Route::get('/cart', [Api\ShoppingCartController::class, 'index']);
    // Accessible at /api/cart/add (add item to cart) - Using POST on a custom route
    Route::post('/cart/add', [Api\ShoppingCartController::class, 'store']);
    // Accessible at /api/cart/{cartItem} (update item quantity) - Using PUT on a resource-like URL
    Route::put('/cart/{cartItem}', [Api\ShoppingCartController::class, 'update']);
    // Accessible at /api/cart/{cartItem} (remove item) - Using DELETE on a resource-like URL
    Route::delete('/cart/{cartItem}', [Api\ShoppingCartController::class, 'destroy']);
    // Accessible at /api/cart/clear (clear the entire cart) - Using POST on a custom route
    Route::post('/cart/clear', [Api\ShoppingCartController::class, 'clearCart']);


    // Product Orders (Authenticated User's own orders)
    // Accessible at /api/my-orders (list user's orders)
    Route::get('/my-orders', [Api\ProductOrderController::class, 'index']);
    // Accessible at /api/my-orders/{productOrder} (show a specific order)
    Route::get('/my-orders/{productOrder}', [Api\ProductOrderController::class, 'show']);
    // Accessible at /api/orders (place a new order) - Using POST on a resource-like URL
    Route::post('/orders', [Api\ProductOrderController::class, 'store']);


    // Hotel Bookings (Authenticated User's own bookings)
    // Accessible at /api/my-bookings (list user's bookings)
    Route::get('/my-bookings', [Api\HotelBookingController::class, 'index']);
    // Accessible at /api/my-bookings/{hotelBooking} (show a specific booking)
    Route::get('/my-bookings/{hotelBooking}', [Api\HotelBookingController::class, 'show']);
    // Accessible at /api/bookings (place a new booking) - Using POST on a resource-like URL
    Route::post('/bookings', [Api\HotelBookingController::class, 'store']);
    // Optional: Allow user to cancel booking (status update)
    // Accessible at /api/my-bookings/{hotelBooking}/cancel - Using POST on a custom route
    // Note: The destroy method in controller can be used for cancellation logic
    Route::post('/my-bookings/{hotelBooking}/cancel', [Api\HotelBookingController::class, 'destroy']); // Re-purposing destroy method for cancel action


    // Site Experiences (Authenticated User's own contributions)
    // Using apiResource for CRUD on user's *own* site experiences.
    // Accessible at /api/my-experiences, /api/my-experiences/{siteExperience}, etc.
    // The apiResource covers index, store, show, update, destroy.
    // The index and show methods in Api\SiteExperienceController are designed to fetch/show *only* the authenticated user's experiences.
    Route::apiResource('my-experiences', Api\SiteExperienceController::class);


    // Polymorphic Actions (Favorites, Ratings, Comments) - Authenticated User Actions
    // Note: These endpoints perform actions or fetch *the user's* specific related items.

    // Favorites
    // Accessible at /api/favorites/toggle - Using POST on a custom route
    Route::post('/favorites/toggle', [Api\FavoriteController::class, 'toggle']);
    // Accessible at /api/my-favorites - Using GET on a custom route
    Route::get('/my-favorites', [Api\FavoriteController::class, 'index']);
    // Optional: Check if authenticated user has favorited a specific item (e.g., GET /api/articles/1/is-favorited)
    // Accessible at /{targetType}/{targetId}/is-favorited - Using GET on a polymorphic route
    Route::get('/{targetType}/{targetId}/is-favorited', [Api\FavoriteController::class, 'isFavoritedForTarget']);


    // Ratings
    // Accessible at /api/ratings (store) - Using POST on a resource route
    // Accessible at /api/ratings/{rating} (update/delete) - Using PUT/DELETE on a resource route
    // Index/Show are typically done via the target endpoint (e.g., /articles/{article}/ratings)
    Route::apiResource('ratings', Api\RatingController::class)->only(['store', 'update', 'destroy']);


    // Comments
    // Accessible at /api/comments (store) - Using POST on a resource route
    // Accessible at /api/comments/{comment} (update/delete) - Using PUT/DELETE on a resource route
    // Index/Show are typically done via the target endpoint (e.g., /articles/{article}/comments)
    Route::apiResource('comments', Api\CommentController::class)->only(['store', 'update', 'destroy']);
    // Accessible at /api/comments/{comment}/replies (get replies for a specific comment) - Using GET on a custom route
    Route::get('/comments/{comment}/replies', [Api\CommentController::class, 'replies']);


    // --- Protected Routes for Specific User Roles (Admin/Vendor/Manager API) ---
    // These routes would be in separate controllers (e.g., Api\Admin\...)
    // and protected by additional middleware or policies (e.g., can:manage-users, can:update-all-products)
    // They are not included in this general API file for simplicity but would follow similar patterns
    // as the admin web panel controllers but returning JSON resources.

});

// Note: This file does NOT include Admin/Vendor/Manager specific API endpoints for managing ALL users,
// ALL products, ALL orders, etc. Those would typically be in separate controllers and route groups
// with explicit authorization middleware (e.g., auth:sanctum, can:isAdmin).
