<script setup>
/** Mobil uygulamadaki Haftalık/Aylık/Yıllık seçicinin aynısı. */
defineProps({ options: Array, modelValue: [String, Number] });
const emit = defineEmits(['update:modelValue']);
</script>

<template>
    <div class="inline-flex rounded-btn border border-line bg-muted p-1 dark:border-white/10 dark:bg-white/5">
        <button
            v-for="o in options"
            :key="o.value"
            type="button"
            :class="[
                'rounded-[10px] px-3.5 py-1.5 text-xs transition',
                o.value === modelValue
                    ? 'bg-primary-soft font-bold text-primary dark:bg-primary/25 dark:text-primary-light'
                    : 'font-medium text-ink-secondary hover:text-ink dark:text-gray-400',
            ]"
            @click="emit('update:modelValue', o.value)"
        >
            {{ o.label }}
        </button>
    </div>
</template>
