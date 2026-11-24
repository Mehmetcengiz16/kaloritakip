# KaloriTakip – Proje Planı

> Yapay zekâ ile yemek fotoğrafından kalori analizi yapan kalori takip uygulaması.
> **Mobil:** Flutter · **Backend + Admin:** Laravel + MySQL · **AI:** OpenRouter (vision modelleri)

---

## 1. Genel Mimari

```
┌──────────────┐   HTTPS/JSON (Sanctum token)   ┌─────────────────────────┐
│ Flutter App  │ ─────────────────────────────▶ │ Laravel API (v1)        │
│ (iOS/Android)│ ◀───────────────────────────── │  ├─ Admin Panel (Inertia)│
└──────────────┘                                 │  ├─ Queue (Redis/Horizon)│
       │ IAP (App Store / Google Play)           │  └─ Scheduler (cron)    │
       ▼                                         └──────────┬──────────────┘
 RevenueCat (abonelik doğrulama, webhook) ─────────────────▶│
                                                            ▼
                                      MySQL 8 · Redis · S3 uyumlu depolama
                                                            │
                                                            ▼
                                                 OpenRouter API (vision LLM)
```

**Kritik kural:** OpenRouter API anahtarı **asla** mobil uygulamada bulunmaz. Tüm AI çağrıları Laravel üzerinden yapılır; böylece kota, maliyet ve kötüye kullanım sunucuda kontrol edilir.

---

## 2. Tasarım Sistemi (görsele birebir uyum)

### 2.1 Renkler
| Token | Değer (tahmini, Figma/görselden pipet ile doğrulanacak) | Kullanım |
|---|---|---|
| `primary` | `#7C3AED` | Butonlar, aktif sekme, halka grafik |
| `primaryGradient` | `#8B5CF6 → #6D28D9` | “Hemen Başla”, “Devam Et”, “Listeye Ekle” |
| `primarySoft` | `#F3EEFF` | Seçili kart arka planı, AI etiketleri, segment seçili |
| `background` | `#FFFFFF` / `#FAFAFC` | Ekran zemini |
| `cardBorder` | `#ECEBF2` | Kart kenarları |
| `textPrimary` | `#1A1A2E` | Başlıklar |
| `textSecondary` | `#6B7280` | Alt metinler |
| `protein` | `#7C3AED` | Protein bar |
| `carb` | `#F59E0B` | Karbonhidrat bar |
| `fat` | `#FACC15` | Yağ bar |
| `success` | `#22C55E` | Onay ikonları, “Aktivite 320 kcal”, kilo düşüşü |
| `water` | `#3B82F6` | Su ilerleme barı |

### 2.2 Tipografi & Bileşenler
- Font: **Inter** (veya Plus Jakarta Sans) – başlık 22–24 bold, gövde 14–15, etiket 11–12.
- Kart radius: **16**, buton radius: **14**, buton yüksekliği: **52**.
- Gölge: çok hafif (`blur 12, opacity 0.04`).
- İkonlar: line-style (Lucide / Phosphor), aktif ikon mor.
- Bottom nav: 5 sekme → **Ana Sayfa · Beslenme · Analiz · Plan · Profil**.
- Ortak widget’lar: `PrimaryButton`, `OutlineButton`, `SelectableOptionCard`, `MacroCard`, `CalorieRing`, `MealListTile`, `SegmentedTabs`, `StatCard`, `SettingsTile`, `ProgressBar`.

### 2.3 Birebir uyum süreci
1. Görseldeki 10 ekran tek tek ekran görüntüsü olarak `design/` klasörüne konur.
2. Her ekran için **golden test** (`flutter test --update-goldens`) yazılır, tasarımla üst üste bindirilerek piksel farkı kontrol edilir.
3. Mümkünse tasarım Figma’ya aktarılıp renk/ölçüler oradan alınır.

---

## 3. Ekranlar (Flutter)

