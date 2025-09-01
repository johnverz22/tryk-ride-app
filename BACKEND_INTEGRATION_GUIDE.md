# 🔧 Backend Integration Guide

## Laravel Backend Setup for Ride-Hailing App

### 📋 **Prerequisites**
- Laravel 12.0+
- PHP 8.2+
- Redis (for message queues)
- WebSocket server (Pusher/Laravel Echo)
- Database (MySQL/PostgreSQL)

---

## 🚀 **Quick Setup**

### 1. **Install Required Packages**
```bash
composer require pusher/pusher-php-server
composer require predis/predis
composer require tymon/jwt-auth
npm install --save laravel-echo pusher-js
```

### 2. **Environment Configuration**
```bash
# .env
BROADCAST_DRIVER=pusher
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis

PUSHER_APP_ID=your_app_id
PUSHER_APP_KEY=your_app_key
PUSHER_APP_SECRET=your_app_secret
PUSHER_APP_CLUSTER=mt1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
```

### 3. **Database Migrations**
```bash
php artisan migrate
php artisan db:seed --class=RideStatusSeeder
php artisan db:seed --class=DriverStatusesTableSeeder
```

---

## 📡 **Real-Time Communication Setup**

### 1. **WebSocket Configuration**
```php
// config/broadcasting.php
'pusher' => [
    'driver' => 'pusher',
    'key' => env('PUSHER_APP_KEY'),
    'secret' => env('PUSHER_APP_SECRET'),
    'app_id' => env('PUSHER_APP_ID'),
    'options' => [
        'cluster' => env('PUSHER_APP_CLUSTER'),
        'useTLS' => true,
    ],
],
```

### 2. **Ride Tracking Service**
```php
<?php
// app/Services/RideTrackingService.php

namespace App\Services;

use App\Models\Ride;
use App\Events\RideStatusUpdated;
use App\Events\DriverLocationUpdated;
use Illuminate\Support\Facades\Redis;

class RideTrackingService
{
    public function updateRideStatus(Ride $ride, string $status)
    {
        $ride->update(['status' => $status]);
        
        // Broadcast to user
        broadcast(new RideStatusUpdated($ride))->toOthers();
        
        // Publish to message queue for analytics
        Redis::publish('ride.status_changed', json_encode([
            'ride_id' => $ride->id,
            'status' => $status,
            'timestamp' => now()->toISOString(),
        ]));
    }
    
    public function updateDriverLocation(string $driverId, float $lat, float $lng)
    {
        // Update driver location in cache
        Redis::setex("driver:location:{$driverId}", 300, json_encode([
            'latitude' => $lat,
            'longitude' => $lng,
            'updated_at' => now()->toISOString(),
        ]));
        
        // Get active ride for this driver
        $ride = Ride::where('driver_id', $driverId)
                   ->whereIn('status', ['accepted', 'driver_en_route', 'in_progress'])
                   ->first();
        
        if ($ride) {
            broadcast(new DriverLocationUpdated($ride, $lat, $lng))->toOthers();
        }
    }
    
    public function findNearbyDrivers(float $lat, float $lng, float $radiusKm = 5.0)
    {
        return DB::select("
            SELECT *, 
            (6371 * acos(cos(radians(?)) * cos(radians(current_latitude)) 
            * cos(radians(current_longitude) - radians(?)) 
            + sin(radians(?)) * sin(radians(current_latitude)))) AS distance
            FROM drivers 
            WHERE is_online = true 
            AND status = 'available'
            HAVING distance < ?
            ORDER BY distance
            LIMIT 10
        ", [$lat, $lng, $lat, $radiusKm]);
    }
}
```

### 3. **Broadcast Events**
```php
<?php
// app/Events/RideStatusUpdated.php

namespace App\Events;

use App\Models\Ride;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class RideStatusUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $ride;

    public function __construct(Ride $ride)
    {
        $this->ride = $ride;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('ride.' . $this->ride->id);
    }

    public function broadcastWith()
    {
        return [
            'type' => 'ride.status_changed',
            'ride_id' => $this->ride->id,
            'status' => $this->ride->status,
            'driver' => $this->ride->driver ? [
                'id' => $this->ride->driver->id,
                'name' => $this->ride->driver->name,
                'phone' => $this->ride->driver->phone,
                'rating' => $this->ride->driver->rating,
                'vehicle_type' => $this->ride->driver->vehicle_type,
                'license_plate' => $this->ride->driver->license_plate,
            ] : null,
            'timestamp' => now()->toISOString(),
        ];
    }
}
```

