<?php

namespace Tests\Feature;

use App\Models\Secret;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecretApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_create_secret(): void
    {
        $response = $this->postJson('/api/v1/secrets', [
            'content' => 'This is a secret message',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'data' => ['id', 'url', 'expires_at'],
            ]);

        $this->assertDatabaseHas('secrets', [
            'id' => $response->json('data.id'),
        ]);
    }

    public function test_can_create_secret_with_ttl(): void
    {
        $response = $this->postJson('/api/v1/secrets', [
            'content' => 'Secret with TTL',
            'ttl_minutes' => 60,
        ]);

        $response->assertStatus(201);
        $this->assertNotNull($response->json('data.expires_at'));
    }

    public function test_can_retrieve_and_delete_secret(): void
    {
        $createResponse = $this->postJson('/api/v1/secrets', [
            'content' => 'Burn on read test',
        ]);

        $secretId = $createResponse->json('data.id');

        $response = $this->getJson("/api/v1/secrets/{$secretId}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'content' => 'Burn on read test',
                ],
            ]);

        $this->assertDatabaseMissing('secrets', ['id' => $secretId]);
    }

    public function test_cannot_retrieve_secret_twice(): void
    {
        $createResponse = $this->postJson('/api/v1/secrets', [
            'content' => 'One time only',
        ]);

        $secretId = $createResponse->json('data.id');

        $this->getJson("/api/v1/secrets/{$secretId}")->assertStatus(200);
        $this->getJson("/api/v1/secrets/{$secretId}")->assertStatus(404);
    }

    public function test_validation_fails_without_content(): void
    {
        $response = $this->postJson('/api/v1/secrets', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['content']);
    }

    public function test_expired_secret_returns_404(): void
    {
        $secret = Secret::create([
            'encrypted_content' => encrypt('Expired secret'),
            'expires_at' => now()->subMinute(),
        ]);

        $response = $this->getJson("/api/v1/secrets/{$secret->id}");

        $response->assertStatus(404);
        $this->assertDatabaseMissing('secrets', ['id' => $secret->id]);
    }
}
