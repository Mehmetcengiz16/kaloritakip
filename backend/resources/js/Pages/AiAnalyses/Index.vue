<script setup>
import { ref, watch } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { DatabaseZap, ImageOff } from 'lucide-vue-next';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';
import Segments from '@/Components/Segments.vue';
import Modal from '@/Components/Modal.vue';
import { num, statusLabels, tl, tlFine, usd } from '@/lib/format';

const props = defineProps({ analyses: Object, filters: Object, usdTry: Number, totals: Object });

const status = ref(props.filters.status ?? '');
watch(status, (s) => router.get('/admin/ai-analyses', { status: s || undefined }, { preserveState: true, replace: true }));

const selected = ref(null);
</script>

<template>
    <Head title="AI Analizleri" />
    <AdminLayout title="AI Analizleri">
        <div class="mb-4 grid gap-4 sm:grid-cols-3">
            <div class="card p-5">
                <p class="text-sm font-medium text-ink-secondary">Toplam analiz</p>
                <p class="mt-1 text-2xl font-extrabold">{{ num(totals.count) }}</p>
            </div>
            <div class="card p-5">
                <p class="text-sm font-medium text-ink-secondary">Toplam maliyet</p>
                <p class="mt-1 text-2xl font-extrabold">{{ totals.cost_try < 100 ? tlFine(totals.cost_try, totals.cost_try < 1 ? 4 : 2) : tl(totals.cost_try) }}</p>
                <p class="text-xs text-ink-muted">{{ usd(totals.cost_usd, 4) }}</p>
            </div>
            <div class="card p-5">
                <p class="text-sm font-medium text-ink-secondary">Analiz başına ortalama</p>
                <p class="mt-1 text-2xl font-extrabold">{{ tlFine(totals.avg_try) }}</p>
                <p class="text-xs text-ink-muted">önbellek hariç · 1 USD = {{ num(usdTry, 4) }} ₺</p>
            </div>
        </div>

        <div class="card">
            <div class="flex flex-wrap items-center gap-3 border-b border-line p-4 dark:border-white/10">
                <Segments
                    v-model="status"
                    :options="[
                        { value: '', label: 'Tümü' },
                        { value: 'done', label: 'Başarılı' },
                        { value: 'not_food', label: 'Yemek Yok' },
                        { value: 'failed', label: 'Hatalı' },
                    ]"
                />
                <p class="text-xs text-ink-secondary">Bir satıra tıklayarak görseli ve AI sonucunu incele.</p>
            </div>
            <div class="overflow-x-auto">
                <table class="table-base">
                    <thead>
                        <tr>
                            <th>Görsel</th>
                            <th>Kullanıcı</th>
                            <th>Sonuç</th>
                            <th>Model</th>
                            <th class="text-right">Token (gir./çık.)</th>
                            <th class="text-right">Maliyet</th>
                            <th class="text-right">Süre</th>
                            <th>Tarih</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="a in analyses.data" :key="a.id" class="cursor-pointer" @click="selected = a">
                            <td>
                                <img v-if="a.has_image" :src="`/admin/ai-analyses/${a.id}/image`" class="h-12 w-12 rounded-lg object-cover" loading="lazy" alt="" />
                                <span v-else class="flex h-12 w-12 items-center justify-center rounded-lg bg-muted dark:bg-white/5"><ImageOff class="h-4 w-4 text-ink-muted" /></span>
                            </td>
                            <td>
                                <Link v-if="a.user" :href="`/admin/users/${a.user.id}`" class="font-semibold hover:text-primary" @click.stop>{{ a.user.name }}</Link>
                            </td>
                            <td>
                                <span :class="['badge', statusLabels[a.status][1]]">{{ statusLabels[a.status][0] }}</span>
                                <span v-if="a.from_cache" class="badge ml-1 bg-success/10 text-success"><DatabaseZap class="mr-1 h-3 w-3" />Önbellek</span>
                                <span v-if="a.total_kcal" class="block pt-1 text-xs font-semibold">{{ num(a.total_kcal) }} kcal · {{ a.items.length }} yemek</span>
                            </td>
                            <td class="max-w-[180px] truncate text-xs text-ink-secondary">{{ a.model ?? '—' }}</td>
                            <td class="text-right text-xs">{{ num(a.prompt_tokens) }} / {{ num(a.completion_tokens) }}</td>
                            <td class="text-right">
                                <span class="block font-semibold">{{ a.from_cache ? '0 ₺' : tlFine(a.cost_try) }}</span>
                                <span class="text-[11px] text-ink-muted">{{ a.from_cache ? '$0' : usd(a.cost_usd, 5) }}</span>
                            </td>
                            <td class="text-right text-xs">{{ a.latency_ms !== null ? (a.latency_ms / 1000).toFixed(1) + ' sn' : '—' }}</td>
                            <td class="text-xs text-ink-secondary">{{ a.created_at }}</td>
                        </tr>
                        <tr v-if="!analyses.data.length">
                            <td colspan="8" class="py-12 text-center text-ink-muted">Henüz AI analizi yok.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <Pagination :paginator="analyses" />
        </div>

        <Modal :show="!!selected" title="Analiz Detayı" width="max-w-2xl" @close="selected = null">
            <div v-if="selected" class="grid gap-5 sm:grid-cols-2">
                <img v-if="selected.has_image" :src="`/admin/ai-analyses/${selected.id}/image`" class="w-full rounded-xl object-cover" alt="" />
                <div>
                    <div class="overflow-hidden rounded-xl border border-line dark:border-white/10">
                        <div class="flex items-center justify-between bg-primary-soft px-4 py-2.5 dark:bg-primary/20">
                            <span class="text-sm font-bold text-primary-dark dark:text-primary-light">Yapay Zeka Analizi</span>
                            <span class="badge bg-primary/10 text-primary">AI</span>
                        </div>
                        <ul class="divide-y divide-line text-sm dark:divide-white/10">
                            <li v-for="(it, i) in selected.items" :key="i" class="px-4 py-2.5">
                                <p class="font-semibold">{{ it.name }}</p>
                                <p class="text-xs text-ink-secondary">
                                    {{ it.kcal }} kcal · {{ it.grams }} g · P {{ it.protein }} / K {{ it.carb }} / Y {{ it.fat }} · güven %{{ Math.round(it.confidence * 100) }}
                                </p>
                            </li>
                            <li v-if="!selected.items.length" class="px-4 py-3 text-ink-muted">Yemek tespit edilmedi.</li>
                        </ul>
                    </div>
                    <p v-if="selected.error" class="mt-3 rounded-lg bg-danger/10 p-3 text-xs text-danger">{{ selected.error }}</p>
                    <p class="mt-3 text-xs text-ink-secondary">
                        {{ selected.model }} · <b>{{ tlFine(selected.cost_try) }}</b> ({{ usd(selected.cost_usd, 5) }}) · {{ selected.created_at }}
                    </p>
                </div>
            </div>
        </Modal>
    </AdminLayout>
</template>
