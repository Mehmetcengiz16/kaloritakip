<script setup>
import { ref } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import { Plus, Pencil, Trash2, KeyRound, AlertTriangle, Eye, EyeOff, PlugZap, CheckCircle2, RefreshCw, Search, ImageIcon } from 'lucide-vue-next';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Modal from '@/Components/Modal.vue';
import FieldError from '@/Components/FieldError.vue';
import { usd } from '@/lib/format';

const props = defineProps({ models: Array, settings: Object, apiKey: Object, pricesSyncedAt: String, fx: Object });

const fxSyncing = ref(false);
const syncFx = () =>
    router.post('/admin/settings/fx-sync', {}, {
        preserveScroll: true,
        onStart: () => (fxSyncing.value = true),
        onFinish: () => (fxSyncing.value = false),
        onSuccess: (page) => (settingsForm.usd_try_rate = page.props.settings.usd_try_rate),
    });
const fxLabel = () =>
    props.fx.synced_at
        ? `${props.fx.source ?? ''} · ${new Date(props.fx.synced_at).toLocaleString('tr-TR', { dateStyle: 'short', timeStyle: 'short' })}`
        : 'henüz güncellenmedi';

const syncing = ref(false);
const syncPrices = () =>
    router.post('/admin/ai-models/sync-prices', {}, { preserveScroll: true, onStart: () => (syncing.value = true), onFinish: () => (syncing.value = false) });
const syncedLabel = () =>
    props.pricesSyncedAt ? new Date(props.pricesSyncedAt).toLocaleString('tr-TR', { dateStyle: 'short', timeStyle: 'short' }) : 'henüz güncellenmedi';

// OpenRouter kataloğunda arama (model ekleme penceresi)
const catalogQuery = ref('');
const catalog = ref([]);
const catalogLoading = ref(false);
const catalogError = ref('');
let catalogTimer;
async function searchCatalog() {
    catalogLoading.value = true;
    catalogError.value = '';
    try {
        const { data } = await window.axios.get('/admin/ai-catalog', { params: { q: catalogQuery.value || undefined, purpose: modelForm.purpose } });
        catalog.value = data.data;
    } catch {
        catalogError.value = 'OpenRouter model listesi alınamadı.';
        catalog.value = [];
    } finally {
        catalogLoading.value = false;
    }
}
const onCatalogInput = () => {
    clearTimeout(catalogTimer);
    catalogTimer = setTimeout(searchCatalog, 300);
};
function pickModel(m) {
    modelForm.slug = m.slug;
    if (!modelForm.label) modelForm.label = m.name;
    modelForm.input_price_per_mtok = m.input_price_per_mtok;
    modelForm.output_price_per_mtok = m.output_price_per_mtok;
}

const keyForm = useForm({ api_key: '' });
const showKey = ref(false);
const editingKey = ref(!props.apiKey.configured);
const saveKey = () =>
    keyForm.put('/admin/settings/api-key', {
        preserveScroll: true,
        onSuccess: () => {
            keyForm.reset();
            editingKey.value = false;
        },
    });
const testKey = () => router.post('/admin/settings/api-key/test', {}, { preserveScroll: true });
const removeKey = () =>
    confirm('Paneldeki OpenRouter anahtarı silinsin mi?') &&
    router.delete('/admin/settings/api-key', { preserveScroll: true, onSuccess: () => (editingKey.value = !props.apiKey.configured) });

const settingsForm = useForm({ ...props.settings, usd_try_auto: props.fx.auto });
const saveSettings = () =>
    settingsForm.put('/admin/settings', {
        preserveScroll: true,
        onSuccess: (page) => (settingsForm.usd_try_rate = page.props.settings.usd_try_rate),
    });

const settingFields = [
    ['ai_free_daily_photo_limit', 'Ücretsiz kullanıcı günlük AI hakkı', 'adet', 'Gelir-gider dengesinin ana ayarı. Düşürmek maliyeti azaltır.'],
    ['ai_premium_daily_photo_limit', 'Premium kullanıcı günlük AI hakkı', 'adet', 'Adil kullanım sınırı.'],
    ['ai_daily_budget_usd', 'Günlük AI bütçesi', 'USD', 'Aşılınca ücretsiz kullanıcılarda AI geçici kapanır. 0 = sınırsız.'],
    ['ai_cost_ratio_alert_pct', 'AI / gelir uyarı eşiği', '%', 'Panelde uyarı gösterilecek oran.'],
    ['store_fee_pct', 'Mağaza komisyonu', '%', 'App Store / Google Play kesintisi.'],
];