| # | Ekran | İçerik | API |
|---|---|---|---|
| 1 | **Splash / Karşılama** | Logo, slogan, kase görseli, “Hemen Başla”, “Hesabın Var mı? Giriş Yap” | – |
| 2 | **Onboarding (1/4 – 4/4)** | Hedef seçimi (Kilo Vermek / Almak / Korumak / Sağlıklı Beslenme) → cinsiyet/yaş → boy/kilo/hedef kilo → aktivite seviyesi | `POST /onboarding` |
| 3 | **Ana Sayfa** | Selam + hedef, kalan kalori halkası, makro kartları, Yemek Ekle / AI ile Analiz / Planım kısayolları, bugünkü tüketimler | `GET /dashboard` |
| 4 | **Yemek Ekle** | Sekmeler: Ara · Barkod · Fotoğraf (AI). Kamera çerçevesi, “Yapay Zekâ Analizi” sonuç listesi, “Listeye Ekle (480 kcal)” | `POST /ai/analyze-photo`, `GET /foods/search`, `GET /foods/barcode/{code}` |
| 5 | **AI Beslenme Analizi** | Günlük özet (1.950 / 2.200), AI önerileri | `GET /ai/daily-insight` |
| 6 | **Beslenme** | Tarih seçici, öğün listesi (Kahvaltı, Ara Öğün, Öğle, Ara Öğün, Akşam), “+ Yemek Ekle” | `GET /meals?date=` |
| 7 | **İlerleme** | Haftalık/Aylık/Yıllık, kilo çizgi grafiği (fl_chart), Kilo / Yağ Oranı / BMI kartları | `GET /progress?range=` |
| 8 | **Diyet Planım** | Kilo Verme/Alma/Koruma segmenti, günlük hedef, örnek günlük plan | `GET /diet-plans?goal=` |
| 9 | **Su ve Aktivite** | Su tüketimi (+250 ml / +500 ml / +1 L), aktiviteler (Yürüyüş, Bisiklet, Diğer) | `POST /water`, `POST /activities` |
| 10 | **Profil** | Kullanıcı kartı, Hedef ve Bilgilerim, Bildirimler (switch), Verilerim, Diyet Planım, Uygulama Ayarları | `GET/PUT /me` |
| + | **Paywall / Premium** | Tasarıma uygun mor tema ile abonelik ekranı (gelir modeli için gerekli) | RevenueCat |
| + | Giriş / Kayıt | E-posta, Google, Apple ile giriş | `POST /auth/*` |

### 3.1 Flutter Teknik Yapı
- **State:** Riverpod · **Routing:** go_router · **HTTP:** dio (+ interceptor ile token yenileme)
- **Model:** freezed + json_serializable · **Yerel önbellek:** Hive / Isar (offline günlük)
- **Grafik:** fl_chart · **Kamera:** camera + image_picker · **Barkod:** mobile_scanner
- **Görsel sıkıştırma:** flutter_image_compress (≤ 1024 px, JPEG %75 → ~150 KB) – **AI maliyetini doğrudan düşürür**
- **Abonelik:** purchases_flutter (RevenueCat) · **Bildirim:** firebase_messaging
- **Dil:** flutter_localizations (TR önce, EN sonra)

```
lib/
  core/        (theme, colors, typography, router, dio_client, env)
  shared/      (widgets: buttons, cards, ring, tiles)
  features/
    auth/ onboarding/ home/ add_food/ ai_insight/
    nutrition/ progress/ diet_plan/ water_activity/ profile/ paywall/
    └─ data/ (repo, dto)  domain/ (model)  presentation/ (screens, providers)
```

---

## 4. Backend – Laravel 11 + MySQL 8

### 4.1 Paketler
- **Laravel Sanctum** (mobil token auth), **Socialite** (Google/Apple)
- **Inertia.js + Vue 3 + Tailwind CSS** (özel tasarım admin panel – hazır panel paketi kullanılmaz, bkz. 4.4)
- **Laravel Horizon + Redis** (AI isteklerini kuyrukta işleme, rate limit)
- **Intervention Image** (sunucu tarafı ikinci sıkıştırma / doğrulama)
- **spatie/laravel-permission** (admin rolleri), **spatie/laravel-activitylog**

