<?php

namespace App\Services;

use App\Repositories\SecretRepository;

class SecretService
{
    public function __construct(
        private SecretRepository $repository
    ) {}

    public function storeSecret(string $content, ?int $ttlMinutes = null): array
    {
        $secret = $this->repository->create($content, $ttlMinutes);

        return [
            'id' => $secret->id,
            'url' => url("/api/v1/secrets/{$secret->id}"),
            'expires_at' => $secret->expires_at?->toIso8601String(),
        ];
    }

    public function retrieveSecret(string $id): ?array
    {
        return $this->repository->findAndDelete($id);
    }

    public function cleanupExpired(): int
    {
        return $this->repository->deleteExpired();
    }
}
