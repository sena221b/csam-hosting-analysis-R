# CSAM Barındırma Analizi ve Karar Ağacıyla Tahmin

Bu proje, yayımlanmış ülke bazlı CSAM istatistiklerini etkileşimli bir dünya haritasında gösterir. Ayrıca 2024 verilerini kullanarak 2025 değerlerini tahmin eden bir karar ağacı kurar ve modelin tahminlerini ayrı test verisinde değerlendirir.

Proje, adli bilimlerle ilgili bir veri setinde tahmin modeli kurulmasını isteyen ders ödevi için hazırlanmıştır.

> Bu bir gerçek olay, mağdur, fail veya indirme noktası haritası değildir. Proje istismar içeriği indirmez; bu içeriklere ait ham URL listeleri, IP adresleri veya kişisel veriler toplamaz.

## Proje ne yapıyor?

- **Veriyi gösterir:** Ülkelerin tespit edilmiş CSAM barındırma hacmini haritada sunar.
- **Tahmin yapar:** Önceki yılın URL ve alan adı adetlerinden sonraki yılın URL adedini tahmin eder.
- **Başarıyı ölçer:** Karar ağacını, eğitimde kullanılmamış test ülkelerinde değerlendirir.
- **Karşılaştırma yapar:** Modeli, “önceki yıl aynı kalsın” ve “eğitim ortalaması” gibi iki basit yöntemle karşılaştırır.
- **Çıktı üretir:** Harita, karar ağacı görseli, değerlendirme grafikleri, CSV tabloları ve açıklayıcı rapor oluşturur.

## Hızlı başlangıç

### Gerekenler

R ve RStudio kullanılır. Kodun ihtiyaç duyduğu paketler `leaflet`, `htmlwidgets`, `htmltools` ve `rpart` paketleridir; eksik paketler varsa script bunları kurmayı dener.

Veri tabloları R dosyasının içinde bulunduğu için ayrıca veri dosyası indirmeniz gerekmez. Paket kurulumu ve harita altlıklarının yüklenmesi için internet bağlantısı gerekir.

### Çalıştırma

1. `csam_chapter4_karar_agaci.R` dosyasını bilgisayarınıza indirin.
2. Dosyayı RStudio'da açın.
3. **Source** düğmesine basın.

Alternatif olarak, R dosyasının bulunduğu klasör çalışma dizini seçiliyken aşağıdaki komutu çalıştırın:

```r
source("csam_chapter4_karar_agaci.R", encoding = "UTF-8")
```

Script; veriyi hazırlar, modeli eğitir, sonuçları hesaplar ve haritayı gösterir. Çıktılar, R'nin o anki çalışma dizini altında oluşturulan `csam_chapter4_ciktilari` klasörüne kaydedilir.

Çalışma dizininizi görmek için:

```r
getwd()
```

## Veriler neyi ifade ediyor?

CSAM, çocukların cinsel istismarını içeren materyaller için kullanılan kısaltmadır. Ana veri kaynağı olan Internet Watch Foundation (IWF), ülke tablosunda CSAM gösteren veya CSAM'a yönlendiren ve işlem yaptığı web adreslerini, barındırıldıkları ülkeye göre sayar ([IWF 2025 açıklaması](https://www.iwf.org.uk/annual-data-insights-report-2025/online-hosting/geographic-insights)).

Burada **URL bir web adresi**, **alan adı ise URL'nin bağlı olduğu site adıdır**. Aynı alan adına bağlı birden fazla URL bulunabileceğinden bu iki adet aynı ölçü değildir.

