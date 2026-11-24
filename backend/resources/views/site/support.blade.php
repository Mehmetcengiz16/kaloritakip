@extends('site.layout', ['title' => 'Destek'])
@php($s = config('site'))

@section('content')
    <section class="mx-auto max-w-3xl px-5 py-12">
        <h1 class="text-3xl font-extrabold tracking-tight sm:text-4xl">Nasıl yardımcı olabiliriz?</h1>
        <p class="mt-3 text-ink-secondary">Sorunu yaşadığın cihazı (iPhone / Android), uygulama sürümünü ve kısa bir açıklamayı yazarsan daha hızlı yardımcı olabiliriz.</p>

        <a href="mailto:{{ $s['email'] }}?subject={{ rawurlencode($s['app_name'].' destek') }}" class="card mt-8 flex items-center gap-4 p-5 transition hover:border-primary">
            <span class="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary-soft text-primary"><x-icon name="mail" class="h-6 w-6" /></span>
            <span>
                <span class="block font-bold">E-posta ile ulaş</span>
                <span class="text-sm text-ink-secondary">{{ $s['email'] }} · genellikle 1 iş günü içinde yanıt</span>
            </span>
        </a>

        <div class="mt-10 grid gap-4 sm:grid-cols-2">
            @foreach([
                ['credit-card','Abonelik ve iade', route('site.subscription')],
                ['trash','Hesabımı silmek istiyorum', route('site.deletion')],
                ['shield','Gizlilik Politikası', route('site.privacy')],
                ['file-text','Kullanım Koşulları', route('site.terms')],
            ] as [$i,$t,$u])
                <a href="{{ $u }}" class="card flex items-center gap-3 p-4 font-semibold transition hover:border-primary">
                    <x-icon :name="$i" class="h-5 w-5 text-primary" />{{ $t }}<x-icon name="chevron-right" class="ml-auto h-4 w-4 text-ink-muted" />
                </a>
            @endforeach
        </div>

        <h2 class="mt-12 text-xl font-bold">Hızlı çözümler</h2>
        <div class="mt-4 space-y-3">
            @foreach([
                ['Premium aldım ama uygulama hâlâ ücretsiz görünüyor.','Premium ekranında "Satın alımları geri yükle"ye dokun. Aynı Apple Kimliği / Google hesabıyla giriş yaptığından emin ol.'],
                ['AI analizi "şu an yapılamıyor" diyor.','İnternet bağlantını kontrol et ve birkaç dakika sonra tekrar dene. Günlük analiz hakkın dolduysa yarın yenilenir.'],
                ['Barkodu okuttum, ürün bulunamadı.','Ürün veritabanımızda yoksa Ara sekmesinden benzer bir ürün seçebilir veya Fotoğraf (AI) ile ekleyebilirsin.'],
                ['Kalori hedefim yanlış görünüyor.','Profil > Hedef ve Bilgilerim\'den boy, kilo ve aktivite seviyeni güncelle; hedef otomatik yeniden hesaplanır.'],
            ] as [$q,$a])
                <details class="card group p-5">
                    <summary class="flex cursor-pointer list-none items-center justify-between font-semibold">{{ $q }}<x-icon name="plus" class="h-5 w-5 shrink-0 text-primary transition group-open:rotate-45" /></summary>
                    <p class="mt-3 text-sm leading-relaxed text-ink-secondary">{{ $a }}</p>
                </details>
            @endforeach
        </div>
    </section>
@endsection
