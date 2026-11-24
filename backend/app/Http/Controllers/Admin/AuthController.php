<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;

class AuthController extends Controller
{
    public function show()
    {
        return Auth::user()?->is_admin ? redirect('/admin') : Inertia::render('Auth/Login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $ok = Auth::attempt([...$credentials, 'is_admin' => true, 'is_blocked' => false], $request->boolean('remember'));
        if (! $ok) {
            throw ValidationException::withMessages(['email' => 'E-posta veya şifre hatalı.']);
        }

        $request->session()->regenerate();

        return redirect()->intended('/admin');
    }

    public function logout(Request $request)
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/admin/login');
    }
}
