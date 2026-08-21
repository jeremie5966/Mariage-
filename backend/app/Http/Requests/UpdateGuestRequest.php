<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateGuestRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user()?->role === 'admin';
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'first_name' => ['sometimes', 'string', 'max:100'],
            'last_name' => ['sometimes', 'string', 'max:100'],
            'phone' => ['nullable', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:255'],
            'category' => ['sometimes', 'string', 'max:50'],
            'number_of_guests' => ['sometimes', 'integer', 'min:1', 'max:20'],
            'table_number' => ['nullable', 'integer', 'min:1'],
            'notes' => ['nullable', 'string'],
            'status' => ['sometimes', 'in:active,inactive,blocked'],
        ];
    }
}
