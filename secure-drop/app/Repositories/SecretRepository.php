<?php

namespace App\Repositories;

use App\Models\Secret;
use Illuminate\Support\Facades\Crypt;

class SecretRepository
{
    public function create(string $content, ?int $ttlMinutes = null): Secret
    {
        $encryptedContent = Crypt::encryptString($content);
        
        $expiresAt = $ttlMinutes 
            ? now()->addMinutes($ttlMinutes) 
            : null;

        return Secret::create([
            'encrypted_content' => $encryptedContent,
            'expires_at' => $expiresAt,
        ]);
    }

    public function findAndDelete(string $id): ?array
    {
        $secret = Secret::find($id);

        if (!$secret) {
            return null;
        }

        if ($secret->expires_at && $secret->expires_at->isPast()) {
            $secret->delete();
            return null;
        }

        $decryptedContent = Crypt::decryptString($secret->encrypted_content);
        $secret->delete();

        return [
            'content' => $decryptedContent,
            'created_at' => $secret->created_at,
        ];
    }

    public function deleteExpired(): int
    {
        return Secret::where('expires_at', '<', now())->delete();
    }
}
