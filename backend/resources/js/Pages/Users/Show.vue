<script setup>
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { ArrowLeft, Crown, Ban, RotateCcw } from 'lucide-vue-next';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { goalLabels, num, statusLabels, tl, tlFine } from '@/lib/format';

const props = defineProps({ user: Object, analyses: Array, subscriptions: Array, quotaToday: Number });

const days = ref(30);
const post = (url, data = {}) => router.post(url, data, { preserveScroll: true });
const activity = { sedentary: 'Hareketsiz', light: 'Az hareketli', moderate: 'Orta', active: 'Çok hareketli', very_active: 'Sporcu' };
</script>

<template>
    <Head :title="user.name" />
    <AdminLayout :title="user.name">
        <Link href="/admin/users" class="mb-4 inline-flex items-center gap-1 text-sm font-medium text-ink-secondary hover:text-primary">
            <ArrowLeft class="h-4 w-4" /> Kullanıcılar
        </Link>

        <div class="grid gap-4 xl:grid-cols-3">
            <div class="card p-6">
                <div class="flex items-center gap-4">
                    <span class="flex h-14 w-14 items-center justify-center rounded-full bg-primary-soft text-xl font-bold text-primary dark:bg-primary/20">{{ user.name[0] }}</span>
                    <div>
                        <p class="text-lg font-bold">{{ user.name }}</p>
                        <p class="text-sm text-ink-secondary">{{ user.email }}</p>
                        <p class="mt-1 text-xs text-ink-muted">Kayıt: {{ new Date(user.created_at).toLocaleDateString('tr-TR') }}</p>
                    </div>
                </div>
                <dl v-if="user.profile" class="mt-6 grid grid-cols-2 gap-3 text-sm">
                    <div><dt class="text-xs text-ink-secondary">Hedef</dt><dd class="font-semibold">{{ goalLabels[user.profile.goal] }}</dd></div>
                    <div><dt class="text-xs text-ink-secondary">Aktivite</dt><dd class="font-semibold">{{ activity[user.profile.activity_level] }}</dd></div>
                    <div><dt class="text-xs text-ink-secondary">Boy / Kilo</dt><dd class="font-semibold">{{ user.profile.height_cm ?? '—' }} cm / {{ user.profile.weight_kg ?? '—' }} kg</dd></div>
                    <div><dt class="text-xs text-ink-secondary">Hedef kilo</dt><dd class="font-semibold">{{ user.profile.target_weight_kg ?? '—' }} kg</dd></div>
                    <div><dt class="text-xs text-ink-secondary">Günlük kalori</dt><dd class="font-semibold">{{ num(user.profile.daily_kcal_target) }} kcal</dd></div>
                    <div><dt class="text-xs text-ink-secondary">P / K / Y</dt><dd class="font-semibold">{{ user.profile.protein_g }} / {{ user.profile.carb_g }} / {{ user.profile.fat_g }} g</dd></div>
                </dl>
            </div>

            <div class="card p-6">
                <h3 class="mb-4 font-bold">Üyelik ve Kota</h3>
                <p class="text-sm">
                    <span v-if="user.is_premium" class="badge bg-primary text-white">
                        Premium · {{ new Date(user.premium_until).toLocaleDateString('tr-TR') }}'e kadar
                    </span>
                    <span v-else class="badge bg-track text-ink-secondary dark:bg-white/10">Ücretsiz</span>
                    <span v-if="user.is_blocked" class="badge ml-1 bg-danger/10 text-danger">Engelli</span>
                </p>
                <p class="mt-3 text-sm text-ink-secondary">Bugün kullanılan AI analizi: <b class="text-ink dark:text-white">{{ quotaToday }}</b></p>

                <div class="mt-5 flex items-center gap-2">
                    <select v-model="days" class="input h-9 w-28 text-xs">
                        <option :value="7">7 gün</option>
                        <option :value="30">30 gün</option>
                        <option :value="90">90 gün</option>
                        <option :value="365">1 yıl</option>
                    </select>
                    <button class="btn-primary h-9 px-3 text-xs" @click="post(`/admin/users/${user.id}/premium`, { days })">
                        <Crown class="h-3.5 w-3.5" /> Premium ekle
                    </button>
                </div>
                <div class="mt-3 flex flex-wrap gap-2">
                    <button v-if="user.is_premium" class="btn-outline btn-sm" @click="post(`/admin/users/${user.id}/premium`, { days: 0 })">Premium kaldır</button>
                    <button class="btn-outline btn-sm" @click="post(`/admin/users/${user.id}/reset-quota`)"><RotateCcw class="h-3.5 w-3.5" /> AI hakkını sıfırla</button>
                    <button class="btn-outline btn-sm" :class="user.is_blocked ? '' : 'text-danger'" @click="post(`/admin/users/${user.id}/block`)">
                        <Ban class="h-3.5 w-3.5" /> {{ user.is_blocked ? 'Engeli kaldır' : 'Engelle' }}
                    </button>
                </div>
            </div>

            <div class="card p-6">
                <h3 class="mb-4 font-bold">Abonelik Geçmişi</h3>
                <ul class="space-y-3 text-sm">
                    <li v-for="(s, i) in subscriptions" :key="i" class="flex justify-between gap-2">
                        <span>
                            <span class="font-semibold">{{ s.product_id }}</span>
                            <span class="block text-xs text-ink-secondary">{{ s.store }} · {{ s.started_at }} → {{ s.expires_at ?? '—' }}</span>
                        </span>
                        <span class="text-right">
                            <span class="block font-semibold">{{ tl(s.price) }}</span>
                            <span class="text-xs text-ink-secondary">{{ s.status }}</span>
                        </span>
                    </li>
                    <li v-if="!subscriptions.length" class="text-ink-muted">Abonelik yok.</li>
                </ul>
            </div>
        </div>

        <div class="card mt-4 p-6">
            <h3 class="mb-4 font-bold">Son AI Analizleri</h3>
            <div class="grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-6">
                <div v-for="a in analyses" :key="a.id" class="overflow-hidden rounded-xl border border-line dark:border-white/10">
                    <img v-if="a.has_image" :src="`/admin/ai-analyses/${a.id}/image`" class="aspect-square w-full object-cover" loading="lazy" alt="" />
                    <div v-else class="aspect-square bg-muted dark:bg-white/5" />
                    <div class="p-2 text-xs">
                        <span :class="['badge', statusLabels[a.status][1]]">{{ statusLabels[a.status][0] }}</span>
                        <p class="mt-1 font-semibold">{{ a.total_kcal ? num(a.total_kcal) + ' kcal' : '—' }}</p>
                        <p class="text-ink-secondary">{{ tlFine(a.cost_try) }} · {{ a.created_at }}</p>
                    </div>
                </div>
                <p v-if="!analyses.length" class="col-span-full text-sm text-ink-muted">Henüz AI analizi yok.</p>
            </div>
        </div>
    </AdminLayout>
</template>
