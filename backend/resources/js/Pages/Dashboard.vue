<script setup>
import { computed, ref, watch } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import {
    Wallet, Receipt, PiggyBank, Sparkles, Users, Crown, UserPlus, Activity, Zap, DatabaseZap, AlertTriangle, CircleDollarSign,
} from 'lucide-vue-next';
import AdminLayout from '@/Layouts/AdminLayout.vue';
import StatCard from '@/Components/StatCard.vue';
import Segments from '@/Components/Segments.vue';
import { delta, num, pct, tl, usd } from '@/lib/format';

const props = defineProps({
    days: Number,
    summary: Object,
    previous: Object,
    series: Array,
    aiRatioAlert: Number,
    users: Object,
    ai: Object,
    subscriptions: Object,
});

const period = ref(props.days);
watch(period, (days) => router.get('/admin', { days }, { preserveState: true, preserveScroll: true }));

const totalCost = (s) => s.store_fee + s.ai_cost + s.expenses;
const isDark = () => document.documentElement.classList.contains('dark');

const aiRatioHigh = computed(() => props.summary.ai_ratio_pct !== null && props.summary.ai_ratio_pct > props.aiRatioAlert);
const budgetPct = computed(() => (props.ai.budget_usd > 0 ? Math.min(100, (props.ai.spent_today_usd / props.ai.budget_usd) * 100) : 0));

const trendSeries = computed(() => [
    { name: 'Gelir', data: props.series.map((r) => r.revenue) },
    { name: 'Gider', data: props.series.map((r) => r.cost) },
    { name: 'Net', data: props.series.map((r) => r.net) },
]);

