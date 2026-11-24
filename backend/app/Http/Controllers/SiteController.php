<?php

namespace App\Http\Controllers;

/** Tanıtım ve politika sayfaları (App Store / Google Play mağaza kayıtlarında kullanılacak adresler). */
class SiteController extends Controller
{
    public function home() { return view('site.home'); }
    public function privacy() { return view('site.privacy'); }
    public function terms() { return view('site.terms'); }
    public function subscription() { return view('site.subscription'); }
    public function kvkk() { return view('site.kvkk'); }
    public function deletion() { return view('site.deletion'); }
    public function support() { return view('site.support'); }
}
