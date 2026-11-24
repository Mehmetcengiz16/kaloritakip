<?php

namespace App\Services\Ai;

use App\Models\AiAnalysis;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Throwable;

/**
 * Yemek fotoğrafını analiz eder: küçült -> önbellek kontrolü -> OpenRouter -> doğrula -> kaydet.
 */
class FoodPhotoAnalyzer
{
    public const PROMPT = <<<'TXT'
Sen deneyimli bir diyetisyensin. Fotoğraftaki yiyecek ve içecekleri tespit et ve porsiyonlarını tabak/kap boyutuna göre tahmin et.
Türk mutfağını dikkate al (ör. pilav, bulgur, mercimek çorbası, köfte, börek, dolma, ayran).
Her yiyecek için gram ve o porsiyonun toplam besin değerini ver.
SADECE şu JSON formatında yanıt ver, başka hiçbir metin yazma:
{"is_food": true, "items": [{"name": "Tavuk ızgara", "grams": 100, "kcal": 180, "protein": 31, "carb": 0, "fat": 5, "confidence": 0.85}]}
- name: Türkçe, kısa yemek adı
- grams, kcal: tam sayı; protein, carb, fat: gram, en fazla 1 ondalık
- confidence: 0 ile 1 arası
Fotoğrafta yiyecek yoksa: {"is_food": false, "items": []}
TXT;

    public function __construct(private OpenRouterClient $client, private AiQuota $quota) {}

    public function analyze(User $user, UploadedFile $file): AiAnalysis
    {
        $jpeg = $this->normalize($file);
        $hash = hash('sha256', $jpeg);

        // Aynı fotoğraf daha önce başarıyla analiz edildiyse önbellekten dön (maliyet 0, hak düşmez).
        $cached = AiAnalysis::where('image_hash', $hash)->where('status', 'done')->latest()->first();
        if ($cached) {
            return AiAnalysis::create([
                'user_id' => $user->id,
                'image_path' => $cached->image_path,
                'image_hash' => $hash,
                'model' => $cached->model,
                'from_cache' => true,
                'status' => 'done',
                'result_json' => $cached->result_json,
                'latency_ms' => 0,
            ]);
        }

        $path = 'ai/'.now()->format('Y/m/d').'/'.Str::uuid().'.jpg';
        Storage::disk('local')->put($path, $jpeg);

        $analysis = AiAnalysis::create([
            'user_id' => $user->id,
            'image_path' => $path,
            'image_hash' => $hash,
            'status' => 'pending',
        ]);

        $started = hrtime(true);
        try {
            $res = $this->client->chat('vision', [[
                'role' => 'user',
                'content' => [
                    ['type' => 'text', 'text' => self::PROMPT],
                    ['type' => 'image_url', 'image_url' => ['url' => 'data:image/jpeg;base64,'.base64_encode($jpeg)]],
                ],
            ]]);
        } catch (Throwable $e) {
            $analysis->update(['status' => 'failed', 'error' => mb_substr($e->getMessage(), 0, 1000)]);
            throw $e;
        }

        $result = $this->parse($res['content']);
        $analysis->update([
            'model' => $res['model'],
            'prompt_tokens' => $res['prompt_tokens'],
            'completion_tokens' => $res['completion_tokens'],
            'cost_usd' => $res['cost_usd'],
            'latency_ms' => (int) ((hrtime(true) - $started) / 1e6),
            'status' => $result === null ? 'failed' : ($result['is_food'] ? 'done' : 'not_food'),
            'result_json' => $result,
            'error' => $result === null ? 'Geçersiz yanıt: '.mb_substr($res['content'], 0, 500) : null,
        ]);

        // Model çağrıldıysa (maliyet oluştuysa) hak düşer; böylece yemek olmayan fotoğrafla kötüye kullanım sınırlanır.
        $this->quota->consumePhoto($user);

        return $analysis;
    }

    /** Fotoğrafı en uzun kenarı 1024 px olacak şekilde küçültür, EXIF'i atar, JPEG'e çevirir. */
    private function normalize(UploadedFile $file): string
    {
        $src = @imagecreatefromstring((string) file_get_contents($file->getRealPath()));
        if (! $src) {
            throw new \InvalidArgumentException('Fotoğraf okunamadı.');
        }

        $w = imagesx($src);
        $h = imagesy($src);
        $max = config('ai.image_max_side');
        $scale = min(1, $max / max($w, $h));
        $nw = (int) round($w * $scale);
        $nh = (int) round($h * $scale);

        $dst = imagecreatetruecolor($nw, $nh);
        imagefill($dst, 0, 0, imagecolorallocate($dst, 255, 255, 255));
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);

        ob_start();
        imagejpeg($dst, null, config('ai.image_quality'));

        return (string) ob_get_clean();
    }

    /** Model yanıtını doğrular ve temizler; geçersizse null. */
    public function parse(string $content): ?array
    {
        // Bazı modeller JSON'u ```json ... ``` içine koyar.
        if (preg_match('/\{.*\}/s', $content, $m)) {
            $content = $m[0];
        }
        $json = json_decode($content, true);
        if (! is_array($json) || ! isset($json['items']) || ! is_array($json['items'])) {
            return null;
        }

        $items = [];
        foreach (array_slice($json['items'], 0, 15) as $i) {
            if (! is_array($i) || empty($i['name'])) {
                continue;
            }
            $items[] = [
                'name' => mb_substr(trim((string) $i['name']), 0, 120),
                'grams' => max(1, min(3000, (int) round((float) ($i['grams'] ?? 100)))),
                'kcal' => max(0, min(5000, (int) round((float) ($i['kcal'] ?? 0)))),
                'protein' => round(max(0, (float) ($i['protein'] ?? 0)), 1),
                'carb' => round(max(0, (float) ($i['carb'] ?? 0)), 1),
                'fat' => round(max(0, (float) ($i['fat'] ?? 0)), 1),
                'confidence' => round(max(0, min(1, (float) ($i['confidence'] ?? 0.5))), 2),
            ];
        }

        $isFood = (bool) ($json['is_food'] ?? count($items) > 0) && count($items) > 0;

        return [
            'is_food' => $isFood,
            'items' => $isFood ? $items : [],
            'total_kcal' => array_sum(array_column($items, 'kcal')),
        ];
    }
}
