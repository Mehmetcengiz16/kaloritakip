<script setup>
import { ref, watch } from 'vue';
import { Head, router, useForm } from '@inertiajs/vue3';
import { Search, Plus, Pencil, Trash2, BadgeCheck, ImagePlus, X } from 'lucide-vue-next';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';
import Segments from '@/Components/Segments.vue';
import Modal from '@/Components/Modal.vue';
import FieldError from '@/Components/FieldError.vue';
import { foodEmoji, num, sourceLabels } from '@/lib/format';

const props = defineProps({ foods: Object, filters: Object, pendingCount: Number });

const q = ref(props.filters.q ?? '');
const view = ref(props.filters.pending ? 'pending' : props.filters.source ?? '');

let t;
const reload = () =>
    router.get(
        '/admin/foods',
        {
            q: q.value || undefined,
            source: ['manual', 'openfoodfacts', 'ai'].includes(view.value) ? view.value : undefined,
            pending: view.value === 'pending' ? 1 : undefined,
        },
        { preserveState: true, replace: true },
    );
watch(q, () => {
    clearTimeout(t);
    t = setTimeout(reload, 350);
});
watch(view, reload);

const empty = { name: '', brand: '', barcode: '', kcal_per_100g: '', protein_per_100g: 0, carb_per_100g: 0, fat_per_100g: 0, default_portion_g: 100 };
const form = useForm({ ...empty, image: null, remove_image: false });
const preview = ref(null);

function onImage(e) {
    const file = e.target.files?.[0];
    form.image = file ?? null;
    form.remove_image = false;
    preview.value = file ? URL.createObjectURL(file) : null;
}
function clearImage() {
    form.image = null;
    form.remove_image = true;
    preview.value = null;
}
const editing = ref(null);
const show = ref(false);

function open(food = null) {
    editing.value = food;
    form.defaults({
        ...(food ? Object.fromEntries(Object.keys(empty).map((k) => [k, food[k] ?? ''])) : { ...empty }),
        image: null,
        remove_image: false,
    });
    form.reset();
    preview.value = food?.image ?? null;
    form.clearErrors();
    show.value = true;
}

function save() {
    const opts = { preserveScroll: true, onSuccess: () => (show.value = false) };
    // Dosya yükleme için multipart POST (güncellemede de POST rotası var).
    form.post(editing.value ? `/admin/foods/${editing.value.id}` : '/admin/foods', { ...opts, forceFormData: true });
}

const verify = (f) => router.post(`/admin/foods/${f.id}/verify`, {}, { preserveScroll: true });
const destroy = (f) => confirm(`"${f.name}" silinsin mi?`) && router.delete(`/admin/foods/${f.id}`, { preserveScroll: true });

const fields = [
    ['kcal_per_100g', 'Kalori (kcal)'],
    ['protein_per_100g', 'Protein (g)'],
    ['carb_per_100g', 'Karbonhidrat (g)'],
    ['fat_per_100g', 'Yağ (g)'],
];
</script>

