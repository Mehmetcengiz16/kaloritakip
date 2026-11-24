{{-- Gerçek uygulama ekran görüntüsünü telefon çerçevesi içinde gösterir. <x-phone src="home" alt="..." class="w-64" /> --}}
@props(['src', 'alt' => '', 'eager' => false])
<div {{ $attributes->merge(['class' => 'shrink-0']) }}>
    <div class="overflow-hidden rounded-[2.4rem] border-[7px] border-[#1A1A2E] bg-[#1A1A2E] shadow-[0_30px_60px_-20px_rgba(26,26,46,0.35)]">
        <img src="{{ asset('images/screens/'.$src.'.webp') }}" alt="{{ $alt }}" width="540" height="1086" loading="{{ $eager ? 'eager' : 'lazy' }}" decoding="async" @if($eager) fetchpriority="high" @endif class="block h-auto w-full rounded-[1.9rem] bg-white">
    </div>
</div>