```php
<?php
// app/Events/DriverLocationUpdated.php

namespace App\Events;

use App\Models\Ride;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DriverLocationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $ride;
    public $latitude;
    public $longitude;

    public function __construct(Ride $ride, float $latitude, float $longitude)
    {
        $this->ride = $ride;
        $this->latitude = $latitude;
        $this->longitude = $longitude;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('ride.' . $this->ride->id);
    }

    public function broadcastWith()
    {
        return [
            'type' => 'ride.driver_location_update',
            'ride_id' => $this->ride->id,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'eta_minutes' => $this->calculateETA(),
            'timestamp' => now()->toISOString(),
        ];
    }

    private function calculateETA()
    {
        // Calculate ETA based on distance and traffic
        // This is a simplified version
        $distance = $this->calculateDistance(
            $this->latitude, 
            $this->longitude,
            $this->ride->pickup_latitude,
            $this->ride->pickup_longitude
        );
        
        return max(1, round($distance / 0.5)); // Assume 30 km/h average speed
    }

    private function calculateDistance($lat1, $lng1, $lat2, $lng2)
    {
        $earthRadius = 6371; // km
        
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        
        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLng/2) * sin($dLng/2);
             
        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        
        return $earthRadius * $c;
    }
}
```

---

## 🚗 **Ride Management API**

### 1. **Ride Controller**
```php
<?php
// app/Http/Controllers/Api/RideController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ride;
use App\Services\RideTrackingService;
use App\Services\DriverMatchingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RideController extends Controller
{
    protected $rideTrackingService;
    protected $driverMatchingService;

    public function __construct(
        RideTrackingService $rideTrackingService,
        DriverMatchingService $driverMatchingService
    ) {
        $this->rideTrackingService = $rideTrackingService;
        $this->driverMatchingService = $driverMatchingService;
    }

    public function requestRide(Request $request)
    {
        $request->validate([
            'ride_type' => 'required|in:economy,comfort,premium',
            'pickup_address' => 'required|string',
            'pickup_latitude' => 'required|numeric',
            'pickup_longitude' => 'required|numeric',
            'dropoff_address' => 'required|string',
            'dropoff_latitude' => 'required|numeric',
            'dropoff_longitude' => 'required|numeric',
            'payment_method' => 'nullable|string',
        ]);

        // Calculate fare
        $fare = $this->calculateFare(
            $request->pickup_latitude,
            $request->pickup_longitude,
            $request->dropoff_latitude,
            $request->dropoff_longitude,
            $request->ride_type
        );

        // Create ride request
        $ride = Ride::create([
            'user_id' => Auth::id(),
            'ride_status_id' => 1, // requested
            'ride_type' => $request->ride_type,
            'pickup_address' => $request->pickup_address,
            'pickup_latitude' => $request->pickup_latitude,
            'pickup_longitude' => $request->pickup_longitude,
            'dropoff_address' => $request->dropoff_address,
            'dropoff_latitude' => $request->dropoff_latitude,
            'dropoff_longitude' => $request->dropoff_longitude,
            'fare_amount' => $fare,
            'payment_method' => $request->payment_method,
            'requested_at' => now(),
        ]);

        // Find and notify nearby drivers
        $this->driverMatchingService->notifyNearbyDrivers($ride);

        return response()->json([
            'success' => true,
            'ride' => $ride->load('status'),
            'message' => 'Ride requested successfully',
        ]);
    }

    public function getRide(Ride $ride)
    {
        $this->authorize('view', $ride);

        return response()->json([
            'success' => true,
            'ride' => $ride->load(['driver', 'status']),
        ]);
    }

    public function cancelRide(Ride $ride)
    {
        $this->authorize('cancel', $ride);

        if (!in_array($ride->status->status, ['requested', 'accepted', 'driver_en_route'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot cancel ride at this stage',
            ], 400);
        }

        $this->rideTrackingService->updateRideStatus($ride, 'cancelled');

        return response()->json([
            'success' => true,
            'message' => 'Ride cancelled successfully',
        ]);
    }

    public function getUserRides(Request $request)
    {
        $rides = Ride::where('user_id', Auth::id())
                    ->with(['driver', 'status'])
                    ->orderBy('created_at', 'desc')
                    ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'rides' => $rides,
        ]);
    }

    private function calculateFare($pickupLat, $pickupLng, $dropoffLat, $dropoffLng, $rideType)
    {
        // Calculate distance
        $distance = $this->calculateDistance($pickupLat, $pickupLng, $dropoffLat, $dropoffLng);
        
        // Base rates per km
        $rates = [
            'economy' => 2.5,
            'comfort' => 3.5,
            'premium' => 5.0,
        ];
        
        $baseFare = [
            'economy' => 5.0,
            'comfort' => 8.0,
            'premium' => 12.0,
        ];
        
        return $baseFare[$rideType] + ($distance * $rates[$rideType]);
    }

    private function calculateDistance($lat1, $lng1, $lat2, $lng2)
    {
        $earthRadius = 6371; // km
        
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        
        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLng/2) * sin($dLng/2);
             
        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        
        return $earthRadius * $c;
    }
}
```

