@extends('site.legal', ['title' => 'Gizlilik Politikası'])
@php($s = config('site'))

@section('legal')
<p>Bu Gizlilik Politikası, {{ $s['company'] }} ("biz") tarafından sunulan {{ $s['app_name'] }} mobil uygulaması (iOS ve Android) ve web sitesi ("Hizmet") kapsamında hangi kişisel verilerin toplandığını, nasıl kullanıldığını ve haklarınızı açıklar.</p>

<h2>1. Topladığımız veriler</h2>
<ul>
    <li><b>Hesap bilgileri:</b> ad, e-posta adresi, şifrenin geri döndürülemez özeti (hash).</li>
    <li><b>Profil ve sağlıkla ilgili bilgiler:</b> cinsiyet, doğum tarihi, boy, kilo, hedef kilo, aktivite seviyesi, isteğe bağlı vücut yağ oranı.</li>
    <li><b>Kullanım verileri:</b> eklediğiniz öğünler ve yemekler, su ve aktivite kayıtları, kilo geçmişi.</li>
    <li><b>Yemek fotoğrafları:</b> yapay zekâ analizi için gönderdiğiniz fotoğraflar (gönderilmeden önce küçültülür).</li>
    <li><b>Satın alma bilgileri:</b> abonelik durumu, ürün ve işlem kimliği. Kart veya ödeme bilgileriniz Apple / Google tarafından işlenir; bize iletilmez.</li>
    <li><b>Teknik veriler:</b> uygulama sürümü, cihaz türü, hata kayıtları, IP adresi (güvenlik ve kötüye kullanımı önleme amacıyla).</li>
</ul>
<p>Uygulama; konum, rehber, mikrofon verilerinize erişmez. Kamera ve fotoğraf arşivi yalnızca siz yemek fotoğrafı çektiğinizde veya seçtiğinizde, izninizle kullanılır.</p>

<h2>2. Verileri kullanma amaçlarımız</h2>
<ul>
    <li>Günlük kalori ve makro hedefinizi hesaplamak, öğün ve ilerleme takibini sunmak,</li>
    <li>Yemek fotoğrafından kalori tahmini yapmak,</li>
    <li>Premium aboneliğinizi doğrulamak ve yönetmek,</li>
    <li>Hizmetin güvenliğini sağlamak, kötüye kullanımı ve dolandırıcılığı önlemek,</li>
    <li>Destek taleplerinize yanıt vermek, yasal yükümlülüklerimizi yerine getirmek.</li>
</ul>
<p>Verilerinizi <b>reklam amacıyla kullanmayız, satmayız</b> ve sizi farklı uygulama ya da web siteleri arasında izlemeyiz (App Tracking Transparency kapsamında "izleme" yapılmaz).</p>

<h2>3. Paylaştığımız üçüncü taraflar (veri işleyenler)</h2>
<ul>
    <li><b>Yapay zekâ sağlayıcısı (OpenRouter ve aracılık ettiği model sağlayıcıları):</b> yalnızca analiz edilecek yemek fotoğrafı gönderilir; adınız veya e-postanız gönderilmez.</li>
    <li><b>RevenueCat:</b> abonelik durumunun doğrulanması için kullanıcı kimliği (numara) ve satın alma bilgisi.</li>
    <li><b>Apple App Store / Google Play:</b> satın alma ve ödeme işlemleri.</li>
    <li><b>Open Food Facts:</b> barkod okuttuğunuzda yalnızca barkod numarası sorgulanır.</li>
    <li><b>Barındırma hizmeti:</b> verilerin saklandığı sunucu sağlayıcısı.</li>
</ul>
<p>Bu sağlayıcılardan bazıları yurt dışında bulunabilir; aktarım, KVKK ve ilgili mevzuata uygun şekilde yapılır.</p>

<h2>4. Saklama süresi</h2>
<p>Verileriniz hesabınız açık olduğu sürece saklanır. Hesabınızı sildiğinizde kişisel verileriniz ve fotoğraflarınız en geç 30 gün içinde kalıcı olarak silinir; yasal olarak saklanması zorunlu kayıtlar (ör. fatura) ilgili süre boyunca tutulur.</p>

<h2>5. Haklarınız</h2>
<p>Verilerinize erişme, düzeltme, silme, işlemeye itiraz etme ve verilerinizin bir kopyasını isteme hakkına sahipsiniz. Hesabınızı uygulamada <b>Profil &gt; Verilerim &gt; Hesabımı ve verilerimi sil</b> yoluyla doğrudan silebilirsiniz. Diğer talepler için <a href="mailto:{{ $s['kvkk_email'] }}">{{ $s['kvkk_email'] }}</a> adresine yazabilirsiniz. Ayrıntılar: <a href="{{ route('site.kvkk') }}">KVKK Aydınlatma Metni</a>.</p>

<h2>6. Çocuklar</h2>
<p>Hizmet 13 yaşından küçükler için tasarlanmamıştır ve bilerek bu yaştaki kişilerden veri toplamayız. 18 yaşından küçük kullanıcılar uygulamayı ebeveyn veya vasi onayıyla kullanmalıdır.</p>

<h2>7. Güvenlik</h2>
<p>Veriler şifreli bağlantı (HTTPS) üzerinden iletilir; şifreler geri döndürülemez biçimde saklanır; yönetim paneline erişim yetkili kişilerle sınırlıdır.</p>

<h2>8. Sağlık uyarısı</h2>
<p>Uygulamadaki kalori ve besin değerleri tahminidir ve tıbbi tavsiye yerine geçmez. Sağlık durumunuzla ilgili kararlar için bir hekime veya diyetisyene danışın.</p>

<h2>9. Değişiklikler ve iletişim</h2>
<p>Bu politikayı güncelleyebiliriz; önemli değişiklikleri uygulama içinden bildiririz. Sorularınız için: <a href="mailto:{{ $s['email'] }}">{{ $s['email'] }}</a> · {{ $s['company'] }}, {{ $s['address'] }}</p>
@endsection