### 4.2 Veritabanı Şeması (özet)
| Tablo | Önemli alanlar |
|---|---|
| `users` | id, name, email, password, provider, avatar, locale, is_premium, premium_until |
| `user_profiles` | user_id, gender, birth_date, height_cm, weight_kg, target_weight_kg, goal (lose/gain/maintain/healthy), activity_level, daily_kcal_target, protein_g, carb_g, fat_g, water_ml_target |
| `foods` | id, name, brand, barcode, kcal_per_100g, protein, carb, fat, source (manual/openfoodfacts/ai), verified |
| `meals` | id, user_id, date, type (breakfast/snack1/lunch/snack2/dinner), total_kcal |
| `meal_items` | meal_id, food_id (nullable), name, grams, kcal, protein, carb, fat, ai_analysis_id (nullable) |
| `ai_analyses` | id, user_id, image_path, image_hash, model, prompt_tokens, completion_tokens, **cost_usd**, result_json, status, latency_ms |
| `ai_insights` | user_id, date, content_json, cost_usd |
| `weight_logs` | user_id, date, weight_kg, body_fat_pct |
| `water_logs` | user_id, date, amount_ml |
| `activities` / `activity_logs` | tür, MET değeri / user_id, activity_id, minutes, kcal |
| `diet_plans` / `diet_plan_meals` | goal, kcal / plan_id, meal_type, title, description, kcal |
| `subscriptions` | user_id, store, product_id, status, started_at, expires_at, price, currency |
| `usage_quotas` | user_id, date, ai_photo_count, ai_insight_count |
| `ai_models` | name (openrouter slug), input_price, output_price, is_active, priority, purpose |
| `settings` | key/value (ücretsiz limit, aktif model, prompt şablonları…) |
| `expenses` | kategori (sunucu, OpenRouter, mağaza komisyonu, reklam), tutar, tarih |

### 4.3 API Uç Noktaları (`/api/v1`)
```
POST   /auth/register | /auth/login | /auth/social | /auth/logout
POST   /onboarding                     → hedef kalori/makro hesaplanır (Mifflin-St Jeor)
GET    /me            PUT /me
GET    /dashboard?date=
GET    /meals?date=   POST /meals/{type}/items   DELETE /meal-items/{id}
GET    /foods/search?q=   GET /foods/barcode/{code}
POST   /ai/analyze-photo   (multipart)  → kota kontrolü → kuyruk → sonuç
GET    /ai/analyze-photo/{id}           → (polling veya anlık dönüş)
GET    /ai/daily-insight?date=
GET    /progress?range=week|month|year   POST /weight-logs
POST   /water   POST /activities   GET /activities/today
GET    /diet-plans?goal=
GET    /subscription/status   POST /webhooks/revenuecat
```

### 4.4 Admin Panel (özel tasarım – mobil uygulamayla aynı görsel dil)

**Teknoloji:** Laravel + **Inertia.js + Vue 3 + Tailwind CSS** (tek repo, ayrı API gerekmez, SPA hissi).
UI bileşenleri: **shadcn-vue** (Radix tabanlı, tamamen özelleştirilebilir), ikonlar **Lucide** (mobil ile aynı set), grafikler **ApexCharts**, tablolar **TanStack Table**.

