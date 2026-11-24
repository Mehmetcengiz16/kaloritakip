<script setup>
import { X } from 'lucide-vue-next';

defineProps({ show: Boolean, title: String, width: { type: String, default: 'max-w-lg' } });
const emit = defineEmits(['close']);
</script>

<template>
    <Teleport to="body">
        <transition enter-from-class="opacity-0" leave-to-class="opacity-0" enter-active-class="transition" leave-active-class="transition">
            <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4" @mousedown.self="emit('close')">
                <div :class="['card w-full p-6', width]">
                    <div class="mb-5 flex items-center justify-between">
                        <h2 class="text-lg font-bold">{{ title }}</h2>
                        <button class="text-ink-muted hover:text-ink" @click="emit('close')"><X class="h-5 w-5" /></button>
                    </div>
                    <slot />
                </div>
            </div>
        </transition>
    </Teleport>
</template>
