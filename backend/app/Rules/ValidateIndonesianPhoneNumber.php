<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class ValidateIndonesianPhoneNumber implements ValidationRule
{
    /**
     * Run the validation rule.
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        // Indonesian phone numbers start with 62 or 0, followed by valid area code
        if (!preg_match('/^(\+62|0)[0-9]{9,12}$/', $value)) {
            $fail('The ' . $attribute . ' must be a valid Indonesian phone number.');
        }
    }
}
