<script setup>
import { computed } from 'vue';
import { TrendingUp, TrendingDown } from 'lucide-vue-next';

const props = defineProps({
    label: String,
    value: [String, Number],
    hint: String,
    icon: Object,
    color: { type: String, default: 'primary' }, // primary | success | carb | water | danger
    change: { type: Number, default: null }, // önceki döneme göre %
    invert: Boolean, // gider kartlarında artış kötüdür
});

const tone = {
    primary: 'bg-primary-soft text-primary dark:bg-primary/20',
    success: 'bg-success/10 text-success',
    carb: 'bg-carb/10 text-carb',
    water: 'bg-water/10 text-water',
    danger: 'bg-danger/10 text-danger',
};

const good = computed(() => (props.change === null ? null : props.invert ? props.change <= 0 : props.change >= 0));
</script>

<template>
    <div class="card p-5">
        <div class="flex items-start justify-between">
            <span class="text-sm font-medium text-ink-secondary dark:text-gray-400">{{ label }}</span>
            <span v-if="icon" :class="['flex h-9 w-9 items-center justify-center rounded-xl', tone[color]]">
                <component :is="icon" class="h-[18px] w-[18px]" />
            </span>
        </div>
        <div class="mt-2 text-2xl font-extrabold tracking-tight">{{ value }}</div>
        <div class="mt-1 flex items-center gap-2 text-xs">
            <span
                v-if="change !== null"
                :class="['inline-flex items-center gap-0.5 font-semibold', good ? 'text-success' : 'text-danger']"
            >
                <TrendingUp v-if="change >= 0" class="h-3.5 w-3.5" />
                <TrendingDown v-else class="h-3.5 w-3.5" />
                %{{ Math.abs(change).toLocaleString('tr-TR') }}
            </span>
            <span v-if="hint" class="text-ink-muted">{{ hint }}</span>
        </div>
        <slot />
    </div>
</template>
