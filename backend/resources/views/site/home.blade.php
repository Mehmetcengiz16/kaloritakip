@extends('site.layout', ['title' => 'Fotoğrafını çek, kalorini öğren'])
@php($s = config('site'))

@section('content')
    {{-- HERO --}}
    <section class="overflow-hidden border-b border-line bg-muted">
        <div class="mx-auto grid max-w-6xl items-center gap-14 px-5 pb-16 pt-12 lg:grid-cols-[1.05fr_1fr] lg:pb-0 lg:pt-16">
            <div class="lg:pb-20">
                <span class="inline-flex items-center gap-2 rounded-full border border-primary/20 bg-white px-3 py-1 text-xs font-semibold text-primary">
                    <x-icon name="sparkles" class="h-3.5 w-3.5" /> Yapay zekâ destekli kalori takibi
                </span>
                <h1 class="mt-6 text-[2.6rem] font-extrabold leading-[1.08] tracking-tight sm:text-6xl">
                    Fotoğrafını çek,<br><span class="text-primary">kalorini öğren.</span>
                </h1>
                <p class="mt-6 max-w-xl text-lg leading-relaxed text-ink-secondary">
                    Tabağının fotoğrafından yemekleri ve porsiyonları tanır, kalori ve makrolarını saniyeler içinde hesaplar.
                    Kişisel hedef, su ve aktivite takibi, ilerleme grafikleri tek uygulamada.
                </p>
                <div id="indir" class="scroll-mt-24">
                    @include('site.partials.store-buttons', ['class' => 'mt-8'])
                </div>
                <ul class="mt-8 grid gap-3 text-sm font-medium text-ink sm:grid-cols-3">
                    @foreach(['Ücretsiz başla', 'Türk mutfağını tanır', 'Reklamsız Premium'] as $t)
                        <li class="flex items-center gap-2"><x-icon name="check-circle" class="h-5 w-5 text-success" />{{ $t }}</li>
                    @endforeach
                </ul>
            </div>

            <div class="relative mx-auto h-[520px] w-full max-w-[440px] sm:h-[600px]">
                <div class="absolute left-0 top-14 w-[52%] -rotate-[7deg]">
                    <x-phone src="photo" alt="Fotoğraf ile yapay zekâ analizi ekranı" class="w-full" eager />
                </div>
                <div class="absolute right-0 top-0 w-[58%]">
                    <x-phone src="plan" alt="Diyet planı ekranı: günlük hedef ve örnek menü" class="w-full" eager />
                </div>
            </div>
            </div>
        </div>
    </section>

    {{-- ÖZELLİKLER: gerçek ekranlarla --}}
    <section id="ozellikler" class="scroll-mt-20 py-20 lg:py-28">
        <div class="mx-auto max-w-6xl px-5">
            <div class="mx-auto max-w-2xl text-center">
                <p class="text-sm font-bold uppercase tracking-wider text-primary">Özellikler</p>
                <h2 class="mt-3 text-3xl font-extrabold tracking-tight sm:text-4xl">Kalori takibi, ilk günden alışkanlığa</h2>
                <p class="mt-4 text-ink-secondary">Her gün kullanmak isteyeceğin kadar hızlı ve sade.</p>
            </div>

            @php($features = [
                ['photo', 'camera', 'Fotoğrafla analiz', 'Tabağının fotoğrafını çek; yapay zekâ yemekleri tanısın, gramajları ve kalorileri tahmin etsin.', ['Türk mutfağına göre eğitilmiş istem', 'Porsiyonu tek dokunuşla düzelt', 'Emin olmadığı yemeği işaretler']],
                ['search', 'scan-barcode', 'Ara veya barkod okut', 'Yemek veritabanında ara ya da paketli ürünün barkodunu okut; besin değerleri otomatik gelsin.', ['Temel Türk yemekleri hazır', 'Binlerce paketli ürün (Open Food Facts)', 'Porsiyona göre anlık hesap']],
                ['nutrition', 'calendar', 'Öğün günlüğü', 'Kahvaltıdan akşam yemeğine her öğünü gör, düzenle; geçmiş günlere dön.', ['Öğün öğün kalori dağılımı', 'Günlük hedefe göre toplam', 'Geçmiş günlere ekleme']],
                ['progress', 'trending-up', 'İlerlemeni gör', 'Hedefine ne kadar kaldığını, kilo grafiğini, kalori ve makro ortalamalarını tek ekranda izle.', ['Hedefe tahmini varış tarihi', 'Haftalık, aylık, yıllık grafikler', 'Kayıt serisi ve alışkanlıklar']],
                ['plan', 'salad', 'Diyet planları', 'Kilo verme, alma ve koruma için hazırlanmış örnek günlük planlar.', ['Hedefine göre günlük kalori', 'Öğün öğün örnek menü', 'Premium ile tüm planlar']],
            ])

            <div class="mt-16 space-y-24">
                @foreach($features as $i => [$screen, $icon, $title, $desc, $points])
                    <div class="grid items-center gap-10 md:grid-cols-2 md:gap-16">
                        <div class="{{ $i % 2 ? 'md:order-2' : '' }}">
                            <span class="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary-soft text-primary">
                                <x-icon :name="$icon" class="h-6 w-6" />
                            </span>
                            <h3 class="mt-5 text-2xl font-extrabold tracking-tight sm:text-3xl">{{ $title }}</h3>
                            <p class="mt-3 text-lg leading-relaxed text-ink-secondary">{{ $desc }}</p>
                            <ul class="mt-6 space-y-3">
                                @foreach($points as $p)
                                    <li class="flex items-start gap-3 text-[15px]">
                                        <span class="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-primary text-white">
                                            <x-icon name="check" class="h-3 w-3" stroke-width="3" />
                                        </span>
                                        {{ $p }}
                                    </li>
                                @endforeach
                            </ul>
                        </div>
                        <div class="flex justify-center {{ $i % 2 ? 'md:order-1' : '' }}">
                            <div class="relative">
                                <div class="absolute inset-x-6 bottom-6 top-10 -z-10 rounded-[3rem] bg-primary-soft"></div>
                                <x-phone :src="$screen" :alt="$title" class="w-[250px] sm:w-[270px]" />
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    {{-- DİĞER ÖZELLİKLER --}}
    <section class="border-y border-line bg-muted py-16">
        <div class="mx-auto grid max-w-6xl gap-5 px-5 sm:grid-cols-2 lg:grid-cols-4">
            @foreach([
                ['target', 'Kişisel hedef', 'Boy, kilo, yaş ve aktivitene göre kalori ve makro hedefi.'],
                ['droplet', 'Su takibi', 'Tek dokunuşla +250 ml, +500 ml, +1 L.'],
                ['activity', 'Aktivite', 'Yakılan kalori günlük bütçene eklenir.'],
                ['shield', 'Gizlilik', 'Verilerin satılmaz, reklam için kullanılmaz.'],
            ] as [$icon, $t, $d])
                <div class="rounded-card border border-line bg-white p-6">
                    <x-icon :name="$icon" class="h-6 w-6 text-primary" />
                    <h3 class="mt-4 font-bold">{{ $t }}</h3>
                    <p class="mt-1.5 text-sm leading-relaxed text-ink-secondary">{{ $d }}</p>
                </div>
            @endforeach
        </div>
    </section>

    {{-- FİYATLAR --}}
    <section id="fiyatlar" class="scroll-mt-20 py-20 lg:py-28">
        <div class="mx-auto max-w-5xl px-5">
            <div class="mx-auto max-w-2xl text-center">
                <p class="text-sm font-bold uppercase tracking-wider text-primary">Fiyatlar</p>
                <h2 class="mt-3 text-3xl font-extrabold tracking-tight sm:text-4xl">Ücretsiz başla, istediğinde Premium'a geç</h2>
            </div>
            <div class="mt-12 grid items-start gap-6 md:grid-cols-2">
                <div class="rounded-card border border-line p-8">
                    <p class="font-bold">Ücretsiz</p>
                    <p class="mt-3 text-4xl font-extrabold">0 ₺</p>
                    <p class="mt-1 text-sm text-ink-secondary">Süresiz</p>
                    <ul class="mt-8 space-y-3.5 text-[15px]">
                        @foreach(['Günde 2 AI fotoğraf analizi', 'Yemek arama ve barkod', 'Kalori, makro, su ve aktivite takibi', 'Haftalık ve aylık ilerleme'] as $f)
                            <li class="flex gap-3"><x-icon name="check" class="h-5 w-5 shrink-0 text-ink-secondary" />{{ $f }}</li>
                        @endforeach
                    </ul>
                </div>
                <div class="relative rounded-card border-2 border-primary p-8 shadow-[0_20px_50px_-20px_rgba(124,58,237,0.35)]">
                    <span class="absolute -top-3.5 right-8 rounded-full bg-primary px-3 py-1 text-xs font-bold text-white">{{ $s['trial_days'] }} gün ücretsiz</span>
                    <p class="flex items-center gap-2 font-bold text-primary"><x-icon name="sparkles" class="h-4 w-4" /> Premium</p>
                    <p class="mt-3 text-4xl font-extrabold">{{ $s['price_yearly'] }}<span class="text-base font-semibold text-ink-secondary"> /yıl</span></p>
                    <p class="mt-1 text-sm text-ink-secondary">veya {{ $s['price_monthly'] }} /ay</p>
                    <ul class="mt-8 space-y-3.5 text-[15px]">
                        @foreach(['Günde 30 AI fotoğraf analizi', 'Kişisel AI beslenme önerileri', 'Tüm diyet planları', 'Yıllık ilerleme grafikleri', 'Reklamsız deneyim'] as $f)
                            <li class="flex gap-3"><x-icon name="check" class="h-5 w-5 shrink-0 text-primary" />{{ $f }}</li>
                        @endforeach
                    </ul>
                </div>
            </div>
            <p class="mx-auto mt-8 max-w-2xl text-center text-xs leading-relaxed text-ink-muted">
                Fiyatlar örnektir; geçerli fiyat uygulama içinde ve App Store / Google Play'de gösterilir. Abonelik, dönem bitiminden en az 24 saat önce
                iptal edilmezse otomatik yenilenir. Ayrıntılar: <a href="{{ route('site.subscription') }}" class="font-semibold text-primary">Abonelik Koşulları</a>.
            </p>
        </div>
    </section>

    {{-- SSS --}}
    <section id="sss" class="scroll-mt-20 border-t border-line bg-muted py-20">
        <div class="mx-auto max-w-3xl px-5">
            <h2 class="text-center text-3xl font-extrabold tracking-tight sm:text-4xl">Sık sorulan sorular</h2>
            <div class="mt-10 divide-y divide-line rounded-card border border-line bg-white">
                @foreach([
                    ['Fotoğraf analizi ne kadar doğru?', 'Yapay zekâ yemekleri ve porsiyonları tahmin eder; sonuçlar yaklaşıktır. Gramajı tek dokunuşla düzeltebilirsin. Uygulama tıbbi tavsiye vermez.'],
                    ['Fotoğraflarım nerede saklanıyor?', 'Fotoğraflar yalnızca analiz için kullanılır ve güvenli sunucularımızda saklanır; reklam amacıyla kullanılmaz veya satılmaz.'],
                    ['Aboneliğimi nasıl iptal ederim?', 'iPhone\'da Ayarlar > Apple Kimliği > Abonelikler; Android\'de Google Play > Ödemeler ve abonelikler. Uygulamada Profil > Premium Üyeliğin > Aboneliği Yönet de aynı sayfayı açar.'],
                    ['Hesabımı nasıl silerim?', 'Uygulamada Profil > Verilerim > Hesabımı ve verilerimi sil. Uygulamaya erişemiyorsan Hesap ve Veri Silme sayfasındaki adımları izle.'],
                    ['Aboneliğimi yeni telefona taşıyabilir miyim?', 'Evet. Aynı Apple Kimliği / Google hesabıyla giriş yapıp Premium ekranında "Geri yükle"ye dokunman yeterli.'],
                ] as [$q, $a])
                    <details class="group px-6 py-5">
                        <summary class="flex cursor-pointer list-none items-center justify-between gap-4 font-semibold">
                            {{ $q }}
                            <x-icon name="plus" class="h-5 w-5 shrink-0 text-primary transition group-open:rotate-45" />
                        </summary>
                        <p class="mt-3 text-[15px] leading-relaxed text-ink-secondary">{{ $a }}</p>
                    </details>
                @endforeach
            </div>
        </div>
    </section>

    {{-- CTA --}}
    <section class="px-5 py-20">
        <div class="mx-auto grid max-w-6xl items-center gap-10 overflow-hidden rounded-[2rem] bg-primary px-8 pt-12 text-white md:grid-cols-2 md:px-14">
            <div class="pb-12">
                <h2 class="text-3xl font-extrabold tracking-tight sm:text-4xl">Bugün başla, farkı ilk haftada gör.</h2>
                <p class="mt-4 max-w-md text-white/80">Ücretsiz indir, ilk fotoğrafını çek; gerisini {{ $s['app_name'] }} hesaplasın.</p>
                <div class="mt-8">@include('site.partials.store-buttons')</div>
            </div>
            <div class="flex justify-center self-end">
                <x-phone src="progress" alt="İlerleme ekranı" class="w-[230px] translate-y-10" />
            </div>
        </div>
    </section>
@endsection