### 2. **Driver Controller**
```php
<?php
// app/Http/Controllers/Api/DriverController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ride;
use App\Services\RideTrackingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DriverController extends Controller
{
    protected $rideTrackingService;

    public function __construct(RideTrackingService $rideTrackingService)
    {
        $this->rideTrackingService = $rideTrackingService;
    }

    public function acceptRide(Request $request, Ride $ride)
    {
        $request->validate([
            'driver_id' => 'required|exists:drivers,id',
        ]);

        if ($ride->status->status !== 'requested') {
            return response()->json([
                'success' => false,
                'message' => 'Ride is no longer available',
            ], 400);
        }

        // Assign driver to ride
        $ride->update([
            'driver_id' => $request->driver_id,
            'accepted_at' => now(),
        ]);

        $this->rideTrackingService->updateRideStatus($ride, 'accepted');

        return response()->json([
            'success' => true,
            'ride' => $ride->load(['user', 'status']),
            'message' => 'Ride accepted successfully',
        ]);
    }

    public function updateLocation(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $driverId = Auth::id();
        
        $this->rideTrackingService->updateDriverLocation(
            $driverId,
            $request->latitude,
            $request->longitude
        );

        return response()->json([
            'success' => true,
            'message' => 'Location updated successfully',
        ]);
    }

    public function updateRideStatus(Request $request, Ride $ride)
    {
        $request->validate([
            'status' => 'required|in:driver_en_route,arrived,in_progress,completed',
        ]);

        $this->authorize('update', $ride);

        $this->rideTrackingService->updateRideStatus($ride, $request->status);

        if ($request->status === 'completed') {
            $ride->update(['completed_at' => now()]);
        }

        return response()->json([
            'success' => true,
            'ride' => $ride->load(['user', 'status']),
            'message' => 'Ride status updated successfully',
        ]);
    }

    public function getActiveRide()
    {
        $ride = Ride::where('driver_id', Auth::id())
                   ->whereIn('status', ['accepted', 'driver_en_route', 'arrived', 'in_progress'])
                   ->with(['user', 'status'])
                   ->first();

        return response()->json([
            'success' => true,
            'ride' => $ride,
        ]);
    }
}
```

---

## 🔄 **Driver Matching Service**

```php
<?php
// app/Services/DriverMatchingService.php

namespace App\Services;

use App\Models\Ride;
use App\Models\Driver;
use App\Events\RideRequestReceived;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class DriverMatchingService
{
    public function notifyNearbyDrivers(Ride $ride, float $radiusKm = 5.0)
    {
        $nearbyDrivers = $this->findNearbyDrivers(
            $ride->pickup_latitude,
            $ride->pickup_longitude,
            $radiusKm
        );

        foreach ($nearbyDrivers as $driver) {
            // Broadcast ride request to driver
            broadcast(new RideRequestReceived($ride, $driver))->toOthers();
            
            // Store in Redis with expiration (30 seconds)
            Redis::setex(
                "ride_request:{$ride->id}:driver:{$driver->id}",
                30,
                json_encode([
                    'ride_id' => $ride->id,
                    'driver_id' => $driver->id,
                    'expires_at' => now()->addSeconds(30)->toISOString(),
                ])
            );
        }

        return count($nearbyDrivers);
    }

    public function findNearbyDrivers(float $lat, float $lng, float $radiusKm = 5.0)
    {
        return DB::select("
            SELECT d.*, u.name, u.phone, u.profile_picture,
            (6371 * acos(cos(radians(?)) * cos(radians(d.current_latitude)) 
            * cos(radians(d.current_longitude) - radians(?)) 
            + sin(radians(?)) * sin(radians(d.current_latitude)))) AS distance
            FROM drivers d
            JOIN users u ON d.user_id = u.id
            WHERE d.is_online = true 
            AND d.status = 'available'
            AND d.current_latitude IS NOT NULL
            AND d.current_longitude IS NOT NULL
            HAVING distance < ?
            ORDER BY distance, d.rating DESC
            LIMIT 10
        ", [$lat, $lng, $lat, $radiusKm]);
    }

    public function assignBestDriver(Ride $ride)
    {
        $nearbyDrivers = $this->findNearbyDrivers(
            $ride->pickup_latitude,
            $ride->pickup_longitude
        );

        if (empty($nearbyDrivers)) {
            return null;
        }

        // Score drivers based on distance, rating, and acceptance rate
        $scoredDrivers = collect($nearbyDrivers)->map(function ($driver) {
            $distanceScore = max(0, 10 - $driver->distance); // Closer = higher score
            $ratingScore = $driver->rating * 2; // Rating out of 5, multiply by 2
            $acceptanceScore = ($driver->acceptance_rate ?? 80) / 10; // Acceptance rate score
            
            return [
                'driver' => $driver,
                'score' => $distanceScore + $ratingScore + $acceptanceScore,
            ];
        })->sortByDesc('score');

        return $scoredDrivers->first()['driver'] ?? null;
    }
}
```

