<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Ai\AiQuota;
use App\Services\Ai\AiUnavailableException;
use App\Services\Ai\FoodPhotoAnalyzer;
use Illuminate\Http\Request;
use InvalidArgumentException;

class AiController extends Controller
{
    public function __construct(private AiQuota $quota) {}

    public function quota(Request $request)
    {
        return ['data' => $this->quota->status($request->user())];
    }

    public function analyzePhoto(Request $request, FoodPhotoAnalyzer $analyzer)
    {
        $request->validate([
            'image' => ['required', 'file', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        $user = $request->user();

        if (! $this->quota->hasPhotoQuota($user)) {
            return response()->json([
                'message' => $user->isPremium()
                    ? 'Bugünkü AI analiz hakkını doldurdun. Yarın tekrar dene.'
                    : 'Bugünkü ücretsiz AI analiz hakkını kullandın. Premium ile daha fazla analiz yapabilirsin.',
                'code' => 'quota_exceeded',
                'quota' => $this->quota->status($user),
            ], 429);
        }

        if ($this->quota->budgetExceededFor($user)) {
            return response()->json([
                'message' => 'AI analizi şu an yoğunluk nedeniyle geçici olarak kullanılamıyor. Arama veya barkod ile ekleyebilirsin.',
                'code' => 'budget_exceeded',
            ], 503);
        }

        try {
            $analysis = $analyzer->analyze($user, $request->file('image'));
        } catch (InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage(), 'code' => 'invalid_image'], 422);
        } catch (AiUnavailableException $e) {
            return response()->json(['message' => 'AI analizi şu an yapılamıyor. Lütfen biraz sonra tekrar dene.', 'code' => 'ai_unavailable'], 503);
        }

        if ($analysis->status === 'failed') {
            return response()->json(['message' => 'Fotoğraf analiz edilemedi. Lütfen tekrar dene.', 'code' => 'ai_failed'], 502);
        }

        return response()->json(['data' => [
            'id' => $analysis->id,
            'is_food' => $analysis->status === 'done',
            'items' => $analysis->result_json['items'] ?? [],
            'total_kcal' => $analysis->result_json['total_kcal'] ?? 0,
            'from_cache' => $analysis->from_cache,
            'quota' => $this->quota->status($user),
        ]]);
    }
}
