{{-- Politika sayfalarının ortak iskeleti: başlık, yürürlük tarihi, içerik --}}
@extends('site.layout', ['title' => $title, 'legal' => true])
@php($s = config('site'))

@section('content')
    <article class="mx-auto max-w-3xl px-5 py-12">
        <p class="text-sm font-semibold text-primary">{{ $s['app_name'] }}</p>
        <h1 class="mt-1 text-3xl font-extrabold tracking-tight sm:text-4xl">{{ $title }}</h1>
        <p class="mt-2 text-sm text-ink-secondary">Yürürlük tarihi: {{ $s['effective_date'] }}</p>
        <div class="legal mt-8">
            @yield('legal')
        </div>
    </article>
@endsection
