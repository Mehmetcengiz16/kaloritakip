/** Mobil uygulamanın tasarım token'ları (mobile/lib/core/theme/app_colors.dart) ile birebir aynı. */
export default {
    darkMode: 'class',
    content: ['./resources/views/**/*.blade.php', './resources/js/**/*.{vue,js}'],
    theme: {
        extend: {
            fontFamily: { sans: ['"Inter Variable"', 'Inter', 'system-ui', 'sans-serif'] },
            colors: {
                primary: { DEFAULT: '#7C3AED', light: '#8B5CF6', dark: '#6D28D9', soft: '#F3EEFF' },
                ink: { DEFAULT: '#1A1A2E', secondary: '#6B7280', muted: '#9CA3AF' },
                line: '#ECEBF2',
                track: '#EFEDF5',
                muted: '#FAFAFC',
                protein: '#7C3AED',
                carb: '#F59E0B',
                fat: '#FACC15',
                success: '#22C55E',
                water: '#3B82F6',
                danger: '#EF4444',
            },
            borderRadius: { card: '16px', btn: '14px' },
            boxShadow: { soft: '0 4px 12px rgba(26, 26, 46, 0.04)' },
        },
    },
    plugins: [],
};
