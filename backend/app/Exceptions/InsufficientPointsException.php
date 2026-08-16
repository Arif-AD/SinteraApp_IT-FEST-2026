<?php

namespace App\Exceptions;

use Exception;

class InsufficientPointsException extends Exception
{
    public function __construct(string $message = "Insufficient points for this redemption")
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
