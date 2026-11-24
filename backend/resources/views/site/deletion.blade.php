@extends('site.legal', ['title' => 'Hesap ve Veri Silme'])
@php($s = config('site'))

@section('legal')
<p>{{ $s['app_name'] }} hesabınızı ve ilişkili tüm verilerinizi istediğiniz zaman silebilirsiniz.</p>

<h2>Uygulamadan silme (önerilen)</h2>
<ol>
    <li>{{ $s['app_name'] }} uygulamasını açın ve giriş yapın.</li>
    <li><b>Profil</b> sekmesine gidin.</li>
    <li><b>Verilerim</b>'e dokunun.</li>
    <li><b>Hesabımı ve verilerimi sil</b>'e dokunup onaylayın.</li>
</ol>
<p>İşlem anında gerçekleşir ve oturumunuz kapanır.</p>

<h2>Uygulamaya erişemiyorsanız</h2>
<p>Hesabınıza kayıtlı e-posta adresinden <a href="mailto:{{ $s['kvkk_email'] }}?subject=Hesap%20silme%20talebi">{{ $s['kvkk_email'] }}</a> adresine "Hesap silme talebi" konulu bir e-posta gönderin. Kimliğinizi doğruladıktan sonra hesabınız en geç 30 gün içinde silinir.</p>

<h2>Silinen veriler</h2>
<ul>
    <li>Hesap ve profil bilgileri (ad, e-posta, boy, kilo, hedefler)</li>
    <li>Öğün, yemek, su, aktivite ve kilo kayıtları</li>
    <li>Yapay zekâ analizi için yüklenen yemek fotoğrafları ve analiz sonuçları</li>
    <li>Oturum anahtarları</li>
</ul>

<h2>Saklanabilecek veriler</h2>
<p>Yasal zorunluluk nedeniyle saklanması gereken ödeme/fatura kayıtları, ilgili mevzuatta öngörülen süre boyunca (genellikle 10 yıl) kimliğinizle eşleştirilemeyecek biçimde tutulabilir. Kimliğinizle ilişkilendirilmemiş anonim istatistikler silinmez.</p>

<h2>Abonelik hakkında</h2>
<p>Hesabınızı silmek, App Store veya Google Play'deki aboneliğinizi <b>otomatik olarak iptal etmez</b>. Ücretlendirilmeye devam etmemek için aboneliği <a href="{{ route('site.subscription') }}">Abonelik Koşulları</a> sayfasında anlatıldığı şekilde ayrıca iptal edin.</p>
@endsection
