import '../css/app.css';
import '@fontsource-variable/inter';
import './bootstrap';

import { createApp, h } from 'vue';
import { createInertiaApp } from '@inertiajs/vue3';
import VueApexCharts from 'vue3-apexcharts';

createInertiaApp({
    title: (title) => (title ? `${title} · KaloriTakip Admin` : 'KaloriTakip Admin'),
    resolve: (name) => {
        const pages = import.meta.glob('./Pages/**/*.vue', { eager: true });
        return pages[`./Pages/${name}.vue`];
    },
    setup({ el, App, props, plugin }) {
        createApp({ render: () => h(App, props) })
            .use(plugin)
            .use(VueApexCharts)
            .mount(el);
    },
    progress: { color: '#7C3AED' },
});
