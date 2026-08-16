<?php

namespace App\Exceptions;

use Exception;

class ResourceNotFoundException extends Exception
{
    public function __construct(string $message = "Resource not found")
    {
        parent::__construct($message);
    }

    public function render()
    {
        return response()->json([
            'message' => $this->message,
            'status' => 'error',
        ], 404);
    }
}
