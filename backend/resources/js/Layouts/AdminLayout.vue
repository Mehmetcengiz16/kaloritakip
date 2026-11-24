<script setup>
import { computed, ref, watch } from 'vue';
import { Link, router, usePage } from '@inertiajs/vue3';
import {
    LayoutDashboard, Users, Apple, Sparkles, Wallet, Settings, LogOut, Moon, Sun, Menu, X, Flame, CheckCircle2, AlertCircle,
} from 'lucide-vue-next';

defineProps({ title: { type: String, default: '' } });

const page = usePage();
const user = computed(() => page.props.auth?.user);
const flash = computed(() => page.props.flash ?? {});
const mobileOpen = ref(false);
const dark = ref(document.documentElement.classList.contains('dark'));
const toast = ref(null);

const nav = [
    { href: '/admin', label: 'Genel Bakış', icon: LayoutDashboard, exact: true },
    { href: '/admin/users', label: 'Kullanıcılar', icon: Users },
    { href: '/admin/foods', label: 'Yemek Veritabanı', icon: Apple },
    { href: '/admin/ai-analyses', label: 'AI Analizleri', icon: Sparkles },
    { href: '/admin/expenses', label: 'Giderler', icon: Wallet },
    { href: '/admin/settings', label: 'AI & Ayarlar', icon: Settings },
];

const isActive = (item) => {
    const path = page.url.split('?')[0];
    return item.exact ? path === item.href : path.startsWith(item.href);
};

function toggleTheme() {
    dark.value = !dark.value;
    document.documentElement.classList.toggle('dark', dark.value);
    localStorage.setItem('theme', dark.value ? 'dark' : 'light');
}

let timer;
watch(
    flash,
    (f) => {
        const msg = f.success || f.error;
        if (!msg) return;
        toast.value = { msg, error: !!f.error };
        clearTimeout(timer);
        timer = setTimeout(() => (toast.value = null), 3500);
    },
    { immediate: true, deep: true },
);

router.on('navigate', () => (mobileOpen.value = false));
</script>

<template>
    <div class="min-h-screen lg:flex">
        <!-- Sidebar -->
        <aside
            :class="[
                'fixed inset-y-0 left-0 z-40 w-64 transform border-r border-line bg-white transition-transform dark:border-white/10 dark:bg-[#141425] lg:static lg:translate-x-0',
                mobileOpen ? 'translate-x-0' : '-translate-x-full',
            ]"
        >
            <div class="flex h-16 items-center gap-2 px-6">
                <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-b from-primary-light to-primary-dark">
                    <Flame class="h-5 w-5 text-white" />
                </div>
                <span class="text-lg font-extrabold tracking-tight">KaloriTakip</span>
                <button class="ml-auto lg:hidden" @click="mobileOpen = false"><X class="h-5 w-5" /></button>
            </div>
            <nav class="mt-2 space-y-1 px-3">
                <Link
                    v-for="item in nav"
                    :key="item.href"
                    :href="item.href"
                    :class="[
                        'flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition',
                        isActive(item)
                            ? 'bg-primary-soft text-primary dark:bg-primary/20 dark:text-primary-light'
                            : 'text-ink-secondary hover:bg-muted hover:text-ink dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-white',
                    ]"
                >
                    <component :is="item.icon" class="h-[18px] w-[18px]" />
                    {{ item.label }}
                </Link>
            </nav>
        </aside>
        <div v-if="mobileOpen" class="fixed inset-0 z-30 bg-black/30 lg:hidden" @click="mobileOpen = false" />

        <!-- Content -->
        <div class="flex min-w-0 flex-1 flex-col">
            <header class="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-line bg-white/80 px-4 backdrop-blur dark:border-white/10 dark:bg-[#0F0F1A]/80 sm:px-8">
                <button class="lg:hidden" @click="mobileOpen = true"><Menu class="h-5 w-5" /></button>
                <h1 class="text-lg font-bold">{{ title }}</h1>
                <div class="ml-auto flex items-center gap-2">
                    <slot name="actions" />
                    <button class="btn-outline h-9 w-9 px-0" :title="dark ? 'Açık tema' : 'Koyu tema'" @click="toggleTheme">
                        <Sun v-if="dark" class="h-4 w-4" /><Moon v-else class="h-4 w-4" />
                    </button>
                    <div class="hidden items-center gap-2 pl-2 sm:flex">
                        <div class="flex h-9 w-9 items-center justify-center rounded-full bg-primary-soft text-sm font-bold text-primary">
                            {{ user?.name?.[0] ?? 'A' }}
                        </div>
                        <span class="text-sm font-medium">{{ user?.name }}</span>
                    </div>
                    <Link href="/admin/logout" method="post" as="button" class="btn-outline h-9 w-9 px-0" title="Çıkış">
                        <LogOut class="h-4 w-4" />
                    </Link>
                </div>
            </header>
            <main class="flex-1 p-4 sm:p-8">
                <slot />
            </main>
        </div>

        <!-- Toast -->
        <transition
            enter-from-class="translate-y-2 opacity-0"
            leave-to-class="translate-y-2 opacity-0"
            enter-active-class="transition"
            leave-active-class="transition"
        >
            <div
                v-if="toast"
                class="fixed bottom-6 right-6 z-50 flex items-center gap-2 rounded-xl px-4 py-3 text-sm font-medium text-white shadow-lg"
                :class="toast.error ? 'bg-danger' : 'bg-ink dark:bg-primary'"
            >
                <AlertCircle v-if="toast.error" class="h-4 w-4" />
                <CheckCircle2 v-else class="h-4 w-4 text-success dark:text-white" />
                {{ toast.msg }}
            </div>
        </transition>
    </div>
</template>
