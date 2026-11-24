const tr = 'tr-TR';

export const num = (v, digits = 0) =>
    v === null || v === undefined ? '—' : Number(v).toLocaleString(tr, { minimumFractionDigits: digits, maximumFractionDigits: digits });

export const tl = (v) => {
    if (v === null || v === undefined) return '—';
    const n = Math.abs(v) < 0.5 ? 0 : Number(v); // "-₺0" görünmesin
    return n.toLocaleString(tr, { style: 'currency', currency: 'TRY', maximumFractionDigits: 0 });
};

/** Küçük tutarlar için kuruş altı hassasiyet: 0,0172 ₺ */
export const tlFine = (v, digits = 4) =>
    v === null || v === undefined
        ? '—'
        : Number(v).toLocaleString(tr, { minimumFractionDigits: digits, maximumFractionDigits: digits }) + ' ₺';

export const usd = (v, digits = 2) =>
    v === null || v === undefined ? '—' : '$' + Number(v).toLocaleString('en-US', { minimumFractionDigits: digits, maximumFractionDigits: digits });

export const pct = (v) => (v === null || v === undefined ? '—' : `%${num(v, 1)}`);

/** Önceki döneme göre değişim yüzdesi. */
export const delta = (now, prev) => (!prev ? null : Math.round(((now - prev) / Math.abs(prev)) * 1000) / 10);

export const goalLabels = { lose: 'Kilo Vermek', gain: 'Kilo Almak', maintain: 'Kilo Korumak', healthy: 'Sağlıklı Beslenmek' };

export const statusLabels = {
    done: ['Başarılı', 'bg-success/10 text-success'],
    failed: ['Hatalı', 'bg-danger/10 text-danger'],
    not_food: ['Yemek yok', 'bg-carb/10 text-carb'],
    pending: ['Bekliyor', 'bg-track text-ink-secondary'],
};

export const sourceLabels = {
    manual: ['Manuel', 'bg-primary-soft text-primary'],
    openfoodfacts: ['Open Food Facts', 'bg-water/10 text-water'],
    ai: ['AI', 'bg-carb/10 text-carb'],
};

export const expenseLabels = {
    server: 'Sunucu',
    storage: 'Depolama / CDN',
    store_fee: 'Mağaza (ek)',
    marketing: 'Reklam / Pazarlama',
    other: 'Diğer',
};

/** Görseli olmayan yemekler için ada göre emoji (mobil: shared/food_emoji.dart ile aynı). */
const foodEmojiRules = [
    [['yumurta', 'omlet', 'menemen'], '🥚'], [['tavuk', 'piliç', 'kanat', 'döner'], '🍗'],
    [['köfte', 'et ', 'kıyma', 'biftek', 'iskender', 'kebap'], '🍖'], [['balık', 'somon', 'ton balığı', 'hamsi', 'levrek'], '🐟'],
    [['çorba'], '🍲'], [['pilav', 'pirinç'], '🍚'], [['bulgur'], '🌾'], [['makarna', 'spagetti', 'mantı'], '🍝'],
    [['salata'], '🥗'], [['ekmek', 'simit', 'poğaça', 'börek'], '🥐'], [['peynir', 'kaşar'], '🧀'],
    [['süt', 'ayran', 'yoğurt', 'kefir'], '🥛'], [['zeytin'], '🫒'], [['fasulye', 'nohut', 'mercimek'], '🫘'],
    [['sarma', 'dolma'], '🍃'], [['lahmacun', 'pide', 'pizza'], '🍕'], [['patates'], '🍟'],
    [['muz'], '🍌'], [['elma'], '🍎'], [['portakal', 'mandalina'], '🍊'], [['çilek'], '🍓'], [['üzüm'], '🍇'],
    [['karpuz'], '🍉'], [['avokado'], '🥑'], [['ceviz', 'badem', 'fındık', 'fıstık'], '🥜'],
    [['baklava', 'tatlı', 'pasta', 'kek', 'sütlaç', 'kurabiye', 'bisküvi', 'gofret', 'çikolata'], '🍰'],
    [['kahve'], '☕'], [['çay'], '🍵'], [['yulaf', 'müsli', 'granola'], '🥣'], [['sebze', 'brokoli', 'kabak', 'ıspanak'], '🥦'],
];
export const foodEmoji = (name = '') => {
    const n = ` ${String(name).toLocaleLowerCase('tr-TR')} `;
    return foodEmojiRules.find(([keys]) => keys.some((k) => n.includes(k)))?.[1] ?? '🍽️';
};