---

## 📊 **Load Balancer Health Check**

```php
<?php
// app/Http/Controllers/HealthController.php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthController extends Controller
{
    public function check()
    {
        $health = [
            'status' => 'healthy',
            'timestamp' => now()->toISOString(),
            'services' => [],
        ];

        // Check database
        try {
            DB::connection()->getPdo();
            $health['services']['database'] = 'healthy';
        } catch (\Exception $e) {
            $health['services']['database'] = 'unhealthy';
            $health['status'] = 'unhealthy';
        }

        // Check Redis
        try {
            Redis::ping();
            $health['services']['redis'] = 'healthy';
        } catch (\Exception $e) {
            $health['services']['redis'] = 'unhealthy';
            $health['status'] = 'unhealthy';
        }

        // Check queue
        try {
            $queueSize = Redis::llen('queues:default');
            $health['services']['queue'] = [
                'status' => 'healthy',
                'pending_jobs' => $queueSize,
            ];
        } catch (\Exception $e) {
            $health['services']['queue'] = 'unhealthy';
            $health['status'] = 'unhealthy';
        }

        $statusCode = $health['status'] === 'healthy' ? 200 : 503;

        return response()->json($health, $statusCode);
    }

    public function metrics()
    {
        return response()->json([
            'active_rides' => Ride::whereIn('status', ['requested', 'accepted', 'driver_en_route', 'in_progress'])->count(),
            'online_drivers' => DB::table('drivers')->where('is_online', true)->count(),
            'total_users' => DB::table('users')->where('role_id', 2)->count(),
            'server_load' => sys_getloadavg()[0],
            'memory_usage' => memory_get_usage(true),
            'timestamp' => now()->toISOString(),
        ]);
    }
}
```

---

## 🔐 **API Routes**

```php
<?php
// routes/api.php

use App\Http\Controllers\Api\RideController;
use App\Http\Controllers\Api\DriverController;
use App\Http\Controllers\HealthController;
use Illuminate\Support\Facades\Route;

// Health check (for load balancer)
Route::get('/health', [HealthController::class, 'check']);
Route::get('/metrics', [HealthController::class, 'metrics']);

// Authentication required routes
Route::middleware(['auth:api'])->group(function () {
    
    // User routes
    Route::prefix('rides')->group(function () {
        Route::post('/', [RideController::class, 'requestRide']);
        Route::get('/', [RideController::class, 'getUserRides']);
        Route::get('/{ride}', [RideController::class, 'getRide']);
        Route::post('/{ride}/cancel', [RideController::class, 'cancelRide']);
    });

    // Driver routes
    Route::prefix('driver')->group(function () {
        Route::post('/rides/{ride}/accept', [DriverController::class, 'acceptRide']);
        Route::post('/location', [DriverController::class, 'updateLocation']);
        Route::post('/rides/{ride}/status', [DriverController::class, 'updateRideStatus']);
        Route::get('/active-ride', [DriverController::class, 'getActiveRide']);
    });
});
```

---

## 🚀 **Queue Jobs for Background Processing**

```php
<?php
// app/Jobs/ProcessRideRequest.php

namespace App\Jobs;

use App\Models\Ride;
use App\Services\DriverMatchingService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessRideRequest implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $ride;

    public function __construct(Ride $ride)
    {
        $this->ride = $ride;
    }

    public function handle(DriverMatchingService $driverMatchingService)
    {
        // Notify nearby drivers
        $notifiedCount = $driverMatchingService->notifyNearbyDrivers($this->ride);
        
        if ($notifiedCount === 0) {
            // No drivers available, update ride status
            $this->ride->update(['status' => 'no_drivers_available']);
            return;
        }

        // Set timeout for ride request (5 minutes)
        ProcessRideTimeout::dispatch($this->ride)->delay(now()->addMinutes(5));
    }
}
```

