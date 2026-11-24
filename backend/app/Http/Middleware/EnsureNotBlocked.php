<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureNotBlocked
{
    public function handle(Request $request, Closure $next)
    {
        abort_if($request->user()?->is_blocked, 403, 'Hesabınız askıya alınmıştır.');

        return $next($request);
    }
}