**Tema (mobil uygulamanın tasarım token'ları birebir kullanılır):**
- Tailwind config'te aynı renkler: `primary #7C3AED`, `primary-soft #F3EEFF`, protein/karb/yağ/su/success renkleri
- Font **Inter**, kart radius 16, buton radius 14, çok hafif gölge, ince `#ECEBF2` kenarlıklar
- Mor gradient birincil butonlar, yumuşak mor seçili durumlar, segment kontroller (Haftalık/Aylık/Yıllık) mobildeki gibi
- Sol tarafta beyaz, sade sidebar (aktif menü mor arka planlı), üstte arama + bildirim + profil
- KPI kartları mobildeki makro kartları stilinde; halka grafik (kalan kalori halkası gibi) bütçe kullanımı için
- **Açık / koyu tema** desteği, responsive (tablet/telefondan da yönetilebilir)

**Sayfalar:**
- **Dashboard:** günlük aktif kullanıcı, yeni kayıt, premium dönüşüm oranı, günlük AI istek sayısı, **günlük/aylık AI maliyeti**, **gelir – gider – net kâr** grafikleri
- **Kullanıcılar:** listele, detay, premium ver/al, kota sıfırla, engelle
- **Yemek veritabanı:** CRUD, AI’dan gelen yemekleri doğrula (verified) → sonraki aramalarda ücretsiz kullanılır
- **AI Analiz Kayıtları:** görsel + sonuç + maliyet + kullanıcı düzeltmesi (kalite takibi)
- **AI Model Yönetimi:** aktif modeli seç, fallback sırası, prompt şablonları, fiyatlar
- **Diyet Planları & Aktiviteler:** CRUD
- **Abonelikler & Gelir:** RevenueCat verileri, MRR, churn
- **Giderler:** sunucu, depolama, mağaza komisyonu kalemleri
- **Ayarlar:** ücretsiz kullanıcı günlük foto limiti, premium limit, bakım modu, maliyet alarm eşiği

---

## 5. Yapay Zekâ – OpenRouter Entegrasyonu

### 5.1 Akış
1. Kullanıcı fotoğraf çeker → cihazda sıkıştırılır (≤1024 px).
2. `POST /ai/analyze-photo` → Laravel: auth, **kota kontrolü**, dosya tipi/boyut doğrulama.
3. Görselin **perceptual hash**’i hesaplanır; aynı/çok benzer görsel daha önce analiz edildiyse **önbellekten** döner (maliyet 0).
4. `AnalyzeFoodPhotoJob` kuyruğa alınır → OpenRouter `chat/completions` (image_url base64 + JSON şema).
5. Yanıt doğrulanır (JSON schema), `ai_analyses` tablosuna **token ve maliyet** ile yazılır.
6. Kullanıcı porsiyonları düzenleyip “Listeye Ekle” der → `meal_items`.

### 5.2 Prompt (özet)
```
Sen bir beslenme uzmanısın. Fotoğraftaki yemekleri tespit et.
Sadece şu JSON formatında yanıt ver:
{"items":[{"name_tr":"Tavuk ızgara","grams":100,"kcal":180,"protein":31,"carb":0,"fat":5,"confidence":0.85}],
 "total_kcal":480,"is_food":true}
Türk mutfağını dikkate al. Porsiyonu tabak boyutuna göre tahmin et. Yemek yoksa is_food=false.
```
`response_format: { type: "json_schema" }` desteklenen modellerde kullanılır; `max_tokens` ≈ 400 ile sınırlandırılır.

### 5.3 Model Stratejisi (admin panelden değiştirilebilir)
| Kademe | Model sınıfı (OpenRouter) | Kullanım |
|---|---|---|
| Varsayılan | Ucuz & hızlı vision modeli (örn. Gemini Flash / GPT‑4o‑mini sınıfı) | Tüm foto analizleri |
| Fallback | Alternatif sağlayıcıdaki benzer ucuz model | Hata / timeout |
| Günlük öneri (AI Analiz ekranı) | Metin modeli, sadece sayısal özet gönderilir (görsel yok) | Günde 1 kez, sonuç cache’lenir |

> Fiyatlar sık değişir; geliştirme başında OpenRouter fiyat sayfasından güncel değerler alınıp `ai_models` tablosuna girilir. Tahmini maliyet: **foto analizi başına ~$0.0005 – $0.003** (sıkıştırılmış görsel + kısa çıktı ile).

### 5.4 Maliyet Koruma Önlemleri
- Cihazda + sunucuda görsel küçültme (token sayısını belirleyen ana etken)
- Görsel hash önbelleği + doğrulanmış yemekler tablosuna aktarma
- Kullanıcı başı günlük kota (`usage_quotas`) + Laravel `RateLimiter`
- `is_food=false` → istek kotadan düşer ama tekrar denemede uyarı (kötüye kullanım)
- **Günlük global bütçe tavanı:** admin’de belirlenen $ limitini aşınca ücretsiz kullanıcılar için AI geçici kapanır, premium devam eder
- Maliyet alarmı (e‑posta/Telegram) eşik aşıldığında
- Günlük AI öneri metni günde 1 kez üretilir, tekrar istekte cache’ten döner

---

## 6. Gelir – Gider Dengesi ve Kârlılık

### 6.1 Gelir Modeli (Freemium)
| Paket | Fiyat (öneri, TR) | Özellikler |
|---|---|---|
| **Ücretsiz** | 0 ₺ | Manuel ekleme, barkod, su/aktivite, **günde 2 AI foto analizi**, temel grafik, (opsiyonel) banner reklam |
| **Premium Aylık** | 129–149 ₺ | Günde 30 AI analiz (fair use), AI günlük öneri, tüm diyet planları, yıllık grafik, reklamsız |
| **Premium Yıllık** | 899–999 ₺ (~%45 indirim) | Aylık ile aynı, nakit akışı için teşvik edilir |
| 7 gün ücretsiz deneme | – | Yıllık pakette, dönüşümü artırır |

Ek gelir: ücretsiz kullanıcılarda AdMob (ödüllü reklam izle → +1 AI analiz hakkı). Bu sayede ücretsiz kullanıcının AI maliyeti reklamla karşılanır.

### 6.2 Birim Ekonomi (tahmini)
| Kalem | Premium kullanıcı / ay |
|---|---|
| Brüt gelir (aylık 139 ₺) | 139 ₺ |
| Mağaza komisyonu (%15, küçük işletme programı) | −21 ₺ |
| AI maliyeti (ort. 5 foto/gün × 30 × ~$0.002 + öneriler) ≈ $0.35 | ≈ −12 ₺ |
| Sunucu/depolama payı | ≈ −3 ₺ |
| **Kullanıcı başı katkı payı** | **≈ 100 ₺ (~%72)** |

| Kalem | Ücretsiz kullanıcı / ay |
|---|---|
| AI (ort. 1 foto/gün) ≈ $0.06 | ≈ −2 ₺ |
| Sunucu payı | ≈ −0,5 ₺ |
| Reklam geliri | ≈ +1 – 4 ₺ |
| **Net** | **≈ başa baş** |

**Sabit giderler (aylık, başlangıç):** VPS/Cloud (~$20–40), depolama/CDN (~$5), domain/e‑posta, Apple Developer ($99/yıl), Google Play ($25 tek sefer).
**Başa baş noktası:** ≈ 25–40 premium abone.

### 6.3 Dengeyi Koruyan Mekanizmalar
- Admin panelde **canlı kârlılık paneli:** `gelir − (mağaza komisyonu + AI maliyeti + sabit giderler)`
- **Hedef oran:** AI maliyeti / gelir ≤ %15. Aşılırsa:
  1. Daha ucuz modele geçiş (admin’den tek tıkla)
  2. Ücretsiz limitin düşürülmesi (2 → 1)
  3. Görsel çözünürlüğünün düşürülmesi
- Kullanıcı başı maliyet anomalisi tespiti (günde 30+ istek → incele)
- Doğrulanan AI sonuçlarının `foods` tablosuna aktarılması → zamanla arama ile ücretsiz eşleşme oranı artar
- Silinmiş/eski görsellerin 30 gün sonra depolamadan temizlenmesi (scheduler)

---

## 7. Güvenlik & Uyumluluk
- KVKK: aydınlatma metni, açık rıza, hesap ve veri silme (`DELETE /me`) – App Store zorunluluğu
- Sağlık verisi uyarısı: “Tıbbi tavsiye değildir” bildirimi
- HTTPS, Sanctum token, rate limit, dosya doğrulama (sadece jpeg/png/webp, ≤ 5 MB)
- `.env` içinde OpenRouter anahtarı; admin panelde 2FA
- Günlük otomatik MySQL yedeği

---

## 8. Yol Haritası (tahmini ~11–13 hafta)

| Faz | Süre | Çıktı |
|---|---|---|
| **0 – Hazırlık** | 3 gün | Repo yapısı (`/backend`, `/mobile`), tasarım token’ları, Figma/asset hazırlığı |
| **1 – Backend çekirdek** | 1,5 hafta | Laravel kurulum, migration’lar, auth, profil, onboarding hesaplama, meals/foods API |
| **2 – Flutter iskelet & tasarım sistemi** | 1,5 hafta | Tema, ortak widget’lar, router, karşılama + onboarding + ana sayfa birebir |
| **3 – AI entegrasyonu** | 1,5 hafta | OpenRouter servisi, kuyruk, kota, cache, maliyet loglama, Yemek Ekle (Fotoğraf AI) + AI Analiz ekranı |
| **4 – Diğer ekranlar** | 2 hafta | Beslenme, İlerleme, Diyet Planım, Su & Aktivite, Profil, barkod (Open Food Facts) |
| **5 – Admin panel** | 2,5 hafta | Tasarım sistemi (Tailwind tema + bileşenler), sayfalar, kârlılık dashboard’u, model/limit ayarları |
| **6 – Abonelik & reklam** | 1 hafta | RevenueCat, paywall, webhook, AdMob ödüllü reklam |
| **7 – Test & yayın** | 1,5 hafta | Golden testler, API feature testleri, beta (TestFlight / Internal testing), mağaza yayını |

---

## 9. Klasör Yapısı (repo)
```
kaloritakipapp/
├─ backend/          # Laravel 11 API + Inertia/Vue admin panel
├─ mobile/           # Flutter uygulaması
├─ design/           # Referans ekran görüntüleri, ikonlar, illüstrasyonlar
└─ PLAN.md
```

## 10. Netleştirilmesi Gerekenler
1. Uygulama sadece Türkiye pazarı mı, yoksa çok dilli mi başlasın?
2. Reklam (AdMob) ücretsiz sürümde olsun mu?
3. Sunucu tercihi (Hetzner/DigitalOcean VPS + Coolify mi, paylaşımlı hosting mi?)
4. Kalori/besin veritabanı kaynağı: Open Food Facts + kendi TR yemek listemiz yeterli mi?
5. Tasarımın Figma dosyası var mı? (Birebir uyum için en doğru kaynak)