```php
<?php
// app/Jobs/ProcessRideTimeout.php

namespace App\Jobs;

use App\Models\Ride;
use App\Services\RideTrackingService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessRideTimeout implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $ride;

    public function __construct(Ride $ride)
    {
        $this->ride = $ride;
    }

    public function handle(RideTrackingService $rideTrackingService)
    {
        // Refresh ride from database
        $this->ride->refresh();

        // If ride is still in requested status, mark as timeout
        if ($this->ride->status->status === 'requested') {
            $rideTrackingService->updateRideStatus($this->ride, 'timeout');
        }
    }
}
```

---

## 📱 **Flutter Integration**

### WebSocket Connection
```dart
// lib/core/services/websocket_service.dart
import 'package:pusher_client/pusher_client.dart';

class WebSocketService {
  late PusherClient pusher;
  late Channel rideChannel;

  Future<void> connect() async {
    PusherOptions options = PusherOptions(
      cluster: 'mt1',
      encrypted: true,
    );

    pusher = PusherClient(
      'your_pusher_key',
      options,
      autoConnect: true,
    );

    pusher.onConnectionStateChange((state) {
      print('Connection state: ${state?.currentState}');
    });

    await pusher.connect();
  }

  void subscribeToRide(String rideId) {
    rideChannel = pusher.subscribe('private-ride.$rideId');
    
    rideChannel.bind('ride.status_changed', (event) {
      // Handle ride status updates
      final data = jsonDecode(event?.data ?? '{}');
      _handleRideStatusUpdate(data);
    });

    rideChannel.bind('ride.driver_location_update', (event) {
      // Handle driver location updates
      final data = jsonDecode(event?.data ?? '{}');
      _handleDriverLocationUpdate(data);
    });
  }

  void _handleRideStatusUpdate(Map<String, dynamic> data) {
    // Update your ViewModel
    final rideId = data['ride_id'];
    final status = data['status'];
    // Notify your RideBookingViewModel
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> data) {
    // Update driver location on map
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    final eta = data['eta_minutes'];
    // Update your ViewModel
  }
}
```

---

## 🔧 **Deployment Configuration**

### Docker Setup
```dockerfile
# Dockerfile
FROM php:8.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    redis-tools

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy application
COPY . .

# Install dependencies
RUN composer install --optimize-autoloader --no-dev

# Set permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
```

### Nginx Configuration
```nginx
# nginx.conf
server {
    listen 80;
    server_name api.yourapp.com;
    root /var/www/public;
    index index.php;

    # Health check endpoint
    location /health {
        access_log off;
        try_files $uri $uri/ /index.php?$query_string;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Load balancer health check
    location /lb-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

---

## 📊 **Monitoring & Analytics**

### Redis Analytics
```php
<?php
// app/Services/AnalyticsService.php

namespace App\Services;

use Illuminate\Support\Facades\Redis;

class AnalyticsService
{
    public function trackRideRequest(array $data)
    {
        Redis::lpush('analytics:ride_requests', json_encode([
            'timestamp' => now()->toISOString(),
            'data' => $data,
        ]));
    }

    public function trackDriverLocation(string $driverId, float $lat, float $lng)
    {
        Redis::lpush('analytics:driver_locations', json_encode([
            'driver_id' => $driverId,
            'latitude' => $lat,
            'longitude' => $lng,
            'timestamp' => now()->toISOString(),
        ]));
    }

    public function getMetrics()
    {
        return [
            'ride_requests_today' => Redis::llen('analytics:ride_requests'),
            'active_drivers' => Redis::scard('active_drivers'),
            'completed_rides_today' => Redis::get('completed_rides:' . now()->format('Y-m-d')) ?? 0,
        ];
    }
}
```

---

## 🚀 **Quick Deployment Commands**

```bash
# Build and deploy
docker-compose build
docker-compose up -d

# Run migrations
docker-compose exec app php artisan migrate

# Seed database
docker-compose exec app php artisan db:seed

# Start queue workers
docker-compose exec app php artisan queue:work --daemon

# Monitor logs
docker-compose logs -f app
```

This backend setup provides:
- ✅ Real-time WebSocket communication
- ✅ Load balancer health checks
- ✅ Message queue integration
- ✅ Scalable driver matching
- ✅ Background job processing
- ✅ Analytics and monitoring
- ✅ Docker deployment ready

Your Flutter apps can now seamlessly integrate with this backend for a complete ride-hailing solution!