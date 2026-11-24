<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (! $user?->is_admin || $user->is_blocked) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();

            return redirect('/admin/login')->with('error', 'Bu alana erişim yetkiniz yok.');
        }

        return $next($request);
    }
}
