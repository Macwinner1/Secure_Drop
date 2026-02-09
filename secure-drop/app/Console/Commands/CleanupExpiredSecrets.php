<?php

namespace App\Console\Commands;

use App\Services\SecretService;
use Illuminate\Console\Command;

class CleanupExpiredSecrets extends Command
{
    protected $signature = 'secrets:cleanup';
    protected $description = 'Delete expired secrets from the database';

    public function __construct(
        private SecretService $secretService
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $this->info('Cleaning up expired secrets...');
        
        $count = $this->secretService->cleanupExpired();
        
        $this->info("Deleted {$count} expired secret(s).");
        
        return Command::SUCCESS;
    }
}
