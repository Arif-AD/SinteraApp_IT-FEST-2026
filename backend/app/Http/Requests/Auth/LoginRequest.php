<?php

namespace App\Http\Requests\Auth;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => 'required|string',
            'password' => 'required|string|min:1',
        ];
    }

    public function messages(): array
    {
        return [
            'email.required' => 'Email atau username harus diisi',
            'password.required' => 'Kata sandi harus diisi',
            'password.min' => 'Kata sandi minimal 1 karakter',
        ];
    }
}
