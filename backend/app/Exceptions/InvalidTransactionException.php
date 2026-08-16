<?php

namespace App\Exceptions;

use Exception;

class InvalidTransactionException extends Exception
{
    public function __construct(string $message = "Transaction operation failed")
    {
        parent::__construct($message);
    }

    public function render()
    {
        return response()->json([
            'message' => $this->message,
            'status' => 'error',
        ], 422);
    }
}
