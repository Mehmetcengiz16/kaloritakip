<script setup>
import { Head, router, useForm } from '@inertiajs/vue3';
import { Trash2, Info } from 'lucide-vue-next';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import Pagination from '@/Components/Pagination.vue';
import FieldError from '@/Components/FieldError.vue';
import { expenseLabels, tl } from '@/lib/format';

defineProps({ expenses: Object, thisMonth: Number, byCategory: Object });

const today = new Date().toISOString().slice(0, 10);
const form = useForm({ category: 'server', description: '', amount: '', date: today });
const save = () => form.post('/admin/expenses', { preserveScroll: true, onSuccess: () => form.reset('description', 'amount') });
const destroy = (e) => confirm('Bu gider silinsin mi?') && router.delete(`/admin/expenses/${e.id}`, { preserveScroll: true });
</script>

<template>
    <Head title="Giderler" />
    <AdminLayout title="Giderler">
        <div class="grid gap-4 xl:grid-cols-3">
            <div class="space-y-4">
                <form class="card space-y-4 p-5" @submit.prevent="save">
                    <h3 class="font-bold">Gider Ekle</h3>
                    <div>
                        <label class="label">Kategori</label>
                        <select v-model="form.category" class="input">
                            <option v-for="(label, key) in expenseLabels" :key="key" :value="key">{{ label }}</option>
                        </select>
                    </div>
                    <div>
                        <label class="label">Açıklama</label>
                        <input v-model="form.description" class="input" placeholder="ör. Hetzner VPS – Kasım" />
                    </div>
                    <div class="grid grid-cols-2 gap-3">
                        <div>
                            <label class="label">Tutar (₺)</label>
                            <input v-model="form.amount" type="number" step="0.01" min="0" class="input" required />
                            <FieldError :message="form.errors.amount" />
                        </div>
                        <div>
                            <label class="label">Tarih</label>
                            <input v-model="form.date" type="date" :max="today" class="input" required />
                            <FieldError :message="form.errors.date" />
                        </div>
                    </div>
                    <button type="submit" class="btn-primary w-full" :disabled="form.processing">Ekle</button>
                    <p class="flex gap-2 text-[11px] text-ink-muted">
                        <Info class="h-3.5 w-3.5 shrink-0" />
                        OpenRouter (AI) maliyeti ve mağaza komisyonu otomatik hesaplanır; buraya sadece sunucu, reklam gibi diğer giderleri gir.
                    </p>
                </form>

                <div class="card p-5">
                    <h3 class="font-bold">Bu Ay</h3>
                    <p class="mt-1 text-2xl font-extrabold">{{ tl(thisMonth) }}</p>
                    <ul class="mt-3 space-y-2 text-sm">
                        <li v-for="(total, cat) in byCategory" :key="cat" class="flex justify-between">
                            <span class="text-ink-secondary">{{ expenseLabels[cat] ?? cat }}</span>
                            <span class="font-semibold">{{ tl(total) }}</span>
                        </li>
                    </ul>
                </div>
            </div>

            <div class="card xl:col-span-2">
                <div class="overflow-x-auto">
                    <table class="table-base">
                        <thead>
                            <tr>
                                <th>Tarih</th>
                                <th>Kategori</th>
                                <th>Açıklama</th>
                                <th class="text-right">Tutar</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="e in expenses.data" :key="e.id">
                                <td class="text-ink-secondary">{{ new Date(e.date).toLocaleDateString('tr-TR') }}</td>
                                <td><span class="badge bg-primary-soft text-primary dark:bg-primary/20">{{ expenseLabels[e.category] ?? e.category }}</span></td>
                                <td>{{ e.description ?? '—' }}</td>
                                <td class="text-right font-semibold">{{ tl(e.amount) }}</td>
                                <td class="text-right">
                                    <button class="btn-outline btn-sm" title="Sil" @click="destroy(e)"><Trash2 class="h-3.5 w-3.5 text-danger" /></button>
                                </td>
                            </tr>
                            <tr v-if="!expenses.data.length">
                                <td colspan="5" class="py-12 text-center text-ink-muted">Henüz gider girilmedi.</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <Pagination :paginator="expenses" />
            </div>
        </div>
    </AdminLayout>
</template>
