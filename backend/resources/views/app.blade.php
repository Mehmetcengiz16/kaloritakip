<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex, nofollow">
    <script>
        // Koyu tema tercihini ilk boyamadan önce uygula (yanıp sönmeyi önler).
        if (localStorage.getItem('theme') === 'dark') document.documentElement.classList.add('dark');
    </script>
    @vite(['resources/js/app.js'])
    @inertiaHead
</head>
<body>
    @inertia
</body>
</html>
