<script setup>
import { ref, watch } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { Search, Crown, Ban, RotateCcw, ChevronRight } from 'lucide-vue-next';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';
import Segments from '@/Components/Segments.vue';
import { goalLabels, num, usd } from '@/lib/format';

const props = defineProps({ users: Object, filters: Object });

const q = ref(props.filters.q ?? '');
const status = ref(props.filters.status ?? '');

let t;
const reload = () => router.get('/admin/users', { q: q.value || undefined, status: status.value || undefined }, { preserveState: true, replace: true });
watch(q, () => {
    clearTimeout(t);
    t = setTimeout(reload, 350);
});
watch(status, reload);

const post = (url, data = {}, confirmText = null) => {
    if (confirmText && !confirm(confirmText)) return;
    router.post(url, data, { preserveScroll: true });
};
</script>

<template>
    <Head title="Kullanıcılar" />
    <AdminLayout title="Kullanıcılar">
        <div class="card">
            <div class="flex flex-wrap items-center gap-3 border-b border-line p-4 dark:border-white/10">
                <div class="relative w-full max-w-xs">
                    <Search class="absolute left-3.5 top-3.5 h-4 w-4 text-ink-muted" />
                    <input v-model="q" class="input pl-10" placeholder="Ad veya e-posta ara" />
                </div>
                <Segments
                    v-model="status"
                    :options="[
                        { value: '', label: 'Tümü' },
                        { value: 'premium', label: 'Premium' },
                        { value: 'free', label: 'Ücretsiz' },
                        { value: 'blocked', label: 'Engelli' },
                    ]"
                />
            </div>
            <div class="overflow-x-auto">
                <table class="table-base">
                    <thead>
                        <tr>
                            <th>Kullanıcı</th>
                            <th>Hedef</th>
                            <th>Üyelik</th>
                            <th class="text-right">AI Analiz</th>
                            <th class="text-right">AI Maliyeti</th>
                            <th>Kayıt</th>
                            <th class="text-right">İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="u in users.data" :key="u.id">
                            <td>
                                <Link :href="`/admin/users/${u.id}`" class="flex items-center gap-3">
                                    <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary-soft text-sm font-bold text-primary dark:bg-primary/20">
                                        {{ u.name[0] }}
                                    </span>
                                    <span>
                                        <span class="block font-semibold">{{ u.name }}</span>
                                        <span class="block text-xs text-ink-secondary">{{ u.email }}</span>
                                    </span>
                                </Link>
                            </td>
                            <td>
                                <span class="text-sm">{{ goalLabels[u.goal] ?? '—' }}</span>
                                <span v-if="u.kcal_target" class="block text-xs text-ink-secondary">{{ num(u.kcal_target) }} kcal</span>
                            </td>
                            <td>
                                <span v-if="u.is_blocked" class="badge bg-danger/10 text-danger">Engelli</span>
                                <span v-else-if="u.is_premium" class="badge bg-primary text-white">
                                    Premium · {{ new Date(u.premium_until).toLocaleDateString('tr-TR') }}
                                </span>
                                <span v-else class="badge bg-track text-ink-secondary dark:bg-white/10">Ücretsiz</span>
                            </td>
                            <td class="text-right font-medium">{{ num(u.ai_count) }}</td>
                            <td class="text-right font-medium">{{ usd(u.ai_cost_usd, 3) }}</td>
                            <td class="text-ink-secondary">{{ new Date(u.created_at).toLocaleDateString('tr-TR') }}</td>
                            <td>
                                <div class="flex justify-end gap-1.5">
                                    <button
                                        class="btn-outline btn-sm"
                                        :title="u.is_premium ? 'Premium kaldır' : '30 gün premium ver'"
                                        @click="post(`/admin/users/${u.id}/premium`, { days: u.is_premium ? 0 : 30 }, u.is_premium ? `${u.name} için premium kaldırılsın mı?` : null)"
                                    >
                                        <Crown class="h-3.5 w-3.5" :class="u.is_premium ? 'text-carb' : ''" />
                                    </button>
                                    <button class="btn-outline btn-sm" title="Bugünkü AI hakkını sıfırla" @click="post(`/admin/users/${u.id}/reset-quota`)">
                                        <RotateCcw class="h-3.5 w-3.5" />
                                    </button>
                                    <button
                                        class="btn-outline btn-sm"
                                        :title="u.is_blocked ? 'Engeli kaldır' : 'Engelle'"
                                        @click="post(`/admin/users/${u.id}/block`, {}, u.is_blocked ? null : `${u.name} engellensin mi? Açık oturumları kapanır.`)"
                                    >
                                        <Ban class="h-3.5 w-3.5" :class="u.is_blocked ? 'text-danger' : ''" />
                                    </button>
                                    <Link :href="`/admin/users/${u.id}`" class="btn-outline btn-sm"><ChevronRight class="h-3.5 w-3.5" /></Link>
                                </div>
                            </td>
                        </tr>
                        <tr v-if="!users.data.length">
                            <td colspan="7" class="py-12 text-center text-ink-muted">Kullanıcı bulunamadı.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <Pagination :paginator="users" />
        </div>
    </AdminLayout>
</template>