const emptyModel = { slug: '', label: '', purpose: 'vision', priority: 1, is_active: true, input_price_per_mtok: 0, output_price_per_mtok: 0 };
const modelForm = useForm({ ...emptyModel });
const editing = ref(null);
const showModel = ref(false);

function openModel(m = null) {
    editing.value = m;
    modelForm.defaults(m ? { ...m } : { ...emptyModel });
    modelForm.reset();
    modelForm.clearErrors();
    catalogQuery.value = '';
    catalog.value = [];
    showModel.value = true;
    if (!m) searchCatalog();
}
function saveModel() {
    const opts = { preserveScroll: true, onSuccess: () => (showModel.value = false) };
    editing.value ? modelForm.put(`/admin/ai-models/${editing.value.id}`, opts) : modelForm.post('/admin/ai-models', opts);
}
const toggleModel = (m) => router.put(`/admin/ai-models/${m.id}`, { ...m, is_active: !m.is_active }, { preserveScroll: true });
const deleteModel = (m) => confirm(`${m.slug} silinsin mi?`) && router.delete(`/admin/ai-models/${m.id}`, { preserveScroll: true });

// 1.200 giriş + 150 çıkış token ≈ 1024 px fotoğraf analizi (tahmini)
const estimate = (m) => (1200 * m.input_price_per_mtok + 150 * m.output_price_per_mtok) / 1_000_000;
</script>

