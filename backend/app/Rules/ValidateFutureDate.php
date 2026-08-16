<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class ValidateFutureDate implements ValidationRule
{
    /**
     * Run the validation rule.
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        $date = strtotime($value);
        $now = time();

        if ($date === false || $date <= $now) {
            $fail('The ' . $attribute . ' must be a future date.');
        }
    }
}
