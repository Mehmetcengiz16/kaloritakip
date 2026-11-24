@extends('site.legal', ['title' => 'KVKK Aydınlatma Metni'])
@php($s = config('site'))

@section('legal')
<p>6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") uyarınca, veri sorumlusu sıfatıyla <b>{{ $s['company'] }}</b> ({{ $s['address'] }}) olarak kişisel verilerinizi aşağıda açıklanan kapsamda işlemekteyiz.</p>

<h2>1. İşlenen kişisel veriler</h2>
<ul>
    <li><b>Kimlik ve iletişim:</b> ad soyad, e-posta adresi.</li>
    <li><b>Özel nitelikli kişisel veri (sağlık):</b> kilo, boy, vücut yağ oranı, beslenme ve aktivite kayıtları, yemek fotoğrafları.</li>
    <li><b>Müşteri işlem:</b> abonelik ve satın alma kayıtları.</li>
    <li><b>İşlem güvenliği:</b> IP adresi, cihaz ve oturum bilgileri, hata kayıtları.</li>
</ul>

<h2>2. İşleme amaçları</h2>
<p>Üyelik oluşturulması ve yönetimi; kişiye özel kalori ve makro hedefi hesaplanması; beslenme, kilo, su ve aktivite takibinin sunulması; yemek fotoğraflarının yapay zekâ ile analiz edilmesi; abonelik ve ödeme süreçlerinin yürütülmesi; bilgi güvenliğinin sağlanması; talep ve şikâyetlerin yönetilmesi; mevzuattan doğan yükümlülüklerin yerine getirilmesi.</p>

<h2>3. Hukuki sebepler</h2>
<ul>
    <li>Sözleşmenin kurulması ve ifası (KVKK m.5/2-c),</li>
    <li>Hukuki yükümlülüğün yerine getirilmesi (m.5/2-ç),</li>
    <li>Meşru menfaat (m.5/2-f) — güvenlik ve kötüye kullanımın önlenmesi,</li>
    <li>Sağlık verileri bakımından <b>açık rızanız</b> (m.6/2). Hesap oluştururken ve profil bilgilerinizi girerken bu rızayı verirsiniz; dilediğiniz zaman geri alabilirsiniz (bu durumda kişiye özel hesaplamalar sunulamaz).</li>
</ul>

<h2>4. Aktarım</h2>
<p>Kişisel verileriniz; barındırma hizmeti sağlayıcısına, yapay zekâ analiz sağlayıcısına (yalnızca fotoğraf), abonelik doğrulama hizmetine (RevenueCat) ve uygulama mağazalarına (Apple, Google), yukarıdaki amaçlarla sınırlı olarak aktarılabilir. Bu sağlayıcıların bir kısmı yurt dışında yer aldığından aktarım, KVKK m.9 hükümlerine uygun olarak gerçekleştirilir. Yetkili kamu kurumlarına, kanuni zorunluluk halinde aktarım yapılabilir.</p>

<h2>5. Toplama yöntemi</h2>
<p>Veriler, mobil uygulama ve web sitesi üzerinden elektronik ortamda, doğrudan sizin tarafınızdan girilerek ve uygulamayı kullanımınız sırasında otomatik yollarla toplanır.</p>

<h2>6. Haklarınız (KVKK m.11)</h2>
<p>Kişisel verilerinizin işlenip işlenmediğini öğrenme, bilgi talep etme, amacına uygun kullanılıp kullanılmadığını öğrenme, aktarıldığı üçüncü kişileri bilme, eksik veya yanlış işlenmişse düzeltilmesini, silinmesini veya yok edilmesini isteme, otomatik sistemlerle analiz sonucu aleyhinize bir sonuç çıkmasına itiraz etme ve zarara uğramanız halinde tazminat talep etme haklarına sahipsiniz.</p>
<p>Başvurularınızı <a href="mailto:{{ $s['kvkk_email'] }}">{{ $s['kvkk_email'] }}</a> adresine, kayıtlı e-posta adresinizden iletebilirsiniz. Başvurular en geç 30 gün içinde ücretsiz olarak sonuçlandırılır.</p>
@endsection