<template>
    <Head title="AI & Ayarlar" />
    <AdminLayout title="AI & Ayarlar">
        <div class="card mb-4 p-5">
            <div class="flex flex-wrap items-start gap-4">
                <span
                    :class="[
                        'flex h-11 w-11 shrink-0 items-center justify-center rounded-xl',
                        apiKey.configured ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger',
                    ]"
                >
                    <KeyRound class="h-5 w-5" />
                </span>
                <div class="min-w-0 flex-1">
                    <h3 class="font-bold">OpenRouter API Anahtarı</h3>
                    <p v-if="apiKey.configured" class="mt-0.5 flex flex-wrap items-center gap-2 text-sm text-ink-secondary">
                        <CheckCircle2 class="h-4 w-4 text-success" />
                        <code class="rounded bg-muted px-1.5 py-0.5 text-xs dark:bg-white/5">{{ apiKey.masked }}</code>
                        <span class="badge" :class="apiKey.source === 'panel' ? 'bg-primary-soft text-primary' : 'bg-track text-ink-secondary'">
                            {{ apiKey.source === 'panel' ? 'Panelden girildi' : '.env dosyasından' }}
                        </span>
                    </p>
                    <p v-else class="mt-0.5 text-sm text-danger">Anahtar girilmedi; fotoğraf analizi çalışmıyor.</p>
                    <p class="mt-1 text-xs text-ink-muted">
                        Anahtar veritabanında şifrelenerek saklanır ve bir daha açık olarak gösterilmez. Kaydetmeden önce OpenRouter'da doğrulanır.
                        Anahtarı <a href="https://openrouter.ai/settings/keys" target="_blank" rel="noopener" class="font-semibold text-primary">openrouter.ai/settings/keys</a>
                        adresinden oluşturabilirsin.
                    </p>
                </div>
                <div v-if="apiKey.configured && !editingKey" class="flex flex-wrap gap-2">
                    <button class="btn-outline h-9 px-3 text-xs" @click="testKey"><PlugZap class="h-4 w-4" /> Bağlantıyı test et</button>
                    <button class="btn-outline h-9 px-3 text-xs" @click="editingKey = true">Değiştir</button>
                    <button v-if="apiKey.source === 'panel'" class="btn-outline h-9 px-3 text-xs text-danger" @click="removeKey">
                        <Trash2 class="h-4 w-4" /> Sil
                    </button>
                </div>
            </div>

            <form v-if="editingKey" class="mt-4 flex flex-wrap items-start gap-2" @submit.prevent="saveKey">
                <div class="relative min-w-[260px] flex-1">
                    <input
                        v-model="keyForm.api_key"
                        :type="showKey ? 'text' : 'password'"
                        class="input pr-11 font-mono"
                        placeholder="sk-or-v1-..."
                        autocomplete="off"
                        spellcheck="false"
                        required
                    />
                    <button type="button" class="absolute right-3 top-3 text-ink-muted hover:text-ink" @click="showKey = !showKey">
                        <EyeOff v-if="showKey" class="h-4 w-4" /><Eye v-else class="h-4 w-4" />
                    </button>
                    <FieldError :message="keyForm.errors.api_key" />
                </div>
                <button type="submit" class="btn-primary" :disabled="keyForm.processing">
                    {{ keyForm.processing ? 'Doğrulanıyor…' : 'Doğrula ve Kaydet' }}
                </button>
                <button v-if="apiKey.configured" type="button" class="btn-outline" @click="(editingKey = false), keyForm.reset(), keyForm.clearErrors()">
                    Vazgeç
                </button>
            </form>
        </div>

        <div class="grid gap-4 xl:grid-cols-5">
            <div class="card xl:col-span-3">
                <div class="flex items-center justify-between border-b border-line p-5 dark:border-white/10">
                    <div>
                        <h3 class="font-bold">Yapay Zekâ Modelleri</h3>
                        <p class="text-xs text-ink-secondary">Öncelik 1 ana modeldir; hata verirse sıradaki yedek model denenir.</p>
                    </div>
                    <div class="flex items-center gap-2">
                        <button class="btn-outline h-9 px-3 text-xs" :disabled="syncing" title="Fiyatları OpenRouter'dan çek" @click="syncPrices">
                            <RefreshCw :class="['h-4 w-4', syncing && 'animate-spin']" /> Fiyatları güncelle
                        </button>
                        <button class="btn-primary h-9 px-3 text-xs" @click="openModel()"><Plus class="h-4 w-4" /> Model</button>
                    </div>
                </div>
                <div class="overflow-x-auto">
                    <table class="table-base">
                        <thead>
                            <tr>
                                <th>Model</th>
                                <th>Görev</th>
                                <th class="text-center">Sıra</th>
                                <th class="text-right">$/1M token (gir./çık.)</th>
                                <th class="text-right">≈ Analiz başı</th>
                                <th class="text-right"></th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="m in models" :key="m.id" :class="!m.is_active && 'opacity-50'">
                                <td>
                                    <span class="font-semibold">{{ m.label }}</span>
                                    <span class="block font-mono text-xs text-ink-secondary">{{ m.slug }}</span>
                                </td>
                                <td>
                                    <span :class="['badge', m.purpose === 'vision' ? 'bg-primary-soft text-primary' : 'bg-water/10 text-water']">
                                        {{ m.purpose === 'vision' ? 'Fotoğraf' : 'Metin' }}
                                    </span>
                                </td>
                                <td class="text-center font-semibold">{{ m.priority }}</td>
                                <td class="text-right text-xs">{{ usd(m.input_price_per_mtok) }} / {{ usd(m.output_price_per_mtok) }}</td>
                                <td class="text-right font-semibold">{{ usd(estimate(m), 5) }}</td>
                                <td>
                                    <div class="flex justify-end gap-1.5">
                                        <button class="btn-outline btn-sm" @click="toggleModel(m)">{{ m.is_active ? 'Pasif yap' : 'Aktif yap' }}</button>
                                        <button class="btn-outline btn-sm" title="Düzenle" @click="openModel(m)"><Pencil class="h-3.5 w-3.5" /></button>
                                        <button class="btn-outline btn-sm" title="Sil" @click="deleteModel(m)"><Trash2 class="h-3.5 w-3.5 text-danger" /></button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <p class="flex items-start gap-2 p-5 text-xs text-ink-secondary">
                    <AlertTriangle class="h-4 w-4 shrink-0 text-carb" />
                    <span>
                        Fiyatlar her gece OpenRouter'dan otomatik güncellenir (son güncelleme: <b>{{ syncedLabel() }}</b>). Gerçek maliyet her analizde
                        OpenRouter'dan alınır; buradaki fiyatlar tahmin ve yedek hesap içindir.
                    </span>
                </p>
            </div>

            <form class="card space-y-4 p-5 xl:col-span-2" @submit.prevent="saveSettings">
                <div>
                    <h3 class="font-bold">Kota ve Bütçe</h3>
                    <p class="text-xs text-ink-secondary">Değişiklikler anında mobil uygulamaya yansır.</p>
                </div>
                <div v-for="[key, label, unit, hint] in settingFields" :key="key">
                    <label class="label">{{ label }}</label>
                    <div class="relative">
                        <input v-model="settingsForm[key]" type="number" step="any" min="0" class="input pr-14" />
                        <span class="absolute right-4 top-3 text-xs font-semibold text-ink-muted">{{ unit }}</span>
                    </div>
                    <p class="mt-1 text-[11px] text-ink-muted">{{ hint }}</p>
                    <FieldError :message="settingsForm.errors[key]" />
                </div>
                <div>
                    <div class="mb-1.5 flex items-center justify-between">
                        <label class="label mb-0">USD / TL kuru</label>
                        <label class="flex cursor-pointer items-center gap-2 text-xs font-semibold text-ink-secondary">
                            Otomatik
                            <button
                                type="button"
                                role="switch"
                                :aria-checked="settingsForm.usd_try_auto"
                                :class="['relative h-5 w-9 rounded-full transition', settingsForm.usd_try_auto ? 'bg-primary' : 'bg-track dark:bg-white/15']"
                                @click="settingsForm.usd_try_auto = !settingsForm.usd_try_auto"
                            >
                                <span :class="['absolute top-0.5 h-4 w-4 rounded-full bg-white shadow transition-all', settingsForm.usd_try_auto ? 'left-[18px]' : 'left-0.5']" />
                            </button>
                        </label>
                    </div>
                    <div class="flex gap-2">
                        <div class="relative flex-1">
                            <input
                                v-model="settingsForm.usd_try_rate"
                                type="number"
                                step="any"
                                min="0"
                                class="input pr-10"
                                :readonly="settingsForm.usd_try_auto"
                                :class="settingsForm.usd_try_auto && 'cursor-not-allowed opacity-70'"
                            />
                            <span class="absolute right-4 top-3 text-xs font-semibold text-ink-muted">₺</span>
                        </div>
                        <button
                            v-if="settingsForm.usd_try_auto"
                            type="button"
                            class="btn-outline h-11 w-11 px-0"
                            title="Şimdi güncelle"
                            :disabled="fxSyncing"
                            @click="syncFx"
                        >
                            <RefreshCw :class="['h-4 w-4', fxSyncing && 'animate-spin']" />
                        </button>
                    </div>
                    <p class="mt-1 text-[11px] text-ink-muted">
                        <template v-if="settingsForm.usd_try_auto">
                            TCMB döviz satış kurundan günde 4 kez otomatik güncellenir (son: <b>{{ fxLabel() }}</b>).
                        </template>
                        <template v-else>Elle girilen kur kullanılır. AI maliyetinin TL karşılığı için.</template>
                    </p>
                    <FieldError :message="settingsForm.errors.usd_try_rate" />
                </div>
                <button type="submit" class="btn-primary w-full" :disabled="settingsForm.processing">Ayarları Kaydet</button>
            </form>
        </div>

        <Modal :show="showModel" :title="editing ? 'Modeli Düzenle' : 'Yeni Model'" @close="showModel = false">
            <form class="space-y-4" @submit.prevent="saveModel">
                <div v-if="!editing">
                    <label class="label">OpenRouter'da ara</label>
                    <div class="relative">
                        <Search class="absolute left-3.5 top-3.5 h-4 w-4 text-ink-muted" />
                        <input v-model="catalogQuery" class="input pl-10" placeholder="ör. gemini, gpt-4o-mini, claude" @input="onCatalogInput" />
                    </div>
                    <p class="mt-1 text-[11px] text-ink-muted">
                        {{ modelForm.purpose === 'vision' ? 'Sadece fotoğraf okuyabilen modeller, ucuzdan pahalıya.' : 'Tüm modeller, ucuzdan pahalıya.' }}
                        Seçince fiyatlar otomatik dolar.
                    </p>
                    <div class="mt-2 max-h-52 overflow-y-auto rounded-xl border border-line dark:border-white/10">
                        <p v-if="catalogLoading" class="p-3 text-xs text-ink-muted">Yükleniyor…</p>
                        <p v-else-if="catalogError" class="p-3 text-xs text-danger">{{ catalogError }}</p>
                        <p v-else-if="!catalog.length" class="p-3 text-xs text-ink-muted">Sonuç yok.</p>
                        <template v-else>
                            <button
                                v-for="m in catalog"
                                :key="m.slug"
                                type="button"
                                :class="[
                                    'flex w-full items-center justify-between gap-3 border-b border-line px-3 py-2 text-left last:border-0 hover:bg-muted dark:border-white/10 dark:hover:bg-white/5',
                                    m.slug === modelForm.slug && 'bg-primary-soft dark:bg-primary/20',
                                ]"
                                @click="pickModel(m)"
                            >
                                <span class="min-w-0">
                                    <span class="flex items-center gap-1 truncate text-sm font-semibold">
                                        {{ m.name }} <ImageIcon v-if="m.vision" class="h-3.5 w-3.5 shrink-0 text-primary" />
                                    </span>
                                    <span class="block truncate font-mono text-[11px] text-ink-secondary">{{ m.slug }}</span>
                                </span>
                                <span class="shrink-0 text-right text-[11px]">
                                    <span class="block font-semibold">{{ usd(estimate(m), 5) }}<span class="font-normal text-ink-muted"> / analiz</span></span>
                                    <span class="text-ink-muted">{{ usd(m.input_price_per_mtok) }} / {{ usd(m.output_price_per_mtok) }}</span>
                                </span>
                            </button>
                        </template>
                    </div>
                </div>
                <div>
                    <label class="label">OpenRouter model kimliği</label>
                    <input v-model="modelForm.slug" class="input font-mono" placeholder="google/gemini-2.5-flash" :readonly="!!editing" required />
                    <FieldError :message="modelForm.errors.slug" />
                </div>
                <div>
                    <label class="label">Görünen ad</label>
                    <input v-model="modelForm.label" class="input" required />
                    <FieldError :message="modelForm.errors.label" />
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="label">Görev</label>
                        <select v-model="modelForm.purpose" class="input" @change="!editing && searchCatalog()">
                            <option value="vision">Fotoğraf analizi</option>
                            <option value="text">Metin (günlük öneri)</option>
                        </select>
                    </div>
                    <div>
                        <label class="label">Öncelik (1 = ana)</label>
                        <input v-model="modelForm.priority" type="number" min="1" max="9" class="input" required />
                    </div>
                    <div>
                        <label class="label">Giriş $/1M token <span class="font-normal text-ink-muted">(otomatik)</span></label>
                        <input v-model="modelForm.input_price_per_mtok" type="number" step="any" min="0" class="input" required />
                        <FieldError :message="modelForm.errors.input_price_per_mtok" />
                    </div>
                    <div>
                        <label class="label">Çıkış $/1M token <span class="font-normal text-ink-muted">(otomatik)</span></label>
                        <input v-model="modelForm.output_price_per_mtok" type="number" step="any" min="0" class="input" required />
                        <FieldError :message="modelForm.errors.output_price_per_mtok" />
                    </div>
                </div>
                <label class="flex items-center gap-2 text-sm">
                    <input v-model="modelForm.is_active" type="checkbox" class="h-4 w-4 accent-primary" /> Aktif
                </label>
                <div class="flex justify-end gap-2 pt-2">
                    <button type="button" class="btn-outline" @click="showModel = false">Vazgeç</button>
                    <button type="submit" class="btn-primary" :disabled="modelForm.processing">Kaydet</button>
                </div>
            </form>
        </Modal>
    </AdminLayout>
</template>
