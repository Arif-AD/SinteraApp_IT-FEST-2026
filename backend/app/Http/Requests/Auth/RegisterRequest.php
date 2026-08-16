<?php

namespace App\Http\Requests\Auth;

use App\Rules\ValidateIndonesianPhoneNumber;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'phone' => ['required', 'unique:users,phone', new ValidateIndonesianPhoneNumber()],
            'password' => 'required|string|min:8|confirmed',
            'password_confirmation' => 'required|string|min:8',
            'role' => 'required|in:warga,petani,pengantar',
            'address' => 'nullable|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama harus diisi',
            'email.required' => 'Email harus diisi',
            'email.unique' => 'Email sudah terdaftar',
            'phone.required' => 'Nomor telepon harus diisi',
            'phone.unique' => 'Nomor telepon sudah terdaftar',
            'password.required' => 'Kata sandi harus diisi',
            'password.confirmed' => 'Konfirmasi kata sandi tidak sesuai',
            'role.required' => 'Peran harus dipilih',
            'role.in' => 'Peran tidak valid',
        ];
    }
}
