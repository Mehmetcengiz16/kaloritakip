<script setup>
import { computed } from 'vue';
import { Head, useForm, usePage } from '@inertiajs/vue3';
import { Flame, Mail, Lock } from 'lucide-vue-next';
import FieldError from '@/Components/FieldError.vue';

const form = useForm({ email: '', password: '', remember: true });
const flashError = computed(() => usePage().props.flash?.error);

const submit = () => form.post('/admin/login', { onFinish: () => form.reset('password') });
</script>

<template>
    <Head title="Giriş" />
    <div class="flex min-h-screen items-center justify-center bg-gradient-to-br from-primary-soft via-white to-white p-4 dark:from-[#1d1636] dark:via-[#0F0F1A] dark:to-[#0F0F1A]">
        <div class="card w-full max-w-sm p-8">
            <div class="mb-6 flex flex-col items-center text-center">
                <div class="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-b from-primary-light to-primary-dark shadow-[0_8px_20px_rgba(124,58,237,0.35)]">
                    <Flame class="h-7 w-7 text-white" />
                </div>
                <h1 class="text-2xl font-extrabold tracking-tight">KaloriTakip</h1>
                <p class="mt-1 text-sm text-ink-secondary">Yönetim paneline giriş yap</p>
            </div>

            <p v-if="flashError" class="mb-4 rounded-xl bg-danger/10 px-3 py-2 text-xs font-medium text-danger">{{ flashError }}</p>

            <form class="space-y-4" @submit.prevent="submit">
                <div>
                    <label class="label" for="email">E-posta</label>
                    <div class="relative">
                        <Mail class="absolute left-3.5 top-3.5 h-4 w-4 text-ink-muted" />
                        <input id="email" v-model="form.email" type="email" autocomplete="username" class="input pl-10" required autofocus />
                    </div>
                    <FieldError :message="form.errors.email" />
                </div>
                <div>
                    <label class="label" for="password">Şifre</label>
                    <div class="relative">
                        <Lock class="absolute left-3.5 top-3.5 h-4 w-4 text-ink-muted" />
                        <input id="password" v-model="form.password" type="password" autocomplete="current-password" class="input pl-10" required />
                    </div>
                </div>
                <label class="flex items-center gap-2 text-sm text-ink-secondary">
                    <input v-model="form.remember" type="checkbox" class="h-4 w-4 rounded accent-primary" /> Beni hatırla
                </label>
                <button type="submit" class="btn-primary w-full" :disabled="form.processing">Giriş Yap</button>
            </form>
        </div>
    </div>
</template>
