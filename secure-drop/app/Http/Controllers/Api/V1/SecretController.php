<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSecretRequest;
use App\Services\SecretService;
use Illuminate\Http\JsonResponse;

class SecretController extends Controller
{
    public function __construct(
        private SecretService $secretService
    ) {}

    /**
     * Store a newly created secret.
     * 
     * Creates a new secret with optional TTL. Returns a unique URL that can be shared.
     * Once accessed, the secret is permanently deleted (burn on read).
     * 
     * @group Secrets
     * @bodyParam content string required The secret text to store. Max 10000 characters. Example: MySecretPassword123
     * @bodyParam ttl_minutes integer Optional time-to-live in minutes (1-43200). Example: 60
     * @response 201 {"success":true,"data":{"id":"9d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a","url":"http://localhost/api/v1/secrets/9d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a","expires_at":"2026-02-09T20:30:00.000000Z"}}
     */
    public function store(StoreSecretRequest $request): JsonResponse
    {
        $result = $this->secretService->storeSecret(
            $request->input('content'),
            $request->input('ttl_minutes')
        );

        return response()->json([
            'success' => true,
            'data' => $result,
        ], 201);
    }

    /**
     * Retrieve and delete the specified secret.
     * 
     * Retrieves the secret content and immediately deletes it from the database.
     * This endpoint can only be called once per secret (burn on read).
     * 
     * @group Secrets
     * @urlParam id string required The UUID of the secret. Example: 9d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a
     * @response 200 {"success":true,"data":{"content":"MySecretPassword123","created_at":"2026-02-09T19:30:00.000000Z"}}
     * @response 404 {"success":false,"message":"Secret not found or has expired"}
     */
    public function show(string $id): JsonResponse
    {
        $secret = $this->secretService->retrieveSecret($id);

        if (!$secret) {
            return response()->json([
                'success' => false,
                'message' => 'Secret not found or has expired',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $secret,
        ]);
    }
}
