<script setup>
import { Link } from '@inertiajs/vue3';

defineProps({ paginator: { type: Object, required: true } });

const label = (l) => l.replace('&laquo; Previous', '‹').replace('Next &raquo;', '›').replace('pagination.previous', '‹').replace('pagination.next', '›');
</script>

<template>
    <div v-if="paginator.last_page > 1" class="flex flex-wrap items-center justify-between gap-3 px-4 py-3 text-sm">
        <span class="text-ink-secondary">
            Toplam {{ paginator.total.toLocaleString('tr-TR') }} kayıt · {{ paginator.from }}–{{ paginator.to }}
        </span>
        <div class="flex gap-1">
            <template v-for="(l, i) in paginator.links" :key="i">
                <Link
                    v-if="l.url"
                    :href="l.url"
                    preserve-scroll
                    :class="[
                        'flex h-8 min-w-8 items-center justify-center rounded-lg px-2 text-xs font-semibold transition',
                        l.active ? 'bg-primary text-white' : 'border border-line hover:bg-muted dark:border-white/10 dark:hover:bg-white/5',
                    ]"
                    v-html="label(l.label)"
                />
                <span v-else class="flex h-8 min-w-8 items-center justify-center px-2 text-xs text-ink-muted" v-html="label(l.label)" />
            </template>
        </div>
    </div>
</template>