const trendOptions = computed(() => ({
    chart: { type: 'area', toolbar: { show: false }, fontFamily: 'Inter Variable, Inter, sans-serif', foreColor: isDark() ? '#9CA3AF' : '#6B7280' },
    colors: ['#7C3AED', '#F59E0B', '#22C55E'],
    stroke: { curve: 'smooth', width: [2.5, 2, 2] },
    fill: { type: 'gradient', gradient: { opacityFrom: 0.25, opacityTo: 0 } },
    dataLabels: { enabled: false },
    grid: { borderColor: isDark() ? 'rgba(255,255,255,0.06)' : '#ECEBF2', strokeDashArray: 4 },
    xaxis: {
        categories: props.series.map((r) => new Date(r.date).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' })),
        tickAmount: 8,
        axisBorder: { show: false },
        axisTicks: { show: false },
    },
    yaxis: { labels: { formatter: (v) => tl(v) } },
    legend: { position: 'top', horizontalAlign: 'right' },
    tooltip: { y: { formatter: (v) => tl(v) } },
}));

const costBreakdown = computed(() => [props.summary.store_fee, props.summary.ai_cost, props.summary.expenses]);
const donutOptions = computed(() => ({
    chart: { type: 'donut', fontFamily: 'Inter Variable, Inter, sans-serif', foreColor: isDark() ? '#9CA3AF' : '#6B7280' },
    labels: ['Mağaza komisyonu', 'Yapay zekâ', 'Diğer giderler'],
    colors: ['#8B5CF6', '#F59E0B', '#3B82F6'],
    legend: { position: 'bottom' },
    dataLabels: { enabled: false },
    stroke: { width: 0 },
    plotOptions: {
        pie: {
            donut: {
                size: '72%',
                labels: { show: true, total: { show: true, label: 'Toplam gider', formatter: () => tl(totalCost(props.summary)) }, value: { formatter: (v) => tl(v) } },
            },
        },
    },
    tooltip: { y: { formatter: (v) => tl(v) } },
}));

// Mobildeki "Kalan Kalori" halkasının aynısı: bugünkü AI bütçe kullanımı
const ringOptions = computed(() => ({
    chart: { type: 'radialBar', sparkline: { enabled: true }, fontFamily: 'Inter Variable, Inter, sans-serif' },
    colors: [budgetPct.value >= 90 ? '#EF4444' : '#7C3AED'],
    fill: budgetPct.value >= 90 ? {} : { type: 'gradient', gradient: { shade: 'light', type: 'horizontal', gradientToColors: ['#6D28D9'], stops: [0, 100] } },
    plotOptions: {
        radialBar: {
            hollow: { size: '68%' },
            track: { background: isDark() ? 'rgba(255,255,255,0.06)' : '#EFEDF5' },
            dataLabels: {
                name: { show: true, offsetY: -8, fontSize: '12px', color: '#6B7280' },
                value: { offsetY: 4, fontSize: '22px', fontWeight: 800, color: isDark() ? '#fff' : '#1A1A2E', formatter: () => usd(props.ai.spent_today_usd) },
            },
        },
    },
    stroke: { lineCap: 'round' },
    labels: ['Bugün harcanan'],
}));
</script>

<template>
    <Head title="Genel Bakış" />
    <AdminLayout title="Genel Bakış">
        <div class="mb-6 flex flex-wrap items-center justify-between gap-3">
            <div>
                <h2 class="text-xl font-bold">Gelir – Gider Dengesi</h2>
                <p class="text-sm text-ink-secondary">Son {{ days }} gün, önceki {{ days }} günle karşılaştırmalı</p>
            </div>
            <Segments
                v-model="period"
                :options="[
                    { value: 7, label: 'Haftalık' },
                    { value: 30, label: 'Aylık' },
                    { value: 90, label: '3 Aylık' },
                ]"
            />
        </div>

        <div
            v-if="aiRatioHigh"
            class="mb-6 flex items-start gap-3 rounded-card border border-carb/30 bg-carb/10 p-4 text-sm"
        >
            <AlertTriangle class="mt-0.5 h-5 w-5 shrink-0 text-carb" />
            <div>
                <p class="font-semibold">AI maliyeti gelirin {{ pct(summary.ai_ratio_pct) }}'i — hedef sınır {{ pct(aiRatioAlert) }}.</p>
                <p class="mt-0.5 text-ink-secondary">
                    Daha ucuz bir modele geçmeyi, ücretsiz günlük limiti düşürmeyi veya günlük bütçeyi azaltmayı değerlendir
                    (<a href="/admin/settings" class="font-semibold text-primary">AI & Ayarlar</a>).
                </p>
            </div>
        </div>

        <!-- Finans -->
        <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard label="Gelir" :value="tl(summary.revenue)" :icon="Wallet" color="primary" :change="delta(summary.revenue, previous.revenue)" hint="önceki döneme göre" />
            <StatCard
                label="Toplam Gider"
                :value="tl(totalCost(summary))"
                :icon="Receipt"
                color="carb"
                invert
                :change="delta(totalCost(summary), totalCost(previous))"
                hint="komisyon + AI + diğer"
            />
            <StatCard
                label="Net Kâr"
                :value="tl(summary.net)"
                :icon="PiggyBank"
                :color="summary.net >= 0 ? 'success' : 'danger'"
                :hint="summary.margin_pct !== null ? `Kâr marjı ${pct(summary.margin_pct)}` : 'Henüz gelir yok'"
            />
            <StatCard
                label="AI / Gelir Oranı"
                :value="pct(summary.ai_ratio_pct)"
                :icon="Sparkles"
                :color="aiRatioHigh ? 'danger' : 'success'"
                :hint="`${usd(summary.ai_cost_usd, 2)} · hedef ≤ ${pct(aiRatioAlert)}`"
            />
        </div>

        <div class="mt-4 grid gap-4 xl:grid-cols-3">
            <div class="card p-5 xl:col-span-2">
                <h3 class="mb-2 font-bold">Günlük Gelir / Gider</h3>
                <apexchart type="area" height="300" :options="trendOptions" :series="trendSeries" />
            </div>
            <div class="card p-5">
                <h3 class="mb-2 font-bold">Gider Dağılımı</h3>
                <apexchart v-if="totalCost(summary) > 0" type="donut" height="300" :options="donutOptions" :series="costBreakdown" />
                <div v-else class="flex h-[300px] items-center justify-center text-sm text-ink-muted">Bu dönemde gider yok</div>
            </div>
        </div>

        <!-- Kullanıcılar & AI -->
        <h2 class="mb-4 mt-8 text-xl font-bold">Kullanıcılar ve Yapay Zekâ</h2>
        <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard label="Toplam Kullanıcı" :value="num(users.total)" :icon="Users" color="primary" :hint="`${num(users.new)} yeni kayıt`" />
            <StatCard label="Premium" :value="num(users.premium)" :icon="Crown" color="carb" :hint="`Dönüşüm ${pct(users.conversion_pct)} · ${num(subscriptions.active)} aktif abonelik`" />
            <StatCard label="Bugün Aktif" :value="num(users.active_today)" :icon="Activity" color="success" hint="bugün öğün ekleyen" />
            <StatCard label="Yeni Kayıt" :value="num(users.new)" :icon="UserPlus" color="water" :hint="`son ${days} gün`" />
        </div>

        <div class="mt-4 grid gap-4 xl:grid-cols-3">
            <div class="card flex flex-col items-center p-5">
                <h3 class="self-start font-bold">Bugünkü AI Bütçesi</h3>
                <apexchart type="radialBar" height="230" :options="ringOptions" :series="[Math.round(budgetPct)]" />
                <p class="-mt-2 text-sm text-ink-secondary">Günlük limit: <b class="text-ink dark:text-white">{{ usd(ai.budget_usd) }}</b></p>
                <p class="mt-1 text-center text-xs text-ink-muted">Limit dolunca ücretsiz kullanıcılarda AI geçici olarak kapanır, premium devam eder.</p>
            </div>
            <div class="grid gap-4 sm:grid-cols-2 xl:col-span-2">
                <StatCard label="AI Analizi" :value="num(ai.analyses)" :icon="Zap" color="primary" :hint="`${num(ai.failed)} hatalı`" />
                <StatCard label="Önbellekten Dönen" :value="pct(ai.cache_hit_pct)" :icon="DatabaseZap" color="success" hint="maliyetsiz analiz oranı" />
                <StatCard label="Analiz Başına Maliyet" :value="usd(ai.avg_cost_usd, 4)" :icon="CircleDollarSign" color="carb" hint="önbellek hariç ortalama" />
                <StatCard label="Dönem AI Maliyeti" :value="tl(summary.ai_cost)" :icon="Sparkles" color="water" :hint="usd(summary.ai_cost_usd, 2)" />
            </div>
        </div>
    </AdminLayout>
</template>
