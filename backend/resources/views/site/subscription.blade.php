@extends('site.legal', ['title' => 'Abonelik Koşulları'])
@php($s = config('site'))

@section('legal')
<p>{{ $s['app_name'] }} Premium, App Store ve Google Play üzerinden satın alınan, <b>otomatik yenilenen</b> bir aboneliktir.</p>

<h2>Paketler</h2>
<ul>
    <li><b>Premium Aylık:</b> 1 ay süreli, her ay yenilenir. Örnek fiyat: {{ $s['price_monthly'] }}/ay.</li>
    <li><b>Premium Yıllık:</b> 1 yıl süreli, her yıl yenilenir. Örnek fiyat: {{ $s['price_yearly'] }}/yıl. İlk kez abone olanlara {{ $s['trial_days'] }} günlük ücretsiz deneme sunulabilir.</li>
</ul>
<p>Geçerli fiyat, ülkenize ve para biriminize göre satın alma ekranında gösterilir.</p>

<h2>Ödeme ve otomatik yenileme</h2>
<ul>
    <li>Ödeme, satın almayı onayladığınızda <b>Apple Kimliği</b> (iOS) veya <b>Google Play</b> (Android) hesabınızdan alınır.</li>
    <li>Abonelik, mevcut dönemin bitiminden <b>en az 24 saat önce</b> iptal edilmezse otomatik olarak yenilenir.</li>
    <li>Yenileme ücreti, dönem bitimine 24 saat kala hesabınızdan tahsil edilir.</li>
    <li>Ücretsiz deneme süresi varsa, deneme bitmeden en az 24 saat önce iptal etmezseniz deneme sonunda ücretli aboneliğe geçilir. Deneme sırasında abonelik satın alırsanız denemenin kalan kısmı geçersiz olur.</li>
</ul>

<h2>İptal ve yönetim</h2>
<ul>
    <li><b>iPhone / iPad:</b> Ayarlar &gt; [adınız] &gt; Abonelikler &gt; {{ $s['app_name'] }} &gt; Aboneliği İptal Et. Veya <a href="https://apps.apple.com/account/subscriptions" target="_blank" rel="noopener">apps.apple.com/account/subscriptions</a>.</li>
    <li><b>Android:</b> Google Play &gt; Profil &gt; Ödemeler ve abonelikler &gt; Abonelikler. Veya <a href="https://play.google.com/store/account/subscriptions?package={{ $s['android_package'] }}" target="_blank" rel="noopener">play.google.com abonelikler</a>.</li>
    <li>Uygulamada: <b>Profil &gt; Premium Üyeliğin &gt; Aboneliği Yönet</b>.</li>
</ul>
<p>İptal ettiğinizde Premium özellikler, ödemesi yapılmış dönemin sonuna kadar kullanılabilir. Hesabınızı silmek mağazadaki aboneliği <b>otomatik iptal etmez</b>.</p>

<h2>İade</h2>
<p>Ödemeler Apple ve Google tarafından alındığı için iade talepleri de onların politikalarına tabidir:</p>
<ul>
    <li>Apple: <a href="https://reportaproblem.apple.com" target="_blank" rel="noopener">reportaproblem.apple.com</a></li>
    <li>Google Play: <a href="https://support.google.com/googleplay/answer/2479637" target="_blank" rel="noopener">Google Play iade politikası</a></li>
</ul>

<h2>Satın alımları geri yükleme</h2>
<p>Yeni bir cihaza geçtiğinizde aynı Apple Kimliği / Google hesabıyla giriş yapıp uygulamadaki Premium ekranında <b>"Satın alımları geri yükle"</b>ye dokunun.</p>

<p>Sorularınız için: <a href="mailto:{{ $s['email'] }}">{{ $s['email'] }}</a></p>
@endsection
