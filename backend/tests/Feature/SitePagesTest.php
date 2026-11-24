<?php

namespace Tests\Feature;

use Tests\TestCase;

class SitePagesTest extends TestCase
{
    public function test_landing_and_policy_pages_render(): void
    {
        $this->withoutVite();

        $pages = [
            '/' => 'Fotoğrafını çek',
            '/gizlilik' => 'Gizlilik Politikası',
            '/kullanim-kosullari' => 'Standart Son Kullanıcı Lisans Sözleşmesi',
            '/abonelik-kosullari' => 'en az 24 saat önce',
            '/kvkk' => '6698 sayılı',
            '/hesap-silme' => 'Hesabımı ve verilerimi sil',
            '/destek' => 'Nasıl yardımcı olabiliriz',
        ];

        foreach ($pages as $url => $text) {
            $this->get($url)->assertOk()->assertSee($text, false);
        }

        // Politika sayfalarında demo uyarısı ve birbirine linkler
        $this->get('/gizlilik')->assertSee('demo', false)->assertSee(route('site.kvkk'), false);
        $this->get('/abonelik-kosullari')->assertSee('apps.apple.com/account/subscriptions', false)
            ->assertSee('play.google.com/store/account/subscriptions?package=com.kaloritakip.kaloritakip', false);
    }
}
