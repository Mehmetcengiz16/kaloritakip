@php($s = config('site'))
<div class="flex flex-wrap gap-3 {{ $class ?? '' }}">
    <a href="{{ $s['app_store_url'] }}" class="inline-flex h-14 items-center gap-3 rounded-2xl bg-ink px-5 text-white transition hover:bg-black" aria-label="App Store'dan indir">
        <svg viewBox="0 0 24 24" class="h-7 w-7" fill="currentColor"><path d="M16.37 12.6c-.02-2.2 1.8-3.26 1.88-3.31-1.03-1.5-2.62-1.7-3.18-1.73-1.35-.14-2.64.8-3.33.8-.69 0-1.74-.78-2.87-.76a4.25 4.25 0 0 0-3.6 2.18c-1.54 2.66-.39 6.6 1.1 8.76.73 1.06 1.6 2.24 2.74 2.2 1.1-.05 1.51-.71 2.84-.71 1.32 0 1.7.71 2.86.69 1.18-.02 1.93-1.07 2.65-2.13.84-1.22 1.18-2.41 1.2-2.47-.03-.01-2.27-.87-2.29-3.52ZM14.2 6.15c.6-.73 1.01-1.75.9-2.76-.87.03-1.92.58-2.54 1.31-.56.64-1.05 1.67-.92 2.66.97.08 1.96-.49 2.56-1.21Z"/></svg>
        <span class="leading-tight"><span class="block text-[10px] uppercase tracking-wide opacity-80">İndir</span><span class="block text-base font-bold">App Store</span></span>
    </a>
    <a href="{{ $s['play_store_url'] }}" class="inline-flex h-14 items-center gap-3 rounded-2xl bg-ink px-5 text-white transition hover:bg-black" aria-label="Google Play'den edinin">
        <svg viewBox="0 0 24 24" class="h-6 w-6" fill="currentColor"><path d="M3.6 2.2c-.2.2-.3.6-.3 1v17.6c0 .4.1.8.3 1l.1.1 9.9-9.9v-.2L3.7 2.1l-.1.1Zm13.3 13.2-3.3-3.3v-.2l3.3-3.3.1.1 3.9 2.2c1.1.6 1.1 1.7 0 2.3l-3.9 2.2h-.1Zm.1-.1-3.4-3.4L3.6 21.8c.4.4 1 .4 1.7.1l11.7-6.6m0-6.6L5.3 2.1c-.7-.4-1.3-.3-1.7.1l10 10 3.4-3.4Z"/></svg>
        <span class="leading-tight"><span class="block text-[10px] uppercase tracking-wide opacity-80">Edinin</span><span class="block text-base font-bold">Google Play</span></span>
    </a>
</div>
