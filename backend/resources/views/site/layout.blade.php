@php($s = config('site'))
<!DOCTYPE html>
<html lang="tr" class="scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title>{{ isset($title) ? $title.' · ' : '' }}{{ $s['app_name'] }}</title>
    <meta name="description" content="{{ $description ?? 'Yapay zekâ ile yemek fotoğrafından kalori hesaplayan, beslenmeni ve kilonu takip eden uygulama.' }}">
    <meta name="theme-color" content="#7C3AED">
    <meta property="og:title" content="{{ $title ?? $s['app_name'] }}">
    <meta property="og:description" content="{{ $description ?? 'Fotoğrafını çek, kalorini öğren.' }}">
    <meta property="og:type" content="website">
    @isset($noindex)<meta name="robots" content="noindex">@endisset
    @vite(['resources/css/app.css'])
</head>
<body class="bg-white text-ink antialiased">
    <header class="sticky top-0 z-30 border-b border-line/70 bg-white/85 backdrop-blur">
        <div class="mx-auto flex h-16 max-w-6xl items-center gap-6 px-5">
            <a href="{{ route('site.home') }}" class="flex items-center gap-2">
                <span class="flex h-9 w-9 items-center justify-center rounded-xl bg-primary text-white">
                    <svg viewBox="0 0 24 24" class="h-5 w-5" fill="currentColor"><path d="M12 2c.5 3.5 4.5 5.5 4.5 10.5A4.5 4.5 0 0 1 12 17a4.5 4.5 0 0 1-4.5-4.5c0-1.9.9-3.3 1.8-4.4.2 1.4.9 2.4 2 2.9C10.6 8 11 4.6 12 2Zm0 20a7 7 0 0 1-7-7c0-1.1.2-2.2.7-3.2.3 3.9 3 6.7 6.3 6.7s6-2.8 6.3-6.7c.5 1 .7 2.1.7 3.2a7 7 0 0 1-7 7Z"/></svg>
                </span>
                <span class="text-lg font-extrabold tracking-tight">{{ $s['app_name'] }}</span>
            </a>
            <nav class="ml-auto hidden items-center gap-6 text-sm font-medium text-ink-secondary md:flex">
                <a href="{{ route('site.home') }}#ozellikler" class="hover:text-primary">Özellikler</a>
                <a href="{{ route('site.home') }}#fiyatlar" class="hover:text-primary">Fiyatlar</a>
                <a href="{{ route('site.home') }}#sss" class="hover:text-primary">SSS</a>
                <a href="{{ route('site.support') }}" class="hover:text-primary">Destek</a>
            </nav>
            <a href="{{ route('site.home') }}#indir" class="btn-primary ml-auto h-10 px-4 md:ml-0">İndir</a>
        </div>
    </header>

    @if($s['demo'] && ($legal ?? false))
        <div class="border-b border-carb/30 bg-carb/10">
            <p class="mx-auto max-w-3xl px-5 py-2.5 text-center text-xs font-medium text-ink">
                Bu sayfa <b>demo</b> amaçlı örnek bir metindir. Yayından önce şirket bilgileriyle doldurulmalı ve bir hukuk danışmanına kontrol ettirilmelidir.
            </p>
        </div>
    @endif

    <main>
        {{ $slot ?? '' }}
        @yield('content')
    </main>

    <footer class="border-t border-line bg-muted">
        <div class="mx-auto grid max-w-6xl gap-8 px-5 py-12 sm:grid-cols-2 lg:grid-cols-4">
            <div>
                <p class="text-lg font-extrabold">{{ $s['app_name'] }}</p>
                <p class="mt-2 text-sm text-ink-secondary">Beslenmeni yönet, hedeflerine daha hızlı ulaş.</p>
            </div>
            <div>
                <p class="text-sm font-bold">Uygulama</p>
                <ul class="mt-3 space-y-2 text-sm text-ink-secondary">
                    <li><a class="hover:text-primary" href="{{ route('site.home') }}#ozellikler">Özellikler</a></li>
                    <li><a class="hover:text-primary" href="{{ route('site.home') }}#fiyatlar">Fiyatlar</a></li>
                    <li><a class="hover:text-primary" href="{{ route('site.support') }}">Destek</a></li>
                </ul>
            </div>
            <div>
                <p class="text-sm font-bold">Yasal</p>
                <ul class="mt-3 space-y-2 text-sm text-ink-secondary">
                    <li><a class="hover:text-primary" href="{{ route('site.privacy') }}">Gizlilik Politikası</a></li>
                    <li><a class="hover:text-primary" href="{{ route('site.terms') }}">Kullanım Koşulları (EULA)</a></li>
                    <li><a class="hover:text-primary" href="{{ route('site.subscription') }}">Abonelik Koşulları</a></li>
                    <li><a class="hover:text-primary" href="{{ route('site.kvkk') }}">KVKK Aydınlatma Metni</a></li>
                    <li><a class="hover:text-primary" href="{{ route('site.deletion') }}">Hesap ve Veri Silme</a></li>
                </ul>
            </div>
            <div>
                <p class="text-sm font-bold">İletişim</p>
                <ul class="mt-3 space-y-2 text-sm text-ink-secondary">
                    <li><a class="hover:text-primary" href="mailto:{{ $s['email'] }}">{{ $s['email'] }}</a></li>
                    <li>{{ $s['company'] }}</li>
                    <li>{{ $s['address'] }}</li>
                </ul>
            </div>
        </div>
        <p class="border-t border-line py-5 text-center text-xs text-ink-muted">
            © {{ date('Y') }} {{ $s['company'] }}. Apple, App Store; Google Play ve Google Play logosu ilgili şirketlerin ticari markalarıdır.
        </p>
    </footer>
</body>
</html>