| Veri | Projedeki görevi | Yayın |
|---|---|---|
| 2024 ülke bazlı CSAM bağlantılı URL adedi | Modelin birinci girdisi | [IWF 2024 URL tablosu](https://www.iwf.org.uk/annual-data-insights-report-2024/data-and-insights/geographical-hosting-urls/) |
| 2024 ülke bazlı alan adı adedi | Modelin ikinci girdisi | [IWF 2024 alan adı tablosu](https://www.iwf.org.uk/annual-data-insights-report-2024/data-and-insights/geographical-hosting-domains) |
| 2025 ülke bazlı CSAM bağlantılı URL adedi | Tahmin edilmek istenen hedef ve gözlenen harita katmanı | [IWF 2025 ülke tablosu](https://www.iwf.org.uk/annual-data-insights-report-2025/online-hosting/geographic-insights) |

IWF'nin 2025 tablosundaki toplam 310.437 URL'dir. Bu, tüm internetin eksiksiz sayımı değil, IWF'nin ilgili dönemde tespit edip işlem yaptığı kapsamdır ([IWF 2025](https://www.iwf.org.uk/annual-data-insights-report-2025/online-hosting/geographic-insights)).

Kod, 28.10.2026 tarihinde erişilen yayın tablolarının gömülü bir kopyasını kullanır. Her çalıştırmada sitelerden güncel veri çekmez.

### Neden haritada ve modelde farklı sayıda ülke var?

Haritada 2025 verisi bulunan ve konumu eşleştirilen **69 ülke/bölge** gösterilir. Model ise hem 2024 URL ve alan adı adetleri hem de 2025 hedefi bulunan **55 tam kaydı** kullanır.

Bir ülkede gerekli ölçümlerden biri eksikse o kayıt modele alınmaz. Eksik değerler sıfırla doldurulmaz; dışlama nedenleri ayrı CSV dosyasına yazılır.

## Karar ağacı nasıl çalışıyor?

Modelin yanıtlamaya çalıştığı soru şudur:

> Bir ülkenin 2024 URL ve alan adı adetlerini biliyorsak, 2025 CSAM bağlantılı URL adedini tahmin edebilir miyiz?

Bu model bir sınıflandırma modeli değil, **sayısal değer tahmin eden bir regresyon ağacıdır**. Ülkeleri “suçlu” veya “suçsuz” olarak sınıflandırmaz.

İşlem sırası:

1. **Verileri eşleştirme:** 2024 ve 2025 tabloları ülke koduyla birleştirilir.
2. **Eksikleri ayırma:** Gerekli ölçümleri bulunmayan kayıtlar ve ülkeye atanamayan Onion kategorisi dışlanır.
3. **Eğitim/test ayrımı:** Sabit `1234` tohumu ile 38 ülke eğitim, 17 ülke test için ayrılır. Bu, yaklaşık %70 / %30 ayrımdır.
4. **Ağacı eğitme:** `rpart` ile yalnız eğitim ülkelerinden karar kuralları öğrenilir.
5. **Budama:** Eğitim içinde beş katlı çapraz doğrulama uygulanır. En düşük çapraz doğrulama hatasını veren CP seçilerek gereksiz dallar budanır; `prune()` işlemi bu amaçla kullanılır ([rpart budama belgesi](https://stat.ethz.ch/R-manual/R-devel/library/rpart/html/prune.rpart.html)).
6. **Test tahmini:** Eğitimde kullanılmamış 17 ülke için tahmin yapılır.
7. **Değerlendirme:** Tahminler gerçek yayımlanmış değerlerle ve iki basit karşılaştırma yöntemiyle karşılaştırılır.

### Neden logaritmik dönüşüm var?

URL adetlerinin küçük değerlerle çok büyük değerleri birlikte içermesi nedeniyle hedefe `log1p()` dönüşümü uygulanır. Böylece model `log(1 + URL)` değerini öğrenir; tahminler daha sonra `expm1()` ile URL ölçeğine geri çevrilir.

Model formülü:

```r
log_url_2025 ~ url_2024 + domain_2024
```

Geri dönüşüm:

```r
tahmin_url_2025 <- pmax(0, expm1(tahmin_log))
```

Bu yüzden tahminler ondalıklı olabilir; tahmin edilen bir adet, gözlenmiş bir kayıt sayısı değildir. Ters dönüşüm log-ölçekli bir merkez tahmini verir; aritmetik koşullu ortalama iddiası taşımaz.

### Veri sızıntısı nasıl önleniyor?

2025 URL adedi yalnızca hedef olarak kullanılır. 2025 payı, 2025 yoğunluk sınıfı, ülke adı/kodu ve koordinatlar modele girdi yapılmaz; test ülkeleri eğitim veya budama seçimine katılmaz.

Ülke kodu yalnız kayıt eşleştirmek için, koordinatlar yalnız haritada göstermek için kullanılır. Başarı ölçümleri eğitim-içi tahminlerden değil, ayrılmış test tahminlerinden hesaplanır.

## Harita nasıl okunur?

| Gösterim | Anlamı |
|---|---|
| Kırmızı kare | IWF'nin yayımladığı, gözlenen 2025 URL adedi |
| Sarı kare | Karar ağacının yalnız test ülkeleri için ürettiği 2025 tahmini |
| Daha güçlü iç dolgu | Daha yüksek URL adedi aralığı |
| Sabit kare boyutu | Kare büyüklüğü olay sayısını veya coğrafi alanı temsil etmez |

Gözlenen katman başlangıçta açıktır. Katman kontrolünden `MODEL | rpart test tahmini 2025` seçildiğinde gözlenen ana katman otomatik kapanır; böylece gerçek değerlerle model tahminleri üst üste karışmaz.

Sarı bir kareye tıklayınca ülke, tahmin, gözlenen değer ve tahmin hatası açılır. **Pozitif hata fazla tahmini, negatif hata eksik tahmini** ifade eder; hata `tahmin − gözlenen` olarak hesaplanır.

Haritadaki “yoğunluk”, tespit edilen URL hacmini anlatır. Nüfus veya kilometrekare başına oran değildir; kareler ülke içindeki olay, sunucu veya kullanıcı konumlarını göstermez.

### Ek kaynak katmanları

Önceki projeden korunan NCMEC bildirimleri ve Kanada kent/kır polis kayıt oranları ayrı katmanlarda, başlangıçta kapalı tutulur. Bunlar karar ağacına girdi yapılmaz ve IWF URL adetleriyle toplanmaz.

Bu ek tablolar son modelleme düzenlemesinde yeniden doğrulanmamıştır. Modelin yöntem ve sonuçlarını incelemek için esas alınan veriler, yukarıdaki üç IWF tablosudur.

## Örnek test sonuçları

Aşağıdaki sonuçlar, sabit tohumlu örnek çalıştırmadaki **17 test ülkesi** için hesaplanmıştır. Kullanılan R ve paket sürümleri çıktı klasöründeki `R_sessionInfo.txt` dosyasına kaydedilir.

| Yöntem | MAE: ortalama mutlak hata | RMSE | RMSLE | R² |
|---|---:|---:|---:|---:|
| Karar ağacı | 2.516,79 URL | 5.406,27 URL | 1,9757 | 0,5370 |
| Önceki yıl aynı kalsın | 4.156,88 URL | 12.222,91 URL | 2,1615 | −1,3665 |
| Eğitim ortalaması | 6.575,73 URL | 8.589,59 URL | 4,9744 | −0,1687 |

- **MAE:** Tahminin ortalama kaç URL yanıldığını gösterir. Daha küçük değer daha iyidir.
- **RMSE:** Büyük hatalara daha fazla ağırlık verir. Daha küçük değer daha iyidir.
- **RMSLE:** Logaritmik ölçekteki tahmin hatasını ölçer. Daha küçük değer daha iyidir.
- **R²:** Kareli hatayı, test değerlerinin ortalamasını kullanan referansa göre değerlendirir. Negatif olabilir; sınıflandırma doğruluğu yüzdesi değildir.

“Önceki yıl aynı kalsın” yöntemi, 2025 tahminini doğrudan 2024 URL adedine eşitler. “Eğitim ortalaması” yöntemi ise her test ülkesine, eğitim ülkelerinin ortalama 2025 değerini tahmin eder.

Bu test ayrımında karar ağacı, iki basit yönteme göre daha düşük hata vermiştir. Bu sonuç modelin her ülkede veya sonraki yıllarda aynı başarıyı göstereceği anlamına gelmez; **R² = 0,5370, “%53,7 doğruluk” demek değildir.**

## Üretilen dosyalar

Başlangıç için depoda aşağıdaki iki dosyanın bulunması yeterlidir. Çıktı klasörü script çalıştırıldığında oluşturulur.

```text
proje/
├── README.md
├── csam_chapter4_karar_agaci.R
└── csam_chapter4_ciktilari/       # Çalıştırılınca oluşur
```

| Önemli çıktı | İçeriği |
|---|---|
| `csam_chapter4_harita.html` | Etkileşimli harita ve model paneli |
| `karar_agaci.png` | Budanmış karar ağacı; yapraklarda URL ölçeğine çevrilmiş tahminler |
| `gozlenen_tahmin_karsilastirmasi.png` | Test tahminleri ve gözlenen değerlerin karşılaştırması |
| `budama_cv_hatasi.png` | Eğitim içindeki çapraz doğrulama hatası |
| `degisken_onemi.png` | Ağaçtaki değişken önemleri |
| `model_test_metrikleri.csv` | Üç yöntemin test başarı ölçümleri |
| `model_test_tahminleri.csv` | Yalnız test ülkelerinin tahminleri ve hataları |
| `model_tum_kayitlar_egitim_test.csv` | Eğitim/test etiketiyle tüm model kayıtları |
| `model_dislanan_kayitlar.csv` | Modele alınmayan kayıtlar ve nedenleri |
| `model_raporu.md` | Yöntem, sonuçlar, veri bağlantıları ve sınırlılıklar |
| `rpart_karar_agaci.rds` | Kaydedilmiş model, ülke ayrımı ve dönüşüm bilgisi |
| `R_sessionInfo.txt` | R ve paket sürümleri |

Kaynak tabloları, eşleştirme kayıtları, CP tablosu ve haritada gösterilemeyen kayıtlar da ayrı CSV dosyalarına yazılır. Eğitim ve test tahminleri aynı dosyada bulunsa bile başarı değerlendirmesinde yalnız test kayıtları kullanılır.

Haritayı daha sonra açmak için üretilen HTML dosyasını tarayıcıda açabilirsiniz. Pandoc bulunmadığında HTML'nin yanında bir `*_files` klasörü de oluşur; dosyayı taşırken bu klasörü de yanında tutun.

## Sınırlılıklar ve dikkat edilmesi gerekenler

- **Kapsam sınırlıdır:** Veri tüm interneti değil, IWF'nin tespit kapsamını yansıtır. Barındırma ülkesi gerçek olay yeri veya mağdurun/failin ülkesi olarak yorumlanmaz ([IWF coğrafi açıklaması](https://www.iwf.org.uk/annual-data-insights-report-2025/online-hosting/geographic-insights)).
- **Tek yıllık geçiş vardır:** Model 2024'ten 2025'e geçişi inceler. Bu geriye dönük bir deneydir; sonraki yıllarda sınanmış bir erken uyarı sistemi değildir.
- **Örneklem küçüktür:** Yalnız tam ölçümlü 55 kayıt modele girer. Tek eğitim/test ayrımı belirsizlik taşır ve eksik ölçümlü ülkelerin dışlanması sonuçların kapsamını sınırlar.
- **Nedensellik kurulmaz:** Değişken önemi, bir göstergenin CSAM'a neden olduğunu veya bağımsız etkisini kanıtlamaz.
- **Eksik veri sıfır değildir:** Yayın tablosunda bulunmayan ülkeler için “CSAM yok” sonucu çıkarılmaz.
- **Kaynak tutarsızlığı korunur:** IWF'nin 2025 küresel tablosunda Birleşik Krallık 950 URL, aynı sayfanın UK metninde 951 URL olarak geçer. Kod küresel tablodaki 950 değerini korur ve farkı metadata içinde belirtir ([IWF 2025](https://www.iwf.org.uk/annual-data-insights-report-2025/online-hosting/geographic-insights)).
- **Kullanım amacı eğitimdir:** Proje kişi veya kurumlar hakkında operasyonel, adli ya da hukuki karar vermek amacıyla kullanılmamalıdır.

## Sık karşılaşılan sorunlar

| Sorun | Kontrol edilecek nokta |
|---|---|
| R dosyası bulunamıyor | `getwd()` ile çalışma dizinini kontrol edin veya dosyayı RStudio'da açıp Source'a basın. |
| Paket kurulumu başarısız | İnternet bağlantısını ve R paket klasörüne yazma iznini kontrol edin. |
| Türkçe karakterler bozuk | Dosyayı UTF-8 olarak açın; yukarıdaki `source(..., encoding = "UTF-8")` komutunu kullanın. |
| Harita altlığı yüklenmiyor | İnternet bağlantısını kontrol edin ve diğer altlığı deneyin. Ülke istatistikleri ile altlık servisi birbirinden ayrıdır. |
| Taşınan HTML açılıyor ama harita çalışmıyor | HTML yanında üretilmiş `*_files` klasörünün de taşındığından emin olun. |

Projenin temel amacı, açık ve toplulaştırılmış bir adli bilim verisini anlamlandırmak ve karar ağacının tahmin gücünü ölçmektir. Harita sunum aracıdır; ödevin tahmin modeli, eğitim/test ayrımı ve değerlendirme bölümleriyle birlikte ele alınmalıdır.
