<?php

namespace Database\Seeders;

use App\Models\Food;
use Illuminate\Database\Seeder;

/**
 * Temel yemek listesi (100 g başına yaklaşık değerler). Admin panelden genişletilebilir.
 */
class FoodSeeder extends Seeder
{
    public function run(): void
    {
        // [ad, kcal, protein, karb, yağ, varsayılan porsiyon (g)]
        $foods = [
            ['Tavuk göğsü ızgara', 165, 31, 0, 3.6, 120],
            ['Tavuk sote', 150, 20, 4, 6, 200],
            ['Köfte (ızgara)', 250, 18, 6, 17, 120],
            ['Kuru fasulye', 110, 6.5, 15, 3, 250],
            ['Mercimek çorbası', 60, 3.5, 9, 1.2, 250],
            ['Ezogelin çorbası', 65, 3, 10, 1.5, 250],
            ['Pirinç pilavı', 175, 3, 30, 4.5, 150],
            ['Bulgur pilavı', 150, 4, 26, 3.5, 150],
            ['Makarna (haşlanmış)', 158, 5.8, 31, 0.9, 200],
            ['Mantı (yoğurtlu)', 180, 8, 22, 7, 250],
            ['Lahmacun', 235, 11, 31, 7.5, 150],
            ['Su böreği', 290, 11, 25, 16, 150],
            ['Menemen', 110, 6, 5, 7.5, 200],
            ['Haşlanmış yumurta', 155, 13, 1.1, 11, 50],
            ['Beyaz peynir', 265, 17, 2, 21, 40],
            ['Kaşar peyniri', 360, 25, 1.5, 28, 30],
            ['Siyah zeytin', 180, 1.6, 4, 18, 30],
            ['Tam buğday ekmeği', 245, 9, 43, 3.4, 50],
            ['Beyaz ekmek', 265, 8.5, 50, 3.2, 50],
            ['Simit', 290, 9, 52, 5, 100],
            ['Yulaf ezmesi', 380, 13, 66, 7, 50],
            ['Yoğurt (tam yağlı)', 63, 3.5, 4.7, 3.3, 150],
            ['Ayran', 36, 1.7, 2.5, 2, 200],
            ['Süt (tam yağlı)', 61, 3.2, 4.8, 3.3, 200],
            ['Zeytinyağlı taze fasulye', 85, 2, 8, 5, 200],
            ['Zeytinyağlı yaprak sarma', 175, 2.5, 22, 8.5, 150],
            ['Çoban salata', 45, 1, 5, 2.5, 150],
            ['Mevsim salata', 35, 1.2, 5, 1.5, 150],
            ['Somon (fırın)', 205, 22, 0, 13, 150],
            ['Ton balığı (konserve, süzülmüş)', 130, 29, 0, 1, 80],
            ['Döner (tavuk)', 210, 19, 5, 13, 150],
            ['İskender', 230, 13, 12, 15, 350],
            ['Patates kızartması', 312, 3.4, 41, 15, 150],
            ['Muz', 89, 1.1, 23, 0.3, 120],
            ['Elma', 52, 0.3, 14, 0.2, 180],
            ['Portakal', 47, 0.9, 12, 0.1, 180],
            ['Çilek', 32, 0.7, 7.7, 0.3, 150],
            ['Ceviz', 654, 15, 14, 65, 20],
            ['Badem', 579, 21, 22, 50, 20],
            ['Fındık', 628, 15, 17, 61, 20],
            ['Avokado', 160, 2, 8.5, 14.7, 100],
            ['Baklava', 430, 6, 50, 23, 60],
            ['Sütlaç', 130, 3.5, 22, 3, 150],
            ['Türk kahvesi (şekersiz)', 2, 0.1, 0, 0, 70],
            ['Çay (şekersiz)', 1, 0, 0.3, 0, 100],
        ];

        foreach ($foods as [$name, $kcal, $p, $c, $f, $portion]) {
            Food::updateOrCreate(
                ['name' => $name, 'source' => 'manual'],
                [
                    'kcal_per_100g' => $kcal,
                    'protein_per_100g' => $p,
                    'carb_per_100g' => $c,
                    'fat_per_100g' => $f,
                    'default_portion_g' => $portion,
                    'verified' => true,
                ],
            );
        }
    }
}
