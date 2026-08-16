<?php

namespace App\Exceptions;

use Exception;

class InvalidRoleException extends Exception
{
    public function __construct(string $message = "User role is not authorized for this action")
    {
        parent::__construct($message);
    }

    public function render()
    {
        return response()->json([
            'message' => $this->message,
            'status' => 'error',
        ], 403);
    }
}
