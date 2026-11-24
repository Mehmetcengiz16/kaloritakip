@extends('site.legal', ['title' => 'Kullanım Koşulları (EULA)'])
@php($s = config('site'))

@section('legal')
<p>Bu Kullanım Koşulları, {{ $s['app_name'] }} uygulamasını ve web sitesini ("Hizmet") kullanımınızı düzenleyen son kullanıcı lisans sözleşmesidir. Hizmeti indirerek veya kullanarak bu koşulları kabul etmiş olursunuz.</p>

<h2>1. Lisans</h2>
<p>{{ $s['company'] }}, size Hizmeti kişisel ve ticari olmayan amaçlarla, sahip olduğunuz veya kontrol ettiğiniz cihazlarda kullanmanız için münhasır olmayan, devredilemez, geri alınabilir bir lisans verir. Uygulama size satılmaz, lisanslanır.</p>
<p>Uygulamayı Apple App Store üzerinden edindiyseniz bu sözleşme, Apple'ın <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/" target="_blank" rel="noopener">Standart Son Kullanıcı Lisans Sözleşmesi</a> ile birlikte uygulanır; çelişki halinde bu sözleşme geçerlidir. Apple bu sözleşmenin tarafı değildir ve uygulamanın bakım, destek veya garantisinden sorumlu değildir; Apple ve bağlı şirketleri bu sözleşmenin üçüncü taraf lehtarlarıdır.</p>

<h2>2. Hesap</h2>
<p>Hesap oluştururken doğru bilgi vermeyi ve şifrenizi gizli tutmayı kabul edersiniz. Hesabınızla yapılan işlemlerden siz sorumlusunuz. Hizmeti kullanmak için en az 13 yaşında olmalısınız.</p>

<h2>3. Premium abonelik</h2>
<p>Premium özellikler otomatik yenilenen abonelik olarak sunulur. Fiyat, süre ve deneme koşulları satın almadan önce uygulamada gösterilir. Ayrıntılar <a href="{{ route('site.subscription') }}">Abonelik Koşulları</a> sayfasındadır.</p>

<h2>4. Yapay zekâ analizi ve sağlık uyarısı</h2>
<p>Fotoğraf analizi ve kalori değerleri tahminidir; hatalı olabilir. Hizmet tıbbi cihaz değildir, teşhis veya tedavi amaçlı değildir ve profesyonel sağlık tavsiyesinin yerine geçmez. Hamilelik, kronik hastalık, yeme bozukluğu gibi durumlarda diyet değişikliği yapmadan önce bir hekime danışın.</p>

<h2>5. Kabul edilemez kullanım</h2>
<ul>
    <li>Hizmeti yasa dışı amaçlarla veya başkalarının haklarını ihlal edecek şekilde kullanmak,</li>
    <li>Yemek dışı, müstehcen veya başkasına ait özel içerikli fotoğraflar yüklemek,</li>
    <li>Hizmetin güvenliğini aşmaya, tersine mühendisliğe, otomatik toplu istek göndermeye çalışmak,</li>
    <li>Kota ve sınırları aşmak amacıyla birden fazla hesap açmak.</li>
</ul>
<p>Bu kurallara aykırı kullanımda hesabınızı askıya alabilir veya kapatabiliriz.</p>

<h2>6. Fikri mülkiyet</h2>
<p>Uygulama, tasarım, yazılım ve içerikler {{ $s['company'] }}'ye veya lisans verenlerine aittir. Girdiğiniz verilerin sahibi sizsiniz; bunları yalnızca Hizmeti sunmak için işleriz.</p>

<h2>7. Sorumluluğun sınırlandırılması</h2>
<p>Hizmet "olduğu gibi" sunulur. Yürürlükteki mevzuatın izin verdiği ölçüde; tahmini kalori değerlerine dayanılarak alınan kararlardan, kesintilerden veya veri kaybından doğan dolaylı zararlardan sorumlu değiliz.</p>

<h2>8. Fesih</h2>
<p>Hesabınızı istediğiniz zaman uygulamadan silebilirsiniz. Aboneliği iptal etmek hesabı silmez; hesabı silmek de mağazadaki aboneliği otomatik iptal etmez — aboneliği App Store / Google Play'den ayrıca iptal etmelisiniz.</p>

<h2>9. Uygulanacak hukuk</h2>
<p>Bu sözleşme Türkiye Cumhuriyeti hukukuna tabidir. Tüketici olarak yerleşim yerinizdeki tüketici hakem heyetlerine ve tüketici mahkemelerine başvurma hakkınız saklıdır.</p>

<h2>10. İletişim</h2>
<p><a href="mailto:{{ $s['email'] }}">{{ $s['email'] }}</a> · {{ $s['company'] }}, {{ $s['address'] }}</p>
@endsection