<template>
    <Head title="Yemek Veritabanı" />
    <AdminLayout title="Yemek Veritabanı">
        <template #actions>
            <button class="btn-primary h-9 px-4" @click="open()"><Plus class="h-4 w-4" /> Yemek Ekle</button>
        </template>

        <div v-if="pendingCount" class="mb-4 rounded-card border border-carb/30 bg-carb/10 p-4 text-sm">
            <b>{{ pendingCount }}</b> yemek yapay zekâdan öğrenildi ve onay bekliyor. Onaylananlar mobil uygulamadaki aramada çıkar; zamanla AI'a
            daha az ihtiyaç duyulur.
            <button class="ml-1 font-semibold text-primary" @click="view = 'pending'">Onay bekleyenleri göster →</button>
        </div>

        <div class="card">
            <div class="flex flex-wrap items-center gap-3 border-b border-line p-4 dark:border-white/10">
                <div class="relative w-full max-w-xs">
                    <Search class="absolute left-3.5 top-3.5 h-4 w-4 text-ink-muted" />
                    <input v-model="q" class="input pl-10" placeholder="Yemek ara" />
                </div>
                <Segments
                    v-model="view"
                    :options="[
                        { value: '', label: 'Tümü' },
                        { value: 'pending', label: 'Onay Bekleyen' },
                        { value: 'manual', label: 'Manuel' },
                        { value: 'openfoodfacts', label: 'Barkod' },
                        { value: 'ai', label: 'AI' },
                    ]"
                />
            </div>
            <div class="overflow-x-auto">
                <table class="table-base">
                    <thead>
                        <tr>
                            <th>Yemek</th>
                            <th>Kaynak</th>
                            <th class="text-right">kcal / 100 g</th>
                            <th class="text-right">P / K / Y</th>
                            <th class="text-right">Porsiyon</th>
                            <th>Durum</th>
                            <th class="text-right">İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="f in foods.data" :key="f.id">
                            <td>
                                <div class="flex items-center gap-3">
                                <img v-if="f.image" :src="f.image" class="h-11 w-11 shrink-0 rounded-xl object-cover" loading="lazy" alt="" />
                                <span v-else class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-muted text-xl dark:bg-white/5">{{ foodEmoji(f.name) }}</span>
                                <span>
                                <span class="font-semibold">{{ f.name }}</span>
                                <span v-if="f.brand || f.barcode" class="block text-xs text-ink-secondary">{{ [f.brand, f.barcode].filter(Boolean).join(' · ') }}</span>
                                </span>
                                </div>
                            </td>
                            <td><span :class="['badge', sourceLabels[f.source][1]]">{{ sourceLabels[f.source][0] }}</span></td>
                            <td class="text-right font-semibold">{{ num(f.kcal_per_100g) }}</td>
                            <td class="text-right text-ink-secondary">{{ num(f.protein_per_100g, 1) }} / {{ num(f.carb_per_100g, 1) }} / {{ num(f.fat_per_100g, 1) }}</td>
                            <td class="text-right">{{ f.default_portion_g }} g</td>
                            <td>
                                <span v-if="f.verified" class="badge bg-success/10 text-success">Onaylı</span>
                                <span v-else class="badge bg-carb/10 text-carb">Onay bekliyor</span>
                            </td>
                            <td>
                                <div class="flex justify-end gap-1.5">
                                    <button class="btn-outline btn-sm" :title="f.verified ? 'Onayı kaldır' : 'Onayla'" @click="verify(f)">
                                        <BadgeCheck class="h-3.5 w-3.5" :class="f.verified ? 'text-success' : ''" />
                                    </button>
                                    <button class="btn-outline btn-sm" title="Düzenle" @click="open(f)"><Pencil class="h-3.5 w-3.5" /></button>
                                    <button class="btn-outline btn-sm" title="Sil" @click="destroy(f)"><Trash2 class="h-3.5 w-3.5 text-danger" /></button>
                                </div>
                            </td>
                        </tr>
                        <tr v-if="!foods.data.length">
                            <td colspan="7" class="py-12 text-center text-ink-muted">Yemek bulunamadı.</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <Pagination :paginator="foods" />
        </div>

        <Modal :show="show" :title="editing ? 'Yemeği Düzenle' : 'Yeni Yemek'" @close="show = false">
            <form class="space-y-4" @submit.prevent="save">
                <div class="flex items-center gap-4">
                    <div class="relative">
                        <img v-if="preview" :src="preview" class="h-20 w-20 rounded-2xl object-cover" alt="" />
                        <span v-else class="flex h-20 w-20 items-center justify-center rounded-2xl bg-muted text-3xl dark:bg-white/5">{{ foodEmoji(form.name) }}</span>
                        <button
                            v-if="preview"
                            type="button"
                            class="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-danger text-white"
                            title="Görseli kaldır"
                            @click="clearImage"
                        >
                            <X class="h-3.5 w-3.5" />
                        </button>
                    </div>
                    <div>
                        <label class="btn-outline h-9 cursor-pointer px-3 text-xs">
                            <ImagePlus class="h-4 w-4" /> Görsel seç
                            <input type="file" accept="image/jpeg,image/png,image/webp" class="hidden" @change="onImage" />
                        </label>
                        <p class="mt-1 text-[11px] text-ink-muted">JPG/PNG/WebP, en fazla 4 MB. Kare olarak kırpılır.</p>
                        <FieldError :message="form.errors.image" />
                    </div>
                </div>
                <div>
                    <label class="label">Ad</label>
                    <input v-model="form.name" class="input" required />
                    <FieldError :message="form.errors.name" />
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="label">Marka</label>
                        <input v-model="form.brand" class="input" />
                    </div>
                    <div>
                        <label class="label">Barkod</label>
                        <input v-model="form.barcode" class="input" inputmode="numeric" />
                        <FieldError :message="form.errors.barcode" />
                    </div>
                </div>
                <p class="text-xs font-semibold text-ink-secondary">100 gram için besin değerleri</p>
                <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
                    <div v-for="[key, label] in fields" :key="key">
                        <label class="label">{{ label }}</label>
                        <input v-model="form[key]" type="number" step="0.1" min="0" class="input" required />
                        <FieldError :message="form.errors[key]" />
                    </div>
                </div>
                <div class="w-1/2">
                    <label class="label">Varsayılan porsiyon (g)</label>
                    <input v-model="form.default_portion_g" type="number" min="1" class="input" required />
                    <FieldError :message="form.errors.default_portion_g" />
                </div>
                <div class="flex justify-end gap-2 pt-2">
                    <button type="button" class="btn-outline" @click="show = false">Vazgeç</button>
                    <button type="submit" class="btn-primary" :disabled="form.processing">Kaydet</button>
                </div>
            </form>
        </Modal>
    </AdminLayout>
</template>
