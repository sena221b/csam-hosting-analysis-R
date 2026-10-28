# ==============================================================================
# CSAM BARINDIRMA YOĞUNLUĞU
# ==============================================================================
# UTF-8: source("csam_chapter4_karar_agaci.R", encoding = "UTF-8")
# Araştırma: 2024 URL/domain sayılarıyla 2025 ülke URL sayısını tahmin etmek.
# Model: ülke bazlı %70 eğitim / %30 test; log1p hedefli rpart regresyon ağacı.
# 2024 URL:
# https://www.iwf.org.uk/annual-data-insights-report-2024/data-and-insights/geographical-hosting-urls/
# 2024 domain:
# https://www.iwf.org.uk/annual-data-insights-report-2024/data-and-insights/geographical-hosting-domains
# Ana veri: IWF 2025 Global hosting by country; erişim: 2026-10-28.
# https://www.iwf.org.uk/annual-data-insights-report-2025/online-hosting/geographic-insights
# Her sayı: CSAM gösteren veya CSAM'a yönlendiren, IWF'nin işlem yaptığı URL adedi.
# Ham CSAM adresi, IP, sunucu veya indirme noktası bu dosyada yoktur.
# Gerçek kaynak tabloları: NCMEC 2025; Statistics Canada 2024.
# Ek tablolar önceki projemden korunmuştur; bu sürümde yeniden doğrulanmamıştır.
# Bu ek tablolar modele girdi yapılmaz; doğrulanmış suç sayısı sayılmazlar.
# https://www.missingkids.org/content/dam/missingkids/pdfs/2025-reports-by-country.pdf
# https://www.missingkids.org/content/dam/missingkids/pdfs/2025-reports-by-state.pdf
# https://www150.statcan.gc.ca/n1/pub/85-002-x/2026001/article/00007/tbl/tbl06-eng.htm
# https://www150.statcan.gc.ca/n1/pub/85-002-x/2026001/article/00007/tbl/tbl07-eng.htm
# Ülke koordinatları: Google DSPL countries.csv
# https://developers.google.com/public-data/docs/canonical/countries_csv
# CARTO anahtar gereksinimi:
# https://docs.carto.com/faqs/carto-basemaps
# Koyu altlık servis bilgisi:
# https://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer

gerekli_paketler <- c("leaflet", "htmlwidgets", "htmltools", "rpart")
eksik_paketler <- gerekli_paketler[
  !vapply(gerekli_paketler, requireNamespace, logical(1), quietly = TRUE)
]
if (length(eksik_paketler)) {
  message("Eksik paketler kuruluyor: ", paste(eksik_paketler, collapse = ", "))
  tryCatch(
    utils::install.packages(eksik_paketler, repos = "https://cloud.r-project.org"),
    error = function(e) message("Paket kurulum açıklaması: ", conditionMessage(e))
  )
  halen_eksik <- gerekli_paketler[
    !vapply(gerekli_paketler, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(halen_eksik)) stop(
    "Paketler kurulamadı: ", paste(halen_eksik, collapse = ", "),
    ". İnternet bağlantısını ve R paket klasörü yazma iznini kontrol edin.",
    call. = FALSE
  )
}
suppressPackageStartupMessages({
  library(leaflet)
  library(htmlwidgets)
})

# ==============================================================================
# 1. VERİ SOYUTLAMA KATMANI
# ==============================================================================
# Gömülü resmî kaynak tabloları
.adli_resmi_tablolar <- list(
  ulke = "geo_id|bolge_adi|lat|lng|yonlendirme|bilgilendirme|deger
AF|Afghanistan|33.93911|67.709953|132644|13792|146436
AX|Åland Islands|<MISSING>|<MISSING>|27|2|29
AL|Albania|41.153332|20.168331|5500|406|5906
DZ|Algeria|28.033886|1.659626|156995|29594|186589
AS|American Samoa|-14.270972|-170.132217|103|18|121
AD|Andorra|42.546245|1.601554|138|38|176
AO|Angola|-11.202692|17.873887|20323|9594|29917
AI|Anguilla|18.220554|-63.068615|80|3|83
AQ|Antarctica|-75.250973|-0.071389|0|1|1
AG|Antigua and Barbuda|17.060816|-61.796428|324|29|353
AR|Argentina|-38.416097|-63.616672|164012|21342|185354
AM|Armenia|40.069099|45.038189|11174|33572|44746
AW|Aruba|12.52111|-69.968338|431|62|493
AU|Australia|-25.274398|133.775136|40783|69722|110505
AT|Austria|47.516231|14.550072|19714|1652|21366
AZ|Azerbaijan|40.143105|47.576927|15164|1099|16263
BS|Bahamas|25.03428|-77.39628|1784|284|2068
BH|Bahrain|25.930414|50.637772|8940|1697|10637
BD|Bangladesh|23.684994|90.356331|596786|100626|697412
BB|Barbados|13.193887|-59.543198|1434|226|1660
BY|Belarus|53.709807|27.953389|49527|294|49821
BE|Belgium|50.503887|4.469936|25529|2333|27862
BZ|Belize|17.189877|-88.49765|1880|102|1982
BJ|Benin|9.30769|2.315834|15156|1794|16950
BM|Bermuda|32.321384|-64.75737|159|6|165
BT|Bhutan|27.514162|90.433601|1586|554|2140
BO|Bolivia|-16.290154|-63.588653|65130|3558|68688
BA|Bosnia and Herzegovina|43.915886|17.679076|6887|639|7526
BW|Botswana|-22.328474|24.684866|3542|391|3933
BR|Brazil|-14.235004|-51.92528|876737|73707|950444
IO|British Indian Ocean Territory|-6.343194|71.876519|3|0|3
VG|British Virgin Islands|18.420695|-64.639968|78|18|96
BN|Brunei|4.535277|114.727669|1410|294|1704
BG|Bulgaria|42.733883|25.48583|19163|4313|23476
BF|Burkina Faso|12.238333|-1.561593|7096|733|7829
BI|Burundi|-3.373056|29.918886|958|70|1028
KH|Cambodia|12.565679|104.990963|48208|8106|56314
CM|Cameroon|7.369722|12.354722|22961|2208|25169
CA|Canada|56.130366|-106.346771|117702|11054|128756
CV|Cape Verde Islands|16.002082|-24.013197|824|301|1125
BQ|Caribbean Netherlands|<MISSING>|<MISSING>|58|3|61
KY|Cayman Islands|19.513469|-80.566956|251|14|265
CF|Central African Republic|6.611111|20.939444|260|24|284
TD|Chad|15.454166|18.732207|2088|142|2230
CL|Chile|-35.675147|-71.542969|77022|9589|86611
CN|China|35.86166|104.195397|7467|1939|9406
CO|Colombia|4.570868|-74.297333|180919|23463|204382
KM|Comoros|-11.875001|43.872219|1352|82|1434
CG|Congo|-0.228021|15.827659|5953|398|6351
CD|Congo, The Democratic Republic of the|-4.038333|21.758664|22681|3001|25682
CK|Cook Islands|-21.236736|-159.777671|41|5|46
CR|Costa Rica|9.748917|-83.753428|19440|2302|21742
CI|Côte d'Ivoire|7.539989|-5.54708|63019|3442|66461
HR|Croatia|45.1|15.2|7893|968|8861
CU|Cuba|21.521757|-77.781167|10956|2014|12970
CW|Curaçao|<MISSING>|<MISSING>|510|39|549
CY|Cyprus|35.126413|33.429859|3900|373|4273
CZ|Czech Republic|49.817492|15.472962|29145|2995|32140
DK|Denmark|56.26392|9.501785|10006|1518|11524
DJ|Djibouti|11.825138|42.590275|454|55|509
DM|Dominica|15.414999|-61.370976|513|43|556
DO|Dominican Republic|18.735693|-70.162651|168485|12655|181140
EC|Ecuador|-1.831239|-78.183406|124225|16909|141134
EG|Egypt|26.820553|30.802498|219500|30398|249898
SV|El Salvador|13.794185|-88.89653|34513|2789|37302
GQ|Equatorial Guinea|1.650801|10.267895|825|342|1167
ER|Eritrea|15.179384|39.782334|7|4|11
EE|Estonia|58.595272|25.013607|5172|391|5563
SZ|Eswatini|-26.522503|31.465866|543|83|626
ET|Ethiopia|9.145|40.489673|6795|574|7369
EP|Europol|<MISSING>|<MISSING>|1016463|86004|1102467
FK|Falkland Islands|-51.796253|-59.523613|17|0|17
FO|Faroe Islands|61.892635|-6.911806|149|9|158
FM|Federated States of Micronesia|7.425554|150.550812|146|26|172
FJ|Fiji|-16.578193|179.414413|1852|861|2713
FI|Finland|61.92411|25.748151|13966|1760|15726
FR|France|46.227638|2.213749|174190|12244|186434
GF|French Guiana|3.933889|-53.125782|1057|43|1100
PF|French Polynesia|-17.679742|-149.406843|454|37|491
GA|Gabon|-0.803689|11.609444|5231|693|5924
GM|Gambia, The|13.443182|-15.310139|1052|136|1188
GE|Georgia|42.315407|43.356892|11168|6491|17659
DE|Germany|51.165691|10.451526|207592|17777|225369
GH|Ghana|7.946527|-1.023194|48003|3595|51598
GI|Gibraltar|36.137741|-5.345374|105|10|115
GR|Greece|39.074208|21.824312|16163|1539|17702
GL|Greenland|71.706936|-42.604303|369|13|382
GD|Grenada|12.262776|-61.604171|951|28|979
GP|Guadeloupe|16.995971|-62.067641|913|71|984
GU|Guam|13.444304|144.793731|316|88|404
GT|Guatemala|15.783471|-90.230759|60824|13718|74542
GG|Guernsey|49.465691|-2.585278|42|57|99
GN|Guinea|9.945587|-9.696645|4259|613|4872
GW|Guinea-Bissau|11.803749|-15.180413|415|22|437
GY|Guyana|4.860416|-58.93018|3765|198|3963
HT|Haiti|18.971187|-72.285215|16689|1373|18062
HN|Honduras|15.199999|-86.241905|31028|2979|34007
HK|Hong Kong|22.396428|114.109497|13636|3721|17357
HU|Hungary|47.162494|19.503304|18526|2610|21136
IS|Iceland|64.963051|-19.020835|1271|92|1363
IN|India|20.593684|78.96288|1769595|164305|1933900
ID|Indonesia|-0.789275|113.921327|968146|213100|1181246
IR|Iran|32.427908|53.688046|73317|10088|83405
IQ|Iraq|33.223191|43.679291|388924|18508|407432
IE|Ireland|53.41291|-8.24389|26628|12330|38958
IM|Isle of Man|54.236107|-4.548056|237|14|251
IL|Israel|31.046051|34.851612|25313|2262|27575
IT|Italy|41.87194|12.56738|268836|11534|280370
JM|Jamaica|18.109581|-77.297508|9878|434|10312
JP|Japan|36.204824|138.252924|185212|52391|237603
JE|Jersey|49.214439|-2.13125|85|240|325
JO|Jordan|30.585164|36.238414|33144|4584|37728
KZ|Kazakhstan|48.019573|66.923684|117646|1530|119176
KE|Kenya|-0.023559|37.906193|41527|3762|45289
KI|Kiribati|-3.370417|-168.734039|261|19|280
KR|Korea, Republic of|35.907757|127.766922|54294|7557|61851
XK|Kosovo|42.602636|20.902977|3118|246|3364
KW|Kuwait|29.31166|47.481766|23765|4252|28017
KG|Kyrgyzstan|41.20438|74.766098|11175|609|11784
LA|Laos|19.85627|102.495496|21962|3421|25383
LV|Latvia|56.879635|24.603189|6176|522|6698
LB|Lebanon|33.854721|35.862285|17151|2709|19860
LS|Lesotho|-29.609988|28.233608|858|69|927
LR|Liberia|6.428055|-9.429499|2572|344|2916
LY|Libya|26.3351|17.228331|47629|3113|50742
LI|Liechtenstein|47.166|9.555373|66|5|71
LT|Lithuania|55.169438|23.881275|9440|772|10212
LU|Luxembourg|49.815273|6.129583|1546|138|1684
MO|Macau|22.198745|113.543873|562|186|748
MG|Madagascar|-18.766947|46.869107|9371|3103|12474
MW|Malawi|-13.254308|34.301525|2338|436|2774
MY|Malaysia|4.210484|101.975766|86809|24887|111696
MV|Maldives|3.202778|73.22068|3428|733|4161
ML|Mali|17.570692|-3.996166|6560|299|6859
MT|Malta|35.937496|14.375416|1274|119|1393
MH|Marshall Islands|7.131474|171.184478|59|13|72
MQ|Martinique|14.641528|-61.024174|808|61|869
MR|Mauritania|21.00789|-10.940835|7546|543|8089
MU|Mauritius|-20.348404|57.552152|3064|357|3421
YT|Mayotte|-12.8275|45.166244|866|69|935
MX|Mexico|23.634501|-102.552784|602813|84635|687448
MD|Moldova|47.411631|28.369885|10997|705|11702
MC|Monaco|43.750298|7.412841|56|6|62
MN|Mongolia|46.862496|103.846656|6115|989|7104
ME|Montenegro|42.708678|19.37439|1771|115|1886
MS|Montserrat|16.742498|-62.187366|16|0|16
MA|Morocco|31.791702|-7.09262|108979|21194|130173
MZ|Mozambique|-18.665695|35.529562|80092|2907|82999
MM|Myanmar|21.913965|95.956223|30174|14011|44185
NA|Namibia|-22.95764|18.49041|2484|181|2665
NR|Nauru|-0.522778|166.931503|28|3|31
NP|Nepal|28.394857|84.124008|34737|7624|42361
NL|Netherlands|52.132633|5.291266|53627|6269|59896
AN|Netherlands Antilles|12.226079|-69.060087|1|0|1
NC|New Caledonia|-20.904305|165.618042|346|19|365
NZ|New Zealand|-40.900557|174.885971|26857|5795|32652
NI|Nicaragua|12.865416|-85.207229|21145|3086|24231
NE|Niger|17.607789|8.081666|2583|198|2781
NG|Nigeria|9.081999|8.675277|724137|24570|748707
NF|Norfolk Island|-29.040835|167.954712|1|1|2
KP|North Korea|40.339852|127.510093|5|7|12
MK|North Macedonia|41.608635|21.745275|3643|325|3968
MP|Northern Mariana Islands|17.33083|145.38469|78|19|97
NO|Norway|60.472024|8.468946|12807|1073|13880
OM|Oman|21.512583|55.923255|34987|2122|37109
PK|Pakistan|30.375321|69.345116|745273|102988|848261
PW|Palau|7.51498|134.58252|50|14|64
PS|Palestinian Territory|31.952162|35.233154|10215|972|11187
PA|Panama|8.537981|-80.782127|14723|1311|16034
PG|Papua New Guinea|-6.314993|143.95555|8275|520|8795
PY|Paraguay|-23.442503|-58.443832|26625|3148|29773
PE|Peru|-9.189967|-75.015152|135755|12931|148686
PH|Philippines|12.879721|121.774017|873277|196428|1069705
PN|Pitcairn, Henderson, Ducie, and Oeno|-24.703615|-127.439308|0|1|1
PL|Poland|51.919438|19.145136|75075|7868|82943
PT|Portugal|39.399872|-8.224454|34596|2933|37529
PR|Puerto Rico|18.220833|-66.590149|4801|1159|5960
QA|Qatar|25.354826|51.183884|19252|4115|23367
RE|Réunion|-21.115141|55.536384|2181|170|2351
RO|Romania|45.943161|24.96676|43405|4517|47922
RU|Russian Federation|61.52401|105.318756|288250|3816|292066
RW|Rwanda|-1.940278|29.873888|1833|187|2020
BL|Saint Barthélemy|<MISSING>|<MISSING>|4|1|5
SH|Saint Helena, Ascension and Tristan da Cunha|-24.143474|-10.030696|1|2|3
KN|Saint Kitts and Nevis|17.357822|-62.782998|241|8|249
LC|Saint Lucia|13.909444|-60.978893|802|34|836
MF|Saint Martin|<MISSING>|<MISSING>|41|4|45
PM|Saint Pierre and Miquelon|46.941936|-56.27111|11|1|12
VC|Saint Vincent and the Grenadines|12.984305|-61.287228|576|18|594
WS|Samoa|-13.759029|-172.104629|225|35|260
SM|San Marino|43.94236|12.457777|52|4|56
ST|São Tomé and Príncipe|0.18636|6.613081|597|98|695
SA|Saudi Arabia|23.885942|45.079162|336142|49603|385745
SN|Senegal|14.497401|-14.452362|9617|1188|10805
RS|Serbia|44.016521|21.005859|14136|1420|15556
SC|Seychelles|-4.679574|55.491977|1817|73|1890
SL|Sierra Leone|8.460555|-11.779889|3000|211|3211
SG|Singapore|1.352083|103.819836|17292|5321|22613
SX|Sint Maarten|<MISSING>|<MISSING>|115|18|133
SK|Slovakia|48.669026|19.699024|16556|976|17532
SI|Slovenia|46.151241|14.995463|3671|439|4110
SB|Solomon Islands|-9.64571|160.156194|369|35|404
SO|Somalia|5.152149|46.199616|9187|500|9687
ZA|South Africa|-30.559482|22.937506|95455|16274|111729
SS|South Sudan|<MISSING>|<MISSING>|762|101|863
ES|Spain|40.463667|-3.74922|85015|9860|94875
LK|Sri Lanka|7.873054|80.771797|44211|9848|54059
SD|Sudan|12.862807|30.217636|15711|2715|18426
SR|Suriname|3.919305|-56.027783|1877|164|2041
SJ|Svalbard|77.553604|23.670272|1|0|1
SE|Sweden|60.128161|18.643501|27657|2411|30068
CH|Switzerland|46.818188|8.227512|15547|1606|17153
SY|Syria|34.802075|38.996815|28866|3792|32658
TW|Taiwan|23.69781|120.960515|28525|14123|42648
TJ|Tajikistan|38.861034|71.276093|3821|334|4155
TZ|Tanzania|-6.369028|34.888822|15006|1911|16917
TH|Thailand|15.870032|100.992541|220994|55037|276031
TL|Timor-Leste|-8.874217|125.727539|3558|395|3953
TG|Togo|8.619543|0.824782|6162|550|6712
TO|Tonga|-21.178986|-175.198242|86|17|103
TT|Trinidad and Tobago|10.691803|-61.222503|6897|956|7853
TN|Tunisia|33.886917|9.537499|18991|3458|22449
TR|Türkiye|38.963745|35.243322|198507|23184|221691
TM|Turkmenistan|38.969719|59.556278|557|34|591
TC|Turks and Caicos Islands|21.694025|-71.797928|218|9|227
TV|Tuvalu|-7.109535|177.64933|87|58|145
UG|Uganda|1.373333|32.290275|12673|912|13585
UA|Ukraine|48.379433|31.16558|271337|8586|279923
AE|United Arab Emirates|23.424076|53.847818|119623|17955|137578
UK|United Kingdom|55.378051|-3.435973|92323|80448|172771
US|United States|37.09024|-95.712891|1480183|581710|2061893
UM|United States Minor Outlying Islands|0|0|53|24|77
UY|Uruguay|-32.522779|-55.765835|10830|1546|12376
VI|US Virgin Islands|18.335765|-64.896335|197|25|222
UZ|Uzbekistan|41.377491|64.585262|16256|1093|17349
VU|Vanuatu|-15.376706|166.959158|650|138|788
VE|Venezuela|6.42375|-66.58973|65600|9327|74927
VN|Vietnam|14.058324|108.277199|411827|177031|588858
WF|Wallis and Futuna|-13.768752|-177.156097|11|0|11
EH|Western Sahara|24.215527|-12.885834|2|0|2
YE|Yemen|15.552727|48.516388|137975|11752|149727
ZM|Zambia|-13.133897|27.849332|3816|3502|7318
ZW|Zimbabwe|-19.015438|29.154857|4971|952|5923
null|Unknown|<MISSING>|<MISSING>|1571801|1759976|3331777",
  eyalet = "geo_id|bolge_adi|lat|lng|yonlendirme|bilgilendirme|deger
AL|Alabama|32.7395785|-86.8434469|14358|16839|31197
AK|Alaska|63.3469818|-152.8385657|2348|465|2813
AZ|Arizona|34.2039362|-111.6063449|39016|9657|48673
AR|Arkansas|34.8955256|-92.4446262|12656|3119|15775
CA|California|37.1626642|-119.5713456|189278|49294|238572
CO|Colorado|38.9937536|-105.5087407|22409|7584|29993
CT|Connecticut|41.5798095|-72.7466313|12719|2655|15374
DC|District of Columbia|38.9042429|-77.0165243|147|0|147
DE|Delaware|38.9988742|-75.4422351|3849|2088|5937
FL|Florida|28.3942569|-82.5173706|70812|55444|126256
GA|Georgia|32.6295789|-83.4235109|63936|18185|82121
HI|Hawaii|19.8280768|-155.495055|5521|1920|7441
ID|Idaho|44.3520074|-114.5978748|6282|1380|7662
IL|Illinois|40.1028754|-89.1526108|49964|18151|68115
IN|Indiana|39.9013136|-86.2919129|28000|9755|37755
IA|Iowa|42.0700227|-93.4933492|10048|1936|11984
KS|Kansas|38.4985464|-98.3834298|10901|2423|13324
KY|Kentucky|37.5336844|-85.2929801|18168|5306|23474
LA|Louisiana|30.708319|-91.6046207|21778|14391|36169
ME|Maine|45.4109866|-68.6676348|3875|700|4575
MD|Maryland|38.9466584|-76.6744939|21160|14736|35896
MA|Massachusetts|42.1565196|-71.4895915|23589|5368|28957
MI|Michigan|44.8441783|-85.6604877|34962|17157|52119
MN|Minnesota|46.3159573|-94.1996043|21478|4114|25592
MS|Mississippi|32.6864714|-89.6561377|15405|4116|19521
MO|Missouri|38.3507508|-92.456782|27239|9136|36375
MT|Montana|47.051177|-109.6348174|3306|666|3972
NE|Nebraska|41.543305|-99.8118641|7377|2060|9437
NV|Nevada|39.3310928|-116.6151469|10860|12292|23152
NH|New Hampshire|43.672431|-71.5835011|4104|740|4844
NJ|New Jersey|40.1072744|-74.6652012|36758|8346|45104
NM|New Mexico|34.4346844|-106.131618|9943|2501|12444
NY|New York|42.9133974|-75.5962723|78191|18004|96195
NC|North Carolina|35.53971|-79.1308636|53682|16125|69807
ND|North Dakota|47.4421609|-100.4608178|2487|475|2962
OH|Ohio|40.4149297|-82.7119975|42389|21269|63658
OK|Oklahoma|35.5900815|-97.4867789|17523|4052|21575
OR|Oregon|43.9717125|-120.6229578|18627|4330|22957
PA|Pennsylvania|40.9046042|-77.8275233|36164|29775|65939
RI|Rhode Island|41.596485|-71.5264901|4795|910|5705
SC|South Carolina|33.8741776|-80.8542639|21844|5124|26968
SD|South Dakota|44.4467957|-100.2381762|2730|548|3278
TN|Tennessee|35.8584393|-86.3496332|35504|14037|49541
TX|Texas|31.4347032|-99.2818238|164699|69819|234518
UT|Utah|39.3349925|-111.6563326|11598|3081|14679
VT|Vermont|44.0589536|-72.6710173|1722|306|2028
VA|Virginia|37.5204693|-78.6670562|36791|17182|53973
WA|Washington|47.4073801|-120.5760468|18581|15803|34384
WV|West Virginia|38.6472843|-80.6182259|6259|1295|7554
WI|Wisconsin|44.6309071|-89.7093916|20688|5015|25703
WY|Wyoming|42.9738766|-107.5290542|1771|415|2186
Unknown|US - State Unknown|<MISSING>|<MISSING>|101892|51621|153513",
  kanada = "geo_id|bolge_adi|lat|lng|kentsel_oran|kirsal_oran
NL|Newfoundland and Labrador|48.9039890456705|-55.8414695103252|91|61.4
PE|Prince Edward Island|46.2736883805985|-62.6748577650689|57.6|16.6
NS|Nova Scotia|45.0881979204254|-63.0934062485344|87.6|40.4
NB|New Brunswick|46.5074946233786|-66.2150536279393|67.3|31.7
QC|Quebec|52.7475380705161|-69.4415601582241|28.2|22.6
ON|Ontario|49.4479494337619|-86.8965599160558|21.2|6.9
MB|Manitoba|54.4393393577877|-97.2915625136411|43.9|15.8
SK|Saskatchewan|52.5253119980843|-105.920067942199|10.8|9.5
AB|Alberta|54.5085055112114|-114.927974617532|45.3|18.2
BC|British Columbia|55.1659798662013|-124.566333906198|145.4|103.7"
)
# Gömülü resmî kaynak tablolarının sonu.

olustur_adli_veri <- function() {
  oku <- function(x) utils::read.table(
    text = x, sep = "|", header = TRUE, quote = "", comment.char = "",
    stringsAsFactors = FALSE, na.strings = "<MISSING>", check.names = FALSE
  )
  ulke <- oku(.adli_resmi_tablolar$ulke)
  eyalet <- oku(.adli_resmi_tablolar$eyalet)
  kanada <- oku(.adli_resmi_tablolar$kanada)
  sabitle <- function(d, kaynak_id, grup, yil, ulke_kodu, ulke_adi,
                      kaynak_adi, kaynak_url, koordinat_url, not_metni) {
    d$kayit_id <- paste(kaynak_id, d$geo_id, sep = "_")
    d$ulke_id <- if (is.null(ulke_kodu)) d$geo_id else ulke_kodu
    d$ulke_adi <- if (is.null(ulke_adi)) d$bolge_adi else ulke_adi
    d$konum_duzeyi <- if (kaynak_id == "NCMEC_ULKE_2025") "Ülke / bölge" else "Eyalet"
    d$veri_turu <- "Resmi_istatistik"
    d$gosterge_id <- kaynak_id
    d$katman <- grup
    d$donem <- as.integer(yil)
    d$kaynak_adi <- kaynak_adi
    d$kaynak_url <- kaynak_url
    d$koordinat_kaynagi <- koordinat_url
    d$kaynak_goruntusu <- "2026-10-28"
    d$sinirlilik <- not_metni
    if (!"deger" %in% names(d)) d$deger <- NA_real_
    if (!"yonlendirme" %in% names(d)) d$yonlendirme <- NA_real_
    if (!"bilgilendirme" %in% names(d)) d$bilgilendirme <- NA_real_
    if (!"kentsel_oran" %in% names(d)) d$kentsel_oran <- NA_real_
    if (!"kirsal_oran" %in% names(d)) d$kirsal_oran <- NA_real_
    d$birim <- if (kaynak_id == "STATCAN_KANADA_2024")
      "100.000 toplam nüfus başına polis kaydı; kent / kır ayrı" else
        "CyberTipline raporu; yönlendirme + bilgilendirme"
    
    d$bildirim_hacmi_bin <- NA_real_
    d$iwf_barindirma_skor <- NA_character_
    d$inhope_kapasite <- NA_character_
    d$bilesik_risk_skoru <- NA_real_
    d$risk_kategorisi <- NA_character_
    d$trend_2019_2026 <- NA_character_
    d$harita_durumu <- ifelse(
      is.finite(d$lat) & is.finite(d$lng), "Gösteriliyor",
      ifelse(d$geo_id == "EP", "Coğrafi bölge değil; haritada gösterilmez",
             ifelse(d$geo_id %in% c("null", "Unknown"),
                    "Coğrafya bilinmiyor; haritada gösterilmez",
                    "Koordinat eşleşmedi; haritada gösterilmez"))
    )
    d
  }
  ncmec_not <- paste(
    "Rapor sayısı doğrulanmış suç, mağdur, indirme veya CSAM'a özgü olay sayısı değildir.",
    "CSAM yanında çevrimiçi çocuğa yaklaşma ve çocuk seks ticareti bildirimlerini içerir.",
    "Bir rapor birden fazla yetkiliye/ülkeye sunulabilir; ülke ve eyaletler toplanamaz.",
    "IP/proxy göstergeleri gerçek olay yerini kesinleştirmez."
  )
  ulke <- sabitle(
    ulke, "NCMEC_ULKE_2025", "RESMÎ | NCMEC ülke / bölge 2025", 2025, NULL, NULL,
    "NCMEC | 2025 CyberTipline Reports by Country",
    "https://www.missingkids.org/content/dam/missingkids/pdfs/2025-reports-by-country.pdf",
    "https://developers.google.com/public-data/docs/canonical/countries_csv", ncmec_not
  )
  # Europol kaynak PDF'de yer alır, ancak ülke değildir ve haritalanmaz.
  ulke$konum_duzeyi[ulke$geo_id == "EP"] <- "Bölge dışı yetkili (Europol)"
  eyalet <- sabitle(
    eyalet, "NCMEC_ABD_2025", "RESMÎ | ABD eyaletleri + DC 2025", 2025, "US",
    "Amerika Birleşik Devletleri", "NCMEC | 2025 CyberTipline Reports by State",
    "https://www.missingkids.org/content/dam/missingkids/pdfs/2025-reports-by-state.pdf",
    paste0("https://tigerweb.geo.census.gov/arcgis/rest/services/",
           "TIGERweb/State_County/MapServer/0"), ncmec_not
  )
  kanada <- sabitle(
    kanada, "STATCAN_KANADA_2024", "RESMÎ | Kanada eyalet oranları 2024", 2024, "CA",
    "Kanada", "Statistics Canada | Tables 6 (rural) and 7 (urban), 2024",
    "https://www150.statcan.gc.ca/n1/pub/85-002-x/2026001/article/00007/tbl/tbl06-eng.htm",
    "https://geo.statcan.gc.ca/geo_wa/rest/services/2021/Cartographic_boundary_files/MapServer/0",
    paste(
      "CSAM kapsamındaki polis kayıt oranı; doğrulanmış mağdur veya trafik yoğunluğu değildir.",
      "Kent/kır, polis hizmetinin kapsadığı nüfusa göre tanımlanır.",
      "100.000 toplam nüfus başına iki ayrı oran; ortalaması veya toplamı eyalet oranı değildir.",
      "RCMP'nin ilgili ulusal merkezi, BC Integrated Child Exploitation Unit ve askerî polis hariç.",
      "Soruşturma ve kayıt uygulamaları karşılaştırmayı etkiler. Üç kuzey bölgesi kapsam dışıdır.",
      "Temsili nokta açık coğrafi poligondan türetilmiştir; olay yeri değildir."
    )
  )
  ulke$ikinci_kaynak_url <- NA_character_
  eyalet$ikinci_kaynak_url <- NA_character_
  kanada$ikinci_kaynak_url <-
    "https://www150.statcan.gc.ca/n1/pub/85-002-x/2026001/article/00007/tbl/tbl07-eng.htm"
  # Yalnızca resmî kaynak kayıtları birleştirilir. Sentetik kayıtlar burada yoktur.
  d <- rbind(ulke, eyalet[, names(ulke)], kanada[, names(ulke)])
  rownames(d) <- NULL
  eski_sutunlar <- c(
    "ulke_id", "ulke_adi", "lat", "lng", "bildirim_hacmi_bin",
    "iwf_barindirma_skor", "inhope_kapasite", "bilesik_risk_skoru",
    "risk_kategorisi", "trend_2019_2026"
  )
  d[, c(eski_sutunlar, setdiff(names(d), eski_sutunlar))]
}

# IWF ana veri tablosu: veri soyutlama katmanının devamı.
olustur_csam_veri <- function() {
  # Doğrudan yayın tablosu; yüzdeler yerine adetler aktarılmıştır.
  # UK için küresel tabloda 950, aynı sayfanın UK metninde 951 vardır.
  # Küresel tablo aynen korunur; fark metadata/kartta gösterilir.
  d <- utils::read.table(
    text = "geo_id|bolge_adi|url_sayisi
BG|Bulgaria|87959
US|United States|49021
NL|Netherlands|33788
RO|Romania|21188
FR|France|20475
DE|Germany|18401
MY|Malaysia|17046
MD|Moldova|9941
IS|Iceland|7455
SE|Sweden|6820
RU|Russian Federation|5797
PA|Panama|5275
IR|Iran|5083
UA|Ukraine|4987
VN|Vietnam|3344
LT|Lithuania|1985
HK|Hong Kong|1959
FI|Finland|1414
PL|Poland|1216
SK|Slovak Republic|1029
IN|India|982
GB|United Kingdom|950
ONION|Onion URL (Dark web)|705
EE|Estonia|596
LV|Latvia|518
AZ|Azerbaijan|446
LU|Luxembourg|370
SG|Singapore|266
JP|Japan|219
CZ|Czech Republic|215
ID|Indonesia|198
CH|Switzerland|119
KR|Korea (South)|94
RS|Serbia|64
CA|Canada|40
IT|Italy|39
AE|United Arab Emirates|37
IQ|Iraq|36
LA|Laos|34
ZA|South Africa|30
SC|Seychelles|30
AT|Austria|27
BA|Bosnia-Herzegovina|26
ES|Spain|25
NO|Norway|22
AL|Albania|22
BR|Brazil|19
HU|Hungary|16
TH|Thailand|13
AU|Australia|13
CN|China|11
KH|Cambodia|11
HR|Croatia|10
MU|Mauritius|8
DK|Denmark|7
BZ|Belize|7
IL|Israel|5
BD|Bangladesh|5
AM|Armenia|4
TR|Turkey|3
MX|Mexico|2
CL|Chile|2
UY|Uruguay|1
TW|Taiwan|1
SI|Slovenia|1
NG|Nigeria|1
ME|Montenegro|1
KZ|Kazakhstan|1
IE|Ireland|1
CY|Cyprus|1",
    sep = "|", header = TRUE, quote = "", comment.char = "",
    stringsAsFactors = FALSE
  )
  # Coğrafi referans yalnızca koordinat içindir; NCMEC sayıları alınmaz.
  referans <- utils::read.table(
    text = .adli_resmi_tablolar$ulke, sep = "|", header = TRUE,
    quote = "", comment.char = "", na.strings = "<MISSING>",
    stringsAsFactors = FALSE
  )
  # Eski referans tablosu Birleşik Krallık için "UK" kullanır.
  # IWF tablosundaki GB anahtarını değiştirmeden yalnızca eşleştirme yapılır.
  eslesme_kodu <- ifelse(d$geo_id == "GB", "UK", d$geo_id)
  idx <- match(eslesme_kodu, referans$geo_id)
  d$lat <- referans$lat[idx]
  d$lng <- referans$lng[idx]
  d$kayit_id <- paste0("IWF_2025_", d$geo_id)
  d$donem <- 2025L
  d$kaynak_adi <- "IWF | 2025 Global hosting by country"
  d$kaynak_url <- paste0(
    "https://www.iwf.org.uk/annual-data-insights-report-2025/",
    "online-hosting/geographic-insights"
  )
  d$kaynak_goruntusu <- "2026-10-28"
  d$koordinat_kaynagi <-
    "https://developers.google.com/public-data/docs/canonical/countries_csv"
  d$birim <- "CSAM gösteren veya CSAM'a yönlendiren URL adedi"
  d$veri_turu <- "Yayinlanmis_CSam_istatistigi"
  d$kaynak_toplami <- 310437
  d$toplamdaki_pay_yuzde <- d$url_sayisi / d$kaynak_toplami * 100
  d$yogunluk_sinifi <- as.character(cut(
    d$url_sayisi, c(-Inf, 10, 100, 1000, 10000, Inf),
    right = FALSE,
    labels = c("1–9 URL", "10–99 URL", "100–999 URL",
               "1.000–9.999 URL", "10.000 ve üzeri URL")
  ))
  d$kaynak_tutarlilik_notu <- paste(
    "Kaynak küresel tablosu aynen aktarılmıştır.",
    "UK: küresel tabloda 950, aynı sayfanın UK metninde 951 URL.",
    "Satır toplamı ile yayımlanan toplam farklıysa değerler otomatik düzeltilmez."
  )
  d$harita_durumu <- ifelse(
    d$geo_id == "ONION", "Ülkeye atanamaz; haritada gösterilmez",
    ifelse(is.finite(d$lat) & is.finite(d$lng), "Gösteriliyor",
           "Koordinat eşleşmedi; haritada gösterilmez")
  )
  d
}

# CHAPTER 4.2: Gerçek geçmiş yıl göstergeleri ve regresyon ağacı.
# Kaynaktaki "-" veya listede bulunmama, SIFIR kabul edilmez.
olustur_model_verisi <- function(csam_veri) {
  gecmis <- utils::read.table(
    text = "geo_id|url_2024|domain_2024
NL|83037|954
US|41110|1914
BG|25180|102
HK|24063|311
RO|21528|74
MY|15902|52
LT|8484|24
PL|8077|46
CZ|7859|42
LV|7540|59
MD|7513|61
UA|7223|124
RU|6487|1492
AT|6144|30
DE|4448|164
SK|3422|1
PA|2095|72
FR|2091|171
SE|1552|42
CH|1117|29
FI|1027|35
GB|987|71
ONION|531|533
AZ|496|8
LU|486|10
VN|461|69
JP|385|160
SG|328|57
ID|235|13
KR|137|78
AE|91|14
IN|80|50
NO|80|22
IT|70|16
CA|69|29
EE|65|47
ES|36|32
BE|30|25
BR|29|9
HU|27|15
TR|26|10
AU|15|6
MU|13|8
CN|12|6
BY|11|2
ZA|6|6
PE|5|5
AL|3|3
DK|3|3
KZ|3|2
PT|3|3
BD|2|1
CY|2|2
IS|2|2
SC|2|2
TW|2|1
BA|1|1
CR|1|1
IE|1|1
MX|1|1
ME|1|1
VU|1|1
UY|NA|1
AI|NA|NA
KH|NA|NA
GE|NA|NA
IR|NA|NA
IL|NA|NA
TH|NA|NA",
    sep = "|", header = TRUE, quote = "", comment.char = "",
    na.strings = "NA", stringsAsFactors = FALSE
  )
  if (anyDuplicated(gecmis$geo_id) || anyDuplicated(csam_veri$geo_id))
    stop("Model kaynaklarında ülke anahtarları benzersiz olmalıdır.")
  hedef <- csam_veri[, c("geo_id", "bolge_adi", "lat", "lng", "url_sayisi")]
  names(hedef)[names(hedef) == "url_sayisi"] <- "url_2025"
  tum <- merge(hedef, gecmis, by = "geo_id", all = TRUE, sort = TRUE)
  # Kaynak anahtarları sayısal modele asla girmez.
  tum$bolge_adi[is.na(tum$bolge_adi)] <-
    tum$geo_id[is.na(tum$bolge_adi)]
  tum$kaynak_2024_url <- paste0(
    "https://www.iwf.org.uk/annual-data-insights-report-2024/",
    "data-and-insights/geographical-hosting-urls/"
  )
  tum$kaynak_2024_domain <- paste0(
    "https://www.iwf.org.uk/annual-data-insights-report-2024/",
    "data-and-insights/geographical-hosting-domains"
  )
  tum$kaynak_2025_url <- paste0(
    "https://www.iwf.org.uk/annual-data-insights-report-2025/",
    "online-hosting/geographic-insights"
  )
  tum$kaynak_erisim_tarihi <- "2026-10-28"
  alanlar <- c("url_2024", "domain_2024", "url_2025")
  for (ad in alanlar) {
    x <- tum[[ad]]
    if (!is.numeric(x) ||
        any(!is.finite(x[!is.na(x)])) ||
        any(x[!is.na(x)] < 0 | x[!is.na(x)] %% 1 != 0))
      stop("Geçersiz model sayımı: ", ad)
  }
  tum$dislama_nedeni <- vapply(seq_len(nrow(tum)), function(i) {
    if (tum$geo_id[i] == "ONION") return("Ülkeye atanamayan kategori")
    eksik <- alanlar[is.na(tum[i, alanlar])]
    if (length(eksik)) paste("Kaynakta ölçüm eksik:", paste(eksik, collapse = ", "))
    else ""
  }, character(1))
  uygun <- tum$dislama_nedeni == ""
  d <- tum[uygun, , drop = FALSE]
  rownames(d) <- NULL
  if (nrow(d) < 25L) stop("Karar ağacı örneği için yeterli tam kayıt yok.")
  list(
    veri = d, dislanan = tum[!uygun, , drop = FALSE],
    tum_kayitlar = tum, gecmis_ham = gecmis
  )
}

egit_karar_agaci <- function(model_verisi, tohum = 1234L) {
  d <- model_verisi$veri
  # Hedefin 1..87959 gibi geniş aralığı nedeniyle önceden belirlenmiş log dönüşümü.
  # Bu bir sınıflandırma değil, sayısal hedefli regresyon ağacıdır (Chapter 4.2).
  set.seed(tohum)
  n_egitim <- floor(.70 * nrow(d))
  egitim_idx <- sort(sample.int(nrow(d), size = n_egitim))
  d$veri_bolumu <- ifelse(seq_len(nrow(d)) %in% egitim_idx, "Egitim", "Test")
  egitim <- d[d$veri_bolumu == "Egitim", , drop = FALSE]
  test <- d[d$veri_bolumu == "Test", , drop = FALSE]
  if (length(intersect(egitim$geo_id, test$geo_id)))
    stop("Eğitim/test ülke sızıntısı tespit edildi.")
  egitim$log_url_2025 <- log1p(egitim$url_2025)
  # 2025 payı, kategorisi, koordinat ve ülke adı/kodu formüle EKLENMEZ.
  myFormula <- log_url_2025 ~ url_2024 + domain_2024
  set.seed(tohum + 1L)
  ilk_agac <- rpart::rpart(
    myFormula, data = egitim, method = "anova", model = TRUE,
    control = rpart::rpart.control(
      minsplit = 8L, minbucket = 3L, maxdepth = 4L,
      cp = .0001, xval = 5L
    )
  )
  # Chapter 4.2'deki seçim: eğitim içi CV hatası en düşük CP, ardından prune().
  cp_tablosu <- as.data.frame(ilk_agac$cptable)
  opt <- which.min(cp_tablosu$xerror)
  cp <- cp_tablosu$CP[opt]
  budanmis_agac <- rpart::prune(ilk_agac, cp = cp)
  # Test ülkeleri CP seçildikten SONRA tahmin edilir; sonradan parametre ayarlanmaz.
  d$tahmin_log <- as.numeric(stats::predict(budanmis_agac, newdata = d))
  d$tahmin_url_2025 <- pmax(0, expm1(d$tahmin_log))
  d$gozlenen_url_2025 <- d$url_2025
  d$hata_url <- d$tahmin_url_2025 - d$url_2025
  d$mutlak_hata_url <- abs(d$hata_url)
  d$baseline_onceki_yil <- d$url_2024
  d$baseline_egitim_ortalamasi <- mean(egitim$url_2025)
  # Üstel ters dönüşüm log-ölçekli tahmindir; aritmetik koşullu ortalama iddiası yoktur.
  degerlendir <- function(gercek, tahmin, ad) {
    payda <- sum((gercek - mean(gercek))^2)
    data.frame(
      model = ad, n_test = length(gercek),
      MAE = mean(abs(tahmin - gercek)),
      RMSE = sqrt(mean((tahmin - gercek)^2)),
      RMSLE = sqrt(mean((log1p(tahmin) - log1p(gercek))^2)),
      R2 = if (payda > 0) 1 - sum((tahmin - gercek)^2) / payda else NA_real_,
      stringsAsFactors = FALSE
    )
  }
  test_tahminleri <- d[d$veri_bolumu == "Test", , drop = FALSE]
  metrikler <- rbind(
    degerlendir(test_tahminleri$url_2025, test_tahminleri$tahmin_url_2025,
               "rpart karar agaci"),
    degerlendir(test_tahminleri$url_2025, test_tahminleri$baseline_onceki_yil,
               "Onceki yil ayni kalir"),
    degerlendir(test_tahminleri$url_2025, test_tahminleri$baseline_egitim_ortalamasi,
               "Egitim ortalamasi")
  )
  onem <- budanmis_agac$variable.importance
  degisken_onemi <- data.frame(
    degisken = c("url_2024", "domain_2024"), onem = 0, stringsAsFactors = FALSE
  )
  if (length(onem)) {
    idx <- match(names(onem), degisken_onemi$degisken)
    degisken_onemi$onem[idx] <- unname(onem)
  }
  list(
    model = budanmis_agac, ilk_model = ilk_agac, formulu = myFormula,
    cp_tablosu = cp_tablosu, secilen_cp = cp, tohum = tohum,
    egitim = egitim, test = test, tahminler = d,
    test_tahminleri = test_tahminleri, metrikler = metrikler,
    degisken_onemi = degisken_onemi, dislanan = model_verisi$dislanan
  )
}

# ==============================================================================
# 2. GÖRSELLEŞTİRME KATMANI
# ==============================================================================
ciz_kurumsal_adli_harita <- function(veri_seti, csam_veri = NULL,
                                   model_sonucu = NULL) {
  gerekli_sutunlar <- c(
    "ulke_id", "ulke_adi", "lat", "lng", "bolge_adi", "konum_duzeyi",
    "kayit_id", "veri_turu", "gosterge_id", "katman", "donem", "deger",
    "yonlendirme", "bilgilendirme", "kentsel_oran", "kirsal_oran",
    "birim", "kaynak_adi", "kaynak_url", "ikinci_kaynak_url",
    "koordinat_kaynagi", "kaynak_goruntusu", "sinirlilik", "harita_durumu"
  )
  if (!is.data.frame(veri_seti)) stop("Girdi data.frame olmalıdır.")
  if (anyDuplicated(names(veri_seti))) stop("Yinelenen sütun adları var.")
  eksik <- setdiff(gerekli_sutunlar, names(veri_seti))
  if (length(eksik)) stop("Eksik sütunlar: ", paste(eksik, collapse = ", "))
  if (!nrow(veri_seti)) stop("Veri seti boş.")
  
  sinir_kontrol <- function(x, alt, ust, ad) {
    if (!is.numeric(x) || any(!is.finite(x)) || any(x < alt | x > ust))
      stop(ad, " sayısal, sonlu ve [", alt, ", ", ust, "] aralığında olmalıdır.")
  }
  if (!is.numeric(veri_seti$lat) || !is.numeric(veri_seti$lng))
    stop("Koordinatlar sayısal olmalıdır.")
  if (any(xor(is.na(veri_seti$lat), is.na(veri_seti$lng))))
    stop("Eksik koordinat çifti: enlem ve boylam birlikte NA olmalıdır.")
  if (any(is.nan(veri_seti$lat)) || any(is.nan(veri_seti$lng)))
    stop("NaN koordinat kabul edilmez.")
  haritada <- !is.na(veri_seti$lat) & !is.na(veri_seti$lng)
  sinir_kontrol(veri_seti$lat[haritada], -85.0511, 85.0511, "Enlem")
  sinir_kontrol(veri_seti$lng[haritada], -180, 180, "Boylam")
  if (any(veri_seti$harita_durumu[haritada] != "Gösteriliyor") ||
      any(veri_seti$harita_durumu[!haritada] == "Gösteriliyor"))
    stop("Koordinatlar ile harita_durumu tutarsız.")
  metin_sutunlari <- c(
    "ulke_id", "ulke_adi", "bolge_adi", "konum_duzeyi", "kayit_id",
    "veri_turu", "gosterge_id", "katman", "birim", "kaynak_adi",
    "kaynak_url", "koordinat_kaynagi", "kaynak_goruntusu", "sinirlilik"
  )
  for (ad in metin_sutunlari) {
    x <- as.character(veri_seti[[ad]])
    if (anyNA(x) || any(!nzchar(trimws(x))))
      stop("Boş veya NA metin: ", ad)
    veri_seti[[ad]] <- x
  }
  if (anyDuplicated(veri_seti$kayit_id)) stop("kayit_id benzersiz olmalıdır.")
  if (any(veri_seti$veri_turu != "Resmi_istatistik"))
    stop("Ana veri setine sentetik/doğrulanmamış kayıt eklenemez.")
  kaynaklar <- c(
    NCMEC_ULKE_2025 =
      "https://www.missingkids.org/content/dam/missingkids/pdfs/2025-reports-by-country.pdf",
    NCMEC_ABD_2025 =
      "https://www.missingkids.org/content/dam/missingkids/pdfs/2025-reports-by-state.pdf",
    STATCAN_KANADA_2024 =
      "https://www150.statcan.gc.ca/n1/pub/85-002-x/2026001/article/00007/tbl/tbl06-eng.htm"
  )
  if (any(!veri_seti$gosterge_id %in% names(kaynaklar)) ||
      any(veri_seti$kaynak_url != unname(kaynaklar[veri_seti$gosterge_id])))
    stop("Gösterge/kaynak eşleşmesi geçersiz.")
  ca <- veri_seti$gosterge_id == "STATCAN_KANADA_2024"
  sinir_kontrol(veri_seti$donem, 2000, 2100, "Dönem")
  if (any(veri_seti$donem != ifelse(ca, 2024L, 2025L)))
    stop("Gösterge/dönem eşleşmesi geçersiz.")
  beklenen_katman <- c(
    NCMEC_ULKE_2025 = "RESMÎ | NCMEC ülke / bölge 2025",
    NCMEC_ABD_2025 = "RESMÎ | ABD eyaletleri + DC 2025",
    STATCAN_KANADA_2024 = "RESMÎ | Kanada eyalet oranları 2024"
  )
  if (any(veri_seti$katman != unname(beklenen_katman[veri_seti$gosterge_id])))
    stop("Gösterge/katman eşleşmesi geçersiz.")
  beklenen_birim <- ifelse(
    ca, "100.000 toplam nüfus başına polis kaydı; kent / kır ayrı",
    "CyberTipline raporu; yönlendirme + bilgilendirme"
  )
  if (any(veri_seti$birim != beklenen_birim)) stop("Gösterge/birim eşleşmesi geçersiz.")
  for (ad in c("deger", "yonlendirme", "bilgilendirme")) {
    sinir_kontrol(veri_seti[[ad]][!ca], 0, Inf, ad)
    if (any(veri_seti[[ad]][!ca] %% 1 != 0))
      stop("NCMEC rapor alanları tam sayı olmalıdır: ", ad)
    if (any(!is.na(veri_seti[[ad]][ca])))
      stop("Kanada oranları rapor adedi alanına yazılamaz: ", ad)
  }
  if (any(veri_seti$deger[!ca] !=
          veri_seti$yonlendirme[!ca] + veri_seti$bilgilendirme[!ca]))
    stop("NCMEC toplamı yönlendirme + bilgilendirme toplamıyla uyuşmuyor.")
  if (any(veri_seti$deger[!ca] %% 1 != 0))
    stop("NCMEC rapor sayısı tam sayı olmalıdır.")
  for (ad in c("kentsel_oran", "kirsal_oran"))
    sinir_kontrol(veri_seti[[ad]][ca], 0, Inf, ad)
  if (any(!is.na(veri_seti$deger[ca])) ||
      any(!is.na(veri_seti$kentsel_oran[!ca])) ||
      any(!is.na(veri_seti$kirsal_oran[!ca])))
    stop("Farklı birimlerdeki göstergeler tek değere dönüştürülemez.")
  if (anyNA(veri_seti$ikinci_kaynak_url[ca]) ||
      any(veri_seti$ikinci_kaynak_url[ca] !=
          "https://www150.statcan.gc.ca/n1/pub/85-002-x/2026001/article/00007/tbl/tbl07-eng.htm"))
    stop("Kanada kentsel oranı için Tablo 7 kaynağı zorunludur.")
  for (ad in intersect(c("bilesik_risk_skoru", "bildirim_hacmi_bin",
                         "iwf_barindirma_skor", "inhope_kapasite",
                         "risk_kategorisi", "trend_2019_2026"), names(veri_seti))) {
    if (any(!is.na(veri_seti[[ad]])))
      stop("Resmî kayıtlarda kaynaksız/eski örnek alanı doldurulamaz: ", ad)
  }
  # Koordinatı bulunmayan kayıtlar CSV'de kalır; (0,0)'a taşınmaz ve sıfırlanmaz.
  toplam_resmi <- nrow(veri_seti)
  haritalanamayan <- veri_seti[!haritada, , drop = FALSE]
  veri_seti <- veri_seti[haritada, , drop = FALSE]
  if (!nrow(veri_seti)) stop("Haritada gösterilebilen resmî kayıt yok.")
  if (!is.null(csam_veri)) {
    csam_gerekli <- c(
      "lat", "lng", "bolge_adi", "kayit_id", "geo_id", "donem",
      "url_sayisi", "toplamdaki_pay_yuzde", "yogunluk_sinifi",
      "kaynak_url", "kaynak_goruntusu", "koordinat_kaynagi",
      "kaynak_toplami", "kaynak_tutarlilik_notu", "harita_durumu", "veri_turu"
    )
    if (!is.data.frame(csam_veri) || anyDuplicated(names(csam_veri)) ||
        length(setdiff(csam_gerekli, names(csam_veri))))
      stop("CSAM veri şeması geçersiz.")
    sinir_kontrol(csam_veri$url_sayisi, 1, Inf, "CSAM URL sayısı")
    if (any(csam_veri$url_sayisi %% 1 != 0))
      stop("URL sayısı tam sayı olmalıdır.")
    if (anyNA(csam_veri$kayit_id) || anyDuplicated(csam_veri$kayit_id))
      stop("CSAM kayıt kimlikleri benzersiz olmalıdır.")
    if (anyNA(csam_veri$veri_turu) ||
        any(csam_veri$veri_turu != "Yayinlanmis_CSam_istatistigi"))
      stop("CSAM ana katmanına yapay veri eklenemez.")
    if (anyNA(csam_veri$kaynak_url) ||
        any(csam_veri$kaynak_url != paste0(
          "https://www.iwf.org.uk/annual-data-insights-report-2025/",
          "online-hosting/geographic-insights"
        ))) stop("IWF kaynak eşleşmesi geçersiz.")
    if (anyNA(csam_veri$donem) || any(csam_veri$donem != 2025L) ||
        anyNA(csam_veri$kaynak_toplami) ||
        any(csam_veri$kaynak_toplami != 310437))
      stop("IWF dönem/toplam bilgisi geçersiz.")
    oran <- csam_veri$url_sayisi / csam_veri$kaynak_toplami * 100
    if (anyNA(csam_veri$toplamdaki_pay_yuzde) ||
        any(abs(oran - csam_veri$toplamdaki_pay_yuzde) > 1e-8))
      stop("IWF pay hesabı uyuşmuyor.")
    uygun <- csam_veri$harita_durumu == "Gösteriliyor"
    if (anyNA(uygun)) stop("CSAM harita durumu boş olamaz.")
    sinir_kontrol(csam_veri$lat[uygun], -85.0511, 85.0511, "CSAM enlem")
    sinir_kontrol(csam_veri$lng[uygun], -180, 180, "CSAM boylam")
    csam_harita_disi <- csam_veri[!uygun, , drop = FALSE]
    csam_veri <- csam_veri[uygun, , drop = FALSE]
  }
  
  guvenli_metin <- function(x)
    as.character(htmltools::htmlEscape(as.character(x)))
  
  kare_ikonu_yap <- function(renk, dolgu_opakligi = .25) {
    kare_svg <- paste0(
      '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12">',
      '<rect x="1" y="1" width="10" height="10" fill="#080a0d" fill-opacity=".8" stroke="#000"/>',
      '<rect x="3" y="3" width="6" height="6" fill="', renk,
      '" fill-opacity="', dolgu_opakligi, '" ',
      'stroke="', renk, '" stroke-width="1.2"/></svg>'
    )
    makeIcon(
      iconUrl = paste0("data:image/svg+xml;charset=UTF-8,",
                       utils::URLencode(kare_svg, reserved = TRUE)),
      iconWidth = 12, iconHeight = 12, iconAnchorX = 6, iconAnchorY = 6,
      popupAnchorX = 0, popupAnchorY = -7
    )
  }
  satir <- function(baslik, deger) paste0(
    "<div class='adli-popup-satir'><span>", guvenli_metin(baslik),
    "</span><strong>", guvenli_metin(deger), "</strong></div>"
  )
  sayi <- function(x, basamak = 0) format(
    round(x, basamak), big.mark = ".", decimal.mark = ",",
    scientific = FALSE, trim = TRUE, nsmall = basamak
  )
  kaynak_baglantisi <- function(url, ad) paste0(
    "<a href='", guvenli_metin(url), "' target='_blank' rel='noopener noreferrer'>",
    guvenli_metin(ad), "</a>"
  )
  popup_icerigi <- vapply(seq_len(nrow(veri_seti)), function(i) {
    d <- veri_seti[i, , drop = FALSE]
    ca <- d$gosterge_id == "STATCAN_KANADA_2024"
    paste0(
      "<div class='adli-popup'>",
      "<div class='adli-popup-baslik'>EK KAYNAK İSTATİSTİĞİ</div>",
      "<div class='adli-popup-uyari'>ANA CSAM BARINDIRMA ÖLÇÜSÜNDEN AYRIDIR</div>",
      satir("Bölge", d$bolge_adi), satir("Yıl / coğrafi düzey",
                                         paste(d$donem, d$konum_duzeyi, sep = " / ")),
      if (ca) paste0(
        satir("Kent: 100.000 kişide CSAM polis kaydı", sayi(d$kentsel_oran, 1)),
        satir("Kır: 100.000 kişide CSAM polis kaydı", sayi(d$kirsal_oran, 1))
      ) else paste0(
        satir("CyberTipline bildirim sayısı (yalnız CSAM değil)", sayi(d$deger)),
        satir("Yönlendirme (referrals)", sayi(d$yonlendirme)),
        satir("Bilgilendirme (informational)", sayi(d$bilgilendirme))
      ),
      "<details><summary>Kaynak ve yöntem</summary>",
      satir("Sayılan birim", d$birim),
      "<div class='adli-popup-not'>",
      kaynak_baglantisi(d$kaynak_url, if (ca) "Statistics Canada / kırsal tablo 6" else d$kaynak_adi),
      if (ca) paste0("<br>", kaynak_baglantisi(d$ikinci_kaynak_url, "Statistics Canada / kentsel tablo 7")) else "",
      "<br>", kaynak_baglantisi(d$koordinat_kaynagi, "Temsili konumun coğrafi kaynağı"),
      "<br>Dosyadaki kaynak tarihi: ", guvenli_metin(d$kaynak_goruntusu), "</div>",
      "<div class='adli-popup-not'>", guvenli_metin(d$sinirlilik),
      " Nokta; olay, sunucu, kullanıcı veya indirme konumu değildir.</div></details></div>"
    )
  }, character(1))
  kisa_etiket <- lapply(seq_len(nrow(veri_seti)), function(i) {
    htmltools::HTML(paste0(
      guvenli_metin(veri_seti$bolge_adi[i]),
      " | ", veri_seti$donem[i], " | ",
      if (veri_seti$gosterge_id[i] == "STATCAN_KANADA_2024")
        paste0("Kent: ", sayi(veri_seti$kentsel_oran[i], 1), "; kır: ",
               sayi(veri_seti$kirsal_oran[i], 1), " / 100.000 toplam nüfus") else
                 paste0(sayi(veri_seti$deger[i]), " CyberTipline raporu"),
      " | Temsili konum"
    ))
  })
  
  stil <- htmltools::tags$style(htmltools::HTML("
    .adli-harita {background:#111820;font-family:'Segoe UI',Arial,sans-serif;}
    .adli-harita .leaflet-control-layers,.adli-harita .adli-panel {
      background:rgba(12,17,23,.94);color:#e7edf3;border:1px solid #47525f;
      border-radius:3px;box-shadow:0 3px 14px rgba(0,0,0,.45);}
    .adli-harita .leaflet-control-layers {padding:9px 12px;font-size:12px;max-width:220px;}
    .adli-harita .adli-panel {font-size:11px;line-height:1.5;max-width:300px;}
    .adli-harita .adli-panel summary {cursor:pointer;padding:8px 12px;font-weight:700;}
    .adli-harita .adli-panel summary:focus-visible {outline:2px solid #a8d4ff;}
    .adli-harita .adli-panel[open] summary {border-bottom:1px solid #47525f;}
    .adli-harita .adli-panel summary .adli-kapat {display:none;margin-left:14px;color:#ffc26e;}
    .adli-harita .adli-panel[open] summary .adli-kapat {display:inline;}
    .adli-harita .adli-panel-icerik {padding:10px 12px;
      max-height:min(230px,calc(100vh - 260px));overflow:auto;}
    .adli-harita .adli-panel-baslik {color:#fff;font-size:12px;font-weight:700;
      letter-spacing:1px;border-bottom:1px solid #58626c;padding-bottom:7px;margin-bottom:7px;}
    .adli-harita .adli-uyari {color:#ffc26e;margin-top:7px;}
    .adli-harita .adli-kare-ornek {display:inline-block;width:8px;height:8px;
      box-sizing:border-box;background:rgba(255,43,34,.25);border:1px solid #ff372d;
      outline:1px solid #000;margin-right:8px;}
    .adli-harita .adli-damga {background:rgba(12,17,23,.90);color:#ffc26e;
      border:1px solid #47525f;padding:4px 7px;font-size:10px;max-width:220px;}
    .adli-harita .adli-tile-uyari[hidden] {display:none;}
    .adli-harita .adli-tile-uyari {margin-top:7px;color:#ffc26e;max-width:220px;}
    .adli-harita .leaflet-popup-content-wrapper,.adli-harita .leaflet-popup-tip {
      background:#111820;color:#e7edf3;}
    .adli-harita .leaflet-popup-content {margin:14px;line-height:1.5;}
    .adli-harita .leaflet-popup-close-button {color:#fff;}
    .adli-harita .adli-popup {font-family:'Segoe UI',Arial,sans-serif;overflow-wrap:anywhere;}
    .adli-harita .adli-popup-baslik {color:#fff;font-weight:700;letter-spacing:.7px;
      border-bottom:2px solid #ef3d32;padding-bottom:8px;}
    .adli-harita .adli-popup-uyari {color:#ffc26e;font-size:10px;margin:8px 0 12px;}
    .adli-harita .adli-popup-satir {padding:5px 0;border-bottom:1px solid #2b3541;}
    .adli-harita .adli-popup-satir span {display:block;color:#aab7c5;font-size:10px;}
    .adli-harita .adli-popup-satir strong {color:#f0f4f8;font-size:12px;}
    .adli-harita .adli-popup-skor {background:#391d20;border-left:3px solid #ff493e;
      padding:9px;margin-top:12px;font-weight:700;}
    .adli-harita .adli-popup-skor small {display:block;font-weight:400;color:#e9b7b2;}
    .adli-harita .adli-popup-not {color:#aab7c5;font-size:10px;margin-top:10px;}
    .adli-harita .leaflet-control-scale-line {background:rgba(12,17,23,.85);
      color:#fff;border-color:#c5cfd9;text-shadow:none;}
    .adli-harita .leaflet-control-attribution {background:rgba(12,17,23,.88);color:#d8e0e8;}
    .adli-harita .leaflet-control-attribution a,.adli-harita .adli-panel a {color:#a8d4ff;}
    @media(max-width:600px) {
      .adli-harita .adli-panel {max-width:220px;}
      .adli-harita .leaflet-control-layers {max-width:180px;}
      .adli-harita .adli-panel-icerik {max-height:min(170px,calc(100vh - 260px));}
      .adli-harita .leaflet-bottom.leaflet-left {bottom:54px;}
    }
  "))
  katlanir_panel <- function(etiket, icerik) paste0(
    "<details class='adli-panel'><summary>", guvenli_metin(etiket),
    "<span class='adli-kapat'>Kapat &#215;</span></summary>",
    "<div class='adli-panel-icerik'>", icerik, "</div></details>"
  )
  gruplar <- veri_seti$katman
  grup_csam <- "CSAM | IWF barındırma URL sayısı 2025"
  grup_model <- "MODEL | rpart test tahmini 2025"
  model_var <- !is.null(model_sonucu)
  if (model_var) {
    if (!inherits(model_sonucu$model, "rpart") ||
        !nrow(model_sonucu$test_tahminleri))
      stop("Harita için geçerli karar ağacı sonucu gereklidir.")
    t <- model_sonucu$test_tahminleri
    if (any(!is.finite(t$lat) | !is.finite(t$lng) |
            !is.finite(t$tahmin_url_2025)))
      stop("Test tahminlerinin koordinat veya sayısal değerleri geçersiz.")
    if (any(t$veri_bolumu != "Test") ||
        length(intersect(t$geo_id, model_sonucu$egitim$geo_id)))
      stop("Tahmin katmanında yalnızca eğitimde görülmemiş test ülkeleri olabilir.")
  }
  yogunluk_opakliklari <- c(
    "1–9 URL" = .15, "10–99 URL" = .35, "100–999 URL" = .55,
    "1.000–9.999 URL" = .8, "10.000 ve üzeri URL" = 1
  )
  renkler <- c(
    "RESMÎ | NCMEC ülke / bölge 2025" = "#ff372d",
    "RESMÎ | ABD eyaletleri + DC 2025" = "#4ad8e8",
    "RESMÎ | Kanada eyalet oranları 2024" = "#c3a1ff"
  )
  if (any(!gruplar %in% names(renkler))) stop("Tanımsız resmî katman.")
  csam_var <- !is.null(csam_veri) && nrow(csam_veri) > 0L
  if (csam_var && any(!csam_veri$yogunluk_sinifi %in% names(yogunluk_opakliklari)))
    stop("CSAM yoğunluk sınıfı tanımsız.")
  if (csam_var) {
    beklenen_sinif <- as.character(cut(
      csam_veri$url_sayisi, c(-Inf, 10, 100, 1000, 10000, Inf),
      right = FALSE, labels = names(yogunluk_opakliklari)
    ))
    if (anyNA(csam_veri$yogunluk_sinifi) ||
        any(csam_veri$yogunluk_sinifi != beklenen_sinif))
      stop("CSAM yoğunluk sınıfı URL sayısıyla uyuşmuyor.")
  }
  if (model_var) {
    model_popup <- paste0(
      "<div class='adli-popup'><div class='adli-popup-baslik'>KARAR AĞACI TAHMİNİ</div>",
      "<div class='adli-popup-uyari'>TEST ÜLKESİ / EĞİTİMDE KULLANILMADI</div>",
      satir("Ülke / bölge", t$bolge_adi),
      "<div class='adli-popup-skor'>", sayi(t$tahmin_url_2025, 1),
      " URL<small>Modelin 2025 için tahmini</small></div>",
      satir("Gözlenen 2025 URL", sayi(t$url_2025)),
      satir("Tahmin hatası (tahmin − gözlenen)", sayi(t$hata_url, 1)),
      "<div class='adli-popup-not'>Artı hata: model fazla tahmin etti. ",
      "Eksi hata: model az tahmin etti. ",
      "Bu değer mağdur, fail veya yeni bir suç olasılığı değildir.</div>",
      "<details><summary>Model ve veri kaynağı</summary>",
      satir("Girdi: 2024 CSAM bağlantılı URL", sayi(t$url_2024)),
      satir("Girdi: 2024 alan adı", sayi(t$domain_2024)),
      "<div class='adli-popup-not'>rpart regresyon ağacı; ",
      "log(1 + URL) hedefi, ters dönüşüm exp(tahmin) − 1. ",
      "Test ülkesi budama ve eğitimde kullanılmadı. ",
      "Bu geriye dönük ülke testidir; ileri yıl performansı kanıtı değildir.</div>",
      kaynak_baglantisi(t$kaynak_2024_url, "IWF 2024: URL sayıları"),
      "<br>", kaynak_baglantisi(t$kaynak_2024_domain, "IWF 2024: alan adı sayıları"),
      "<br>", kaynak_baglantisi(t$kaynak_2025_url, "IWF 2025: gözlenen hedef"),
      "</details></div>"
    )
    tahmin_siniflari <- as.character(cut(
      t$tahmin_url_2025, c(-Inf, 10, 100, 1000, 10000, Inf),
      right = FALSE, labels = names(yogunluk_opakliklari)
    ))
    model_katman_ekle <- function(m) {
      for (sinif in names(yogunluk_opakliklari)) {
        idx <- which(tahmin_siniflari == sinif)
        if (!length(idx)) next
        m <- m %>% addMarkers(
          data = t[idx, , drop = FALSE], lng = ~lng, lat = ~lat,
          layerId = ~paste0("TAHMIN_", geo_id), group = grup_model,
          icon = kare_ikonu_yap("#ffc26e", yogunluk_opakliklari[[sinif]]),
          popup = model_popup[idx],
          popupOptions = popupOptions(
            maxWidth = 300, minWidth = 180, maxHeight = 260,
            autoPanPaddingTopLeft = c(60, 125), autoPanPaddingBottomRight = c(10, 65)
          ),
          label = lapply(idx, function(i) htmltools::HTML(paste0(
            guvenli_metin(t$bolge_adi[i]), " | TEST: ",
            sayi(t$tahmin_url_2025[i], 1), " URL tahmini | Gözlenen: ",
            sayi(t$url_2025[i])
          ))),
          options = markerOptions(riseOnHover = TRUE, keyboard = TRUE)
        )
      }
      m %>% hideGroup(grup_model)
    }
  }
  dunya_sinirlari <- list(c(-85.0511, -180), c(85.0511, 180))
  
  m <- leaflet(
    data = veri_seti, width = NULL, height = NULL,
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = "100%", defaultHeight = 780,
      viewer.fill = TRUE, browser.fill = TRUE, padding = 0
    ),
    options = leafletOptions(
      minZoom = 0, maxZoom = 18, worldCopyJump = TRUE, zoomControl = TRUE
    )
  ) %>%
    addProviderTiles(
      providers$Esri.WorldImagery, layerId = "adli-uydu",
      group = "Uydu Görünümü",
      options = providerTileOptions(
        noWrap = TRUE, maxNativeZoom = 18, bounds = dunya_sinirlari
      )
    ) %>%
    # CARTO tamamen kaldırıldı; bu URL'ye API anahtarı eklenmez.
    addTiles(
      urlTemplate = paste0(
        "https://services.arcgisonline.com/ArcGIS/rest/services/",
        "Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}"
      ),
      layerId = "adli-koyu", group = "Koyu Analiz Görünümü",
      attribution = paste0(
        'Tiles &copy; <a href="https://www.esri.com/">Esri</a>, HERE, Garmin, ',
        '&copy; <a href="https://www.openstreetmap.org/copyright">',
        'OpenStreetMap</a> contributors, and the GIS user community'
      ),
      options = tileOptions(
        noWrap = TRUE, maxNativeZoom = 10, maxZoom = 18,
        bounds = dunya_sinirlari
      )
    ) %>%
    hideGroup("Koyu Analiz Görünümü")
  
  # Her kayıt benzersizdir; aynı ülkenin alt bölgeleri birbirini ezmez.
  for (grup in unique(gruplar)) {
    idx <- which(gruplar == grup)
    m <- m %>% addMarkers(
      data = veri_seti[idx, , drop = FALSE], lng = ~lng, lat = ~lat,
      layerId = ~kayit_id, group = grup, icon = kare_ikonu_yap(renkler[[grup]]),
      popup = popup_icerigi[idx],
      popupOptions = popupOptions(
        maxWidth = 300, minWidth = 180, maxHeight = 260, autoPan = TRUE,
        autoPanPaddingTopLeft = c(60, 125), autoPanPaddingBottomRight = c(10, 65)
      ),
      label = kisa_etiket[idx],
      options = markerOptions(riseOnHover = TRUE, keyboard = TRUE)
    ) %>% hideGroup(grup)
  }
  if (csam_var) {
    csam_popup <- paste0(
      "<div class='adli-popup'><div class='adli-popup-baslik'>CSAM BARINDIRMA YOĞUNLUĞU</div>",
      "<div class='adli-popup-uyari'>IWF 2025 / YAYIMLANMIŞ KAYNAK VERİSİ</div>",
      satir("Barındırma ülkesi / bölgesi", csam_veri$bolge_adi),
      satir("Dönem", csam_veri$donem),
      "<div class='adli-popup-skor'>", sayi(csam_veri$url_sayisi),
      " URL<small>CSAM gösteren veya CSAM'a yönlendiren web adresi</small></div>",
      satir("IWF'nin yayımladığı dünya toplamındaki payı",
            paste0("%", sayi(csam_veri$toplamdaki_pay_yuzde, 4))),
      "<div class='adli-popup-not'>IWF'nin bu ülkede barındırıldığını ",
      "belirleyip işlem yaptığı CSAM bağlantılı web adreslerini sayar. ",
      "Mağdur, fail, ihbar, kayıp çocuk veya indirme sayısı değildir.</div>",
      "<details><summary>Kaynak ve sınırlılıklar</summary>",
      kaynak_baglantisi(csam_veri$kaynak_url, "IWF 2025: ülkelere göre barındırma tablosu"),
      "<br>", kaynak_baglantisi(csam_veri$koordinat_kaynagi, "Temsili ülke koordinatı"),
      "<div class='adli-popup-not'>Erişim: ", guvenli_metin(csam_veri$kaynak_goruntusu),
      ". Bir URL bir görüntü, bir mağdur veya ayrı bir suç demek değildir. ",
      "Veri tüm interneti değil, IWF'nin tespit ettiği ve işlem yaptığı URL'leri kapsar. ",
      "Kare ülkeyi temsil eder; sunucu veya olay yeri değildir. ",
      "Nüfusa veya yüzölçümüne göre oranlanmamıştır.</div>",
      "<div class='adli-popup-not'>",
      guvenli_metin(csam_veri$kaynak_tutarlilik_notu),
      "</div></details></div>"
    )
    for (sinif in names(yogunluk_opakliklari)) {
      idx <- which(csam_veri$yogunluk_sinifi == sinif)
      if (!length(idx)) next
      m <- m %>% addMarkers(
        data = csam_veri[idx, , drop = FALSE], lng = ~lng, lat = ~lat,
        layerId = ~kayit_id, group = grup_csam,
        icon = kare_ikonu_yap("#ff372d", yogunluk_opakliklari[[sinif]]),
        popup = csam_popup[idx],
        popupOptions = popupOptions(
          maxWidth = 300, minWidth = 180, maxHeight = 260,
          autoPanPaddingTopLeft = c(60, 125), autoPanPaddingBottomRight = c(10, 65)
        ),
        label = lapply(idx, function(i) htmltools::HTML(paste0(
          guvenli_metin(csam_veri$bolge_adi[i]), " | ",
          sayi(csam_veri$url_sayisi[i]), " CSAM bağlantılı URL | IWF 2025"
        ))),
        options = markerOptions(riseOnHover = TRUE, keyboard = TRUE)
      )
    }
  }
  if (model_var) m <- model_katman_ekle(m)
  harita_disi_metin <- if (nrow(haritalanamayan))
    paste(guvenli_metin(haritalanamayan$bolge_adi), collapse = "; ") else "Yok"
  lejant_satirlari <- paste0(
    "<div><span class='adli-kare-ornek' style='border-color:", renkler,
    ";background:", renkler, "33'></span>", guvenli_metin(names(renkler)),
    "</div>", collapse = ""
  )
  csam_lejanti <- paste0(
    "<div><span class='adli-kare-ornek' style='background:rgba(255,55,45,",
    yogunluk_opakliklari, ")'></span>",
    guvenli_metin(names(yogunluk_opakliklari)), "</div>", collapse = ""
  )
  if (model_var) {
    agac_met <- model_sonucu$metrikler[1, ]
    kalici_met <- model_sonucu$metrikler[2, ]
    model_bilgi <- paste0(
      "<div class='adli-panel-baslik'>CHAPTER 4.2 / KARAR AĞACI</div>",
      "<div><b>Soru:</b> 2024 URL ve alan adı sayılarıyla 2025 URL adedi tahmin edilebilir mi?</div>",
      "<div><b>Yöntem:</b> rpart regresyon ağacı + eğitim içi CV ile budama.</div>",
      "<div>", nrow(model_sonucu$egitim), " eğitim / ",
      nrow(model_sonucu$test), " test ülkesi. Tohum: ", model_sonucu$tohum, ".</div>",
      "<div><b>Test MAE:</b> ", sayi(agac_met$MAE, 1), " URL.</div>",
      "<div><b>Test RMSLE:</b> ", sayi(agac_met$RMSLE, 3), ".</div>",
      "<div>Önceki yıl sabit kalsaydı MAE: ", sayi(kalici_met$MAE, 1), " URL.</div>",
      "<div class='adli-uyari'>",
      if (agac_met$MAE < kalici_met$MAE)
        "Bu testte ağaç, önceki yıl sabit tahmininden MAE bakımından daha iyi."
      else
        "Bu testte ağaç, önceki yıl sabit tahmininden MAE bakımından daha iyi değil.",
      " Sonuç yalnız bu test ülkelerine aittir; gelecekteki performansı garanti etmez.</div>",
      "<details><summary>Sonuçları nasıl okuyacağım?</summary>",
      "<div>MAE: ortalama mutlak URL hatası; küçük daha iyi. ",
      "RMSLE: log ölçekte hata; küçük daha iyi. RMSE ve R² CSV/rapordadır.</div>",
      "<div>Sarı kare: yalnız test ülkesi için model tahmini. ",
      "Katman kontrolünden MODEL'i seçin; gözlenen katman otomatik kapanır.</div>",
      "<div>CP: ", sayi(model_sonucu$secilen_cp, 6),
      ". Beş katlı CV yalnız eğitimde. Eksik ölçümlü kayıtlar sıfır yapılmadı.</div>",
      "<div>Az ülke, tek 2024→2025 geçişi ve değişebilen tespit kapsamı nedeniyle ",
      "sonuç keşifseldir; nedensellik veya gelecekteki suç riski çıkarılamaz.</div>",
      "<div>Ağaç, grafikler, rapor ve CSV: csam_chapter4_ciktilari klasöründe.</div>",
      "</details>"
    )
    m <- m %>% addControl(
      html = katlanir_panel("Model", model_bilgi),
      position = "topleft", className = "adli-control"
    )
  }
  m <- m %>%
    addControl(
      html = katlanir_panel("Bilgi", paste0(
        "<div class='adli-panel-baslik'>CSAM BARINDIRMA YOĞUNLUĞU</div>",
        "<div><b>Ne sayılıyor?</b> CSAM gösteren veya CSAM'a yönlendiren web adresleri.</div>",
        "<div><b>Kaynak:</b> Internet Watch Foundation (IWF), 2025.</div>",
        "<div><b>Kırmızı kare:</b> Ülke/bölge. İç dolgu güçlendikçe tespit edilen URL sayısı artar.</div>",
        "<div class='adli-uyari'>Bu, tespit edilmiş CSAM barındırma hacmidir; ",
        "mağdur, fail veya indirme yoğunluğu değildir.</div>",
        "<details><summary>Kapsam ve yöntem</summary>",
        "<div>Haritada ", if (csam_var) nrow(csam_veri) else 0,
        " ülke/bölge. Sayılar gerçek yayımlanmış veridir; simülasyon kullanılmaz.</div>",
        "<div>Ham adres veya IP toplanmaz. Noktalar ülke temsili konumlarıdır. ",
        "Nüfusa veya yüzölçümüne göre normalize edilmemiştir; ",
        "tüm internetin eksiksiz sayımı değildir. Verisi olmayan ülke sıfır sayılmaz.</div>",
        if (csam_var) paste0(
          "<div>Kaynağın yayımladığı toplam: 310.437 URL. ",
          "Haritada konumlandırılamayan CSAM kayıtları: ",
          guvenli_metin(paste(csam_harita_disi$bolge_adi, collapse = "; ")),
          ". Ayrı CSV'de korunur.</div>",
          "<div>", guvenli_metin(csam_veri$kaynak_tutarlilik_notu[1]), "</div>"
        ) else "",
        "<div>Ek NCMEC ve Kanada katmanları başlangıçta kapalıdır; ",
        "farklı göstergelerdir ve ana CSAM URL ölçüsüne katılmaz.</div>",
        "<details><summary>Eski kaynak katmanlarının kapsamı</summary>",
        toplam_resmi, " kayıt; ", nrow(veri_seti), " haritada; ",
        nrow(haritalanamayan), " konumlandırılamamış: ", harita_disi_metin,
        ".</details></details>"
      )),
      position = "topleft", className = "adli-control"
    ) %>%
    addControl(
      html = katlanir_panel("Lejant", paste0(
        "<div class='adli-panel-baslik'>CSAM BAĞLANTILI URL SAYISI</div>",
        if (csam_var) csam_lejanti else "<div>IWF verisi yüklenmedi.</div>",
        "<div class='adli-uyari'>Kare boyutu sabit; dolgu tespit edilen URL hacmini gösterir. ",
        "Her kare bir ülke/bölgedir, tek bir olay değildir.</div>",
        if (model_var) paste0(
          "<details><summary>Model tahmini katmanı</summary>",
          "<div><span class='adli-kare-ornek' style='border-color:#ffc26e;",
          "background:#ffc26e66'></span>Sarı: test ülkeleri için tahmin.</div>",
          "<div>Aynı URL aralıkları kullanılır; ilk aralık 0 dahil 10 hariçtir. ",
          "Sarı tahmin, kırmızı yayımlanmış veridir. Hata ayrıntısı kareye tıklayınca açılır.</div>",
          "</details>"
        ) else "",
        "<details><summary>Ek kaynak katmanları</summary>",
        lejant_satirlari,
        "<div>Bu ek katmanlarda renk kaynağı ayırır, yoğunluğu değil. ",
        "NCMEC genel bildirimleri CSAM dışında kategoriler de içerir; ",
        "Kanada kent/kır polis kayıt oranları ayrı bir göstergedir.</div></details>"
      )),
      position = "bottomright", className = "adli-control"
    ) %>%
    addControl(
      html = paste0(
        "<div class='adli-damga' role='status' aria-live='polite'>",
        "IWF 2025 | CSAM BARINDIRMA</div>",
        "<div class='adli-tile-uyari' role='status' aria-live='polite' hidden>",
        "Altlık yüklenemedi. İnterneti kontrol edin veya diğer altlığı seçin.</div>"
      ), position = "bottomleft", className = "adli-control"
    ) %>%
    addLayersControl(
      baseGroups = c("Uydu Görünümü", "Koyu Analiz Görünümü"),
      overlayGroups = c(if (csam_var) grup_csam, if (model_var) grup_model,
                        unique(gruplar)),
      options = layersControlOptions(collapsed = TRUE)
    ) %>%
    addScaleBar(
      position = "bottomleft",
      options = scaleBarOptions(metric = TRUE, imperial = FALSE)
    ) %>%
    fitBounds(
      lng1 = max(-180, min(veri_seti$lng) - 5),
      lat1 = max(-85.0511, min(veri_seti$lat) - 5),
      lng2 = min(180, max(veri_seti$lng) + 5),
      lat2 = min(85.0511, max(veri_seti$lat) + 5)
    )
  
  m <- htmlwidgets::onRender(m, "
    function(el, x) {
      var map = this;
      el.classList.add('adli-harita');
      el.querySelectorAll('.adli-panel').forEach(function(panel) {
        L.DomEvent.disableClickPropagation(panel);
        L.DomEvent.disableScrollPropagation(panel);
      });
      var notice = el.querySelector('.adli-tile-uyari');
      ['adli-uydu', 'adli-koyu'].forEach(function(id) {
        var layer = map.layerManager.getLayer('tile', id);
        if (!layer) return;
        layer.on('tileerror', function() {
          if (notice && map.hasLayer(layer)) notice.hidden = false;
        });
      });
      map.on('baselayerchange', function() {
        if (notice) notice.hidden = true;
      });
      var badge = el.querySelector('.adli-damga');
      var observedName = 'CSAM | IWF barındırma URL sayısı 2025';
      var modelName = 'MODEL | rpart test tahmini 2025';
      function refreshBadge() {
        if (!badge) return;
        var model = map.layerManager.getLayerGroup(modelName);
        var observed = map.layerManager.getLayerGroup(observedName);
        var modelActive = model && map.hasLayer(model);
        badge.textContent = modelActive ? 'RPART | TEST TAHMİNLERİ' :
          (observed && map.hasLayer(observed) ?
           'IWF 2025 | CSAM BARINDIRMA' : 'ANA KATMAN KAPALI | EK KAYNAKLAR AYRI');
        badge.style.borderColor = modelActive ? '#ffc26e' : '#47525f';
      }
      function updateCsamBadge(e, active) {
        if (active && (e.name === observedName || e.name === modelName)) {
          // Leaflet checkbox döngüsü tamamlandıktan sonra öteki ana katmanı kapat.
          // Aynı event içinde kapatmak, kontrolün katmanı yeniden açmasına yol açar.
          requestAnimationFrame(function() {
            var other = map.layerManager.getLayerGroup(
              e.name === modelName ? observedName : modelName
            );
            if (other && map.hasLayer(other)) map.removeLayer(other);
            refreshBadge();
          });
        } else {
          refreshBadge();
        }
      }
      map.on('overlayadd', function(e) { updateCsamBadge(e, true); });
      map.on('overlayremove', function(e) { updateCsamBadge(e, false); });
      function fitPopup(popup) {
        popup.options.maxWidth = Math.min(300, Math.max(180, map.getSize().x - 110));
        popup.options.maxHeight = Math.min(260, Math.max(100, map.getSize().y - 230));
        popup.update();
      }
      map.on('popupopen', function(e) {
        // Bilgi/lejant kartları popup içeriğinin üstüne binmez.
        el.querySelectorAll('.adli-panel[open]').forEach(function(panel) {
          panel.open = false;
        });
        fitPopup(e.popup);
      });
      map.on('resize', function() {
        requestAnimationFrame(function() {
          map.eachLayer(function(layer) {
            if (layer instanceof L.Popup) fitPopup(layer);
          });
        });
      });
      requestAnimationFrame(function() { map.invalidateSize(false); });
    }
  ")
  htmlwidgets::prependContent(m, stil)
}

dogrula_model_sonucu <- function(s) {
  stopifnot(
    inherits(s$model, "rpart"),
    s$model$method == "anova",
    setequal(attr(stats::terms(s$model), "term.labels"),
             c("url_2024", "domain_2024")),
    length(intersect(s$egitim$geo_id, s$test$geo_id)) == 0L,
    nrow(s$test_tahminleri) == nrow(s$test),
    all(s$test_tahminleri$veri_bolumu == "Test"),
    all(is.finite(s$tahminler$tahmin_url_2025)),
    all(s$tahminler$tahmin_url_2025 >= 0),
    s$secilen_cp == s$cp_tablosu$CP[which.min(s$cp_tablosu$xerror)],
    all(s$metrikler$n_test == nrow(s$test)),
    all(is.finite(s$metrikler$MAE)),
    all(is.finite(s$metrikler$RMSE)),
    all(is.finite(s$metrikler$RMSLE))
  )
  invisible(TRUE)
}

kaydet_model_ciktilari <- function(s, model_verisi, cikti_klasoru) {
  dir.create(cikti_klasoru, recursive = TRUE, showWarnings = FALSE)
  yol <- function(ad) file.path(cikti_klasoru, ad)
  csv <- function(d, ad) utils::write.csv(
    d, yol(ad), row.names = FALSE, na = "", fileEncoding = "UTF-8"
  )
  csv(s$tahminler, "model_tum_kayitlar_egitim_test.csv")
  csv(s$test_tahminleri, "model_test_tahminleri.csv")
  csv(s$metrikler, "model_test_metrikleri.csv")
  csv(s$cp_tablosu, "model_cp_tablosu.csv")
  csv(s$degisken_onemi, "model_degisken_onemi.csv")
  csv(model_verisi$gecmis_ham, "iwf_2024_gecmis_gostergeler.csv")
  csv(model_verisi$tum_kayitlar, "model_kaynak_birlestirme_tam.csv")
  csv(s$dislanan, "model_dislanan_kayitlar.csv")
  saveRDS(
    list(model = s$model, ilk_model = s$ilk_model, formulu = s$formulu,
         secilen_cp = s$secilen_cp, tohum = s$tohum,
         egitim_ulkeleri = s$egitim$geo_id, test_ulkeleri = s$test$geo_id,
         test_metrikleri = s$metrikler,
         hedef_donusumu = "log1p(url_2025)",
         ters_donusum = "pmax(0, expm1(predict(model, newdata)))"),
    yol("rpart_karar_agaci.rds")
  )
  writeLines(capture.output(utils::sessionInfo()), yol("R_sessionInfo.txt"),
             useBytes = TRUE)

  # Mevcut koyu görsel dile uygun, yüksek çözünürlüklü rapor grafikleri.
  grafik_yap <- function(ad, ciz, genislik = 2400, yukseklik = 1500) {
    grDevices::png(yol(ad), width = genislik, height = yukseklik, res = 160)
    on.exit(grDevices::dev.off(), add = TRUE)
    eski_secenek <- options(scipen = 999)
    on.exit(options(eski_secenek), add = TRUE)
    graphics::par(
      bg = "#111820", fg = "#e7edf3", col = "#e7edf3", col.axis = "#c2cdd8",
      col.lab = "#e7edf3", col.main = "#ffffff",
      mar = c(5, 5, 4, 2), family = "sans"
    )
    ciz()
  }
  grafik_yap("karar_agaci.png", function() {
    if (nrow(s$model$frame) > 1L) {
      # Yalnız çizim kopyası URL ölçeğinde gösterilir; kayıtlı model değiştirilmez.
      gosterim <- s$model
      gosterim$frame$yval <- round(pmax(0, expm1(gosterim$frame$yval)), 1)
      graphics::plot(gosterim, uniform = TRUE, branch = .45, margin = .13,
                     branch.col = "#8fa4b8", branch.lwd = 2)
      graphics::text(
        gosterim, use.n = TRUE, all = FALSE, digits = 6,
        cex = .9, col = "#f0f4f8", fancy = FALSE
      )
    } else {
      graphics::plot.new()
      graphics::text(
        .5, .55, paste0("Tek yaprak: tahmini URL = ",
                       round(expm1(s$model$frame$yval[1]), 1)),
        col = "#f0f4f8", cex = 1.3
      )
    }
    graphics::title(main = "Chapter 4.2 | Budanmis rpart regresyon agaci")
    graphics::mtext(
      paste0(
        "Yaprak: tahmini URL; n: egitim ulkesi. Model log hedefinde egitildi.",
        "  Egitim: ", nrow(s$egitim), "; test: ", nrow(s$test),
        "; CP: ", signif(s$secilen_cp, 4)
      ), side = 1, line = 3, col = "#c2cdd8", cex = .85
    )
  })
  grafik_yap("gozlenen_tahmin_karsilastirmasi.png", function() {
    graphics::par(mfrow = c(1, 2), mar = c(5, 5, 4, 1))
    t <- s$test_tahminleri
    aralik <- range(c(0, t$url_2025, t$tahmin_url_2025))
    graphics::plot(
      t$url_2025, t$tahmin_url_2025, xlim = aralik, ylim = aralik,
      pch = 21, bg = "#ffc26e", col = "#111820", cex = 1.5,
      xlab = "Gozlenen 2025 URL", ylab = "Karar agaci tahmini",
      main = "Test ulkeleri | URL adedi"
    )
    graphics::abline(a = 0, b = 1, col = "#4ad8e8", lwd = 2, lty = 2)
    log_aralik <- log1p(aralik)
    graphics::plot(
      log1p(t$url_2025), log1p(t$tahmin_url_2025),
      xlim = log_aralik, ylim = log_aralik,
      pch = 21, bg = "#ffc26e", col = "#111820", cex = 1.5,
      xlab = "log(1 + gozlenen URL)", ylab = "log(1 + tahmin URL)",
      main = "Ayni test | Log olcek"
    )
    graphics::abline(a = 0, b = 1, col = "#4ad8e8", lwd = 2, lty = 2)
  }, yukseklik = 1150)
  grafik_yap("budama_cv_hatasi.png", function() {
    rpart::plotcp(s$ilk_model, col = "#ffc26e",
                  main = "Yalniz egitim verisinde capraz dogrulama")
    graphics::mtext("Secim: xerror en kucuk olan CP; test bu secimde kullanilmaz.",
                    side = 1, line = 3.5, col = "#c2cdd8")
  })
  grafik_yap("degisken_onemi.png", function() {
    deger <- s$degisken_onemi$onem
    graphics::barplot(
      deger, names.arg = c("2024 URL", "2024 alan adi"),
      col = c("#ff372d", "#4ad8e8"), border = NA,
      ylim = c(0, max(1, deger) * 1.2),
      ylab = "Agac degisken onemi (goreli)", main = "Budanmis agacta degisken onemi"
    )
    graphics::mtext("Nedensellik veya bagimsiz katki kaniti degildir.",
                    side = 1, line = 3.5, col = "#c2cdd8")
  })

  m <- s$metrikler
  metrik_satirlari <- vapply(seq_len(nrow(m)), function(i) {
    sprintf("| %s | %.2f | %.2f | %.4f | %.4f |",
            m$model[i], m$MAE[i], m$RMSE[i], m$RMSLE[i], m$R2[i])
  }, character(1))
  rapor <- c(
    "# CSAM barındırma: Chapter 4.2 karar ağacı tahmin modeli",
    "",
    "## Araştırma sorusu",
    "2024 ülke URL ve alan adı sayıları kullanılarak 2025 CSAM bağlantılı URL sayısı tahmin edilebilir mi?",
    "",
    "## Kaynaklar ve sayılan birim",
    paste0(
      "2024 URL adedi, CSAM gösteren veya CSAM'a yönlendiren ve IWF'nin işlem yaptığı ",
      "web adreslerini sayar ([IWF 2024 URL tablosu](",
      model_verisi$veri$kaynak_2024_url[1], "))."
    ),
    paste0(
      "Alan adı adedi ayrı bir ölçüdür; URL adediyle aynı birim değildir ",
      "([IWF 2024 alan adı tablosu](",
      model_verisi$veri$kaynak_2024_domain[1], "))."
    ),
    paste0(
      "Hedef 2025 ülke URL adedidir; mağdur, fail, indirme veya doğrulanmış suç sayısı ",
      "olarak adlandırılmaz ([IWF 2025 ülke tablosu](",
      model_verisi$veri$kaynak_2025_url[1], "))."
    ),
    "",
    "## Chapter 4 ile eşleşme",
    "- Chapter 4.2'deki gibi sayısal hedef için rpart regresyon ağacı kurulmuştur.",
    paste0("- Sabit tohum: ", s$tohum, ". Eğitim: ", nrow(s$egitim),
           " ülke; test: ", nrow(s$test), " ülke. Oran yaklaşık %70 / %30."),
    "- Hedef log1p(URL_2025), girdiler yalnızca URL_2024 ve domain_2024'tür.",
    "- Ülke kodu/adı, koordinatlar, 2025 payı ve 2025 sınıfı girdilere eklenmemiştir.",
    paste0(
      "- Eğitim içinde beş katlı çapraz doğrulama ile en düşük xerror CP'si ",
      "seçilmiş ve ağaç budanmıştır; test verisi bu aşamada kullanılmaz. ",
      "CP budaması için [rpart belgeleri]",
      "(https://stat.ethz.ch/R-manual/R-devel/library/rpart/html/prune.rpart.html)."
    ),
    paste0("- Seçilen CP: ", signif(s$secilen_cp, 6), "."),
    "- Tahminler expm1 ile URL ölçeğine çevrilir ve sıfırın altına düşmez.",
    "- Bu ters dönüşüm, log-ölçekli merkez tahminidir; aritmetik koşullu ortalama iddiası yoktur.",
    "- Test tahminleri eğitim-içi tahminlerden ayrı CSV'de tutulur.",
    "",
    "## Ayrılmış test sonuçları",
    "| Model | MAE (URL) | RMSE (URL) | RMSLE | R² |",
    "|---|---:|---:|---:|---:|",
    metrik_satirlari,
    "",
    "MAE, RMSE ve RMSLE için küçük değer daha iyidir. R² negatif olabilir; böyle bir sonuç gizlenmez.",
    if (m$MAE[1] < m$MAE[2])
      "Bu ayrımda karar ağacı, önceki yıl sabit baseline'ından MAE bakımından daha iyidir."
    else
      "Bu ayrımda karar ağacı, önceki yıl sabit baseline'ından MAE bakımından daha iyi değildir.",
    "Bu bir regresyon modelidir; sonuçlar sınıflandırma doğruluğu yüzdesi gibi raporlanmaz.",
    "",
    "## Kapsam ve sınırlılıklar",
    paste0("- Tam ölçümlü ülke sayısı: ", nrow(model_verisi$veri),
           ". Dışlanan kayıt sayısı: ", nrow(s$dislanan), "."),
    "- Kaynaktaki '-' işaretleri ve listede bulunmayan değerler sıfır kabul edilmedi.",
    "- Yalnız üç ölçümü de mevcut ülkeler kullanılır; kapsama bağlı seçilim yanlılığı vardır.",
    "- Onion kategorisi ülke değildir ve modele alınmaz.",
    "- Tek 2024→2025 geçişi vardır; ülke bazlı test ileri yıllara yönelik zaman doğrulaması değildir.",
    "- 2025 gerçekleşmeleri bugün bilindiği için bu, geriye dönük bir tahmin deneyidir.",
    "- Barındırma ülkesi gerçek olay yeri, mağdurun/failin yeri veya ulusal suç eğilimi değildir.",
    "- Tespit kapsamı, altyapı ve taşıma değişimleri gözlenen sayıları etkileyebilir; nedensellik kurulmaz.",
    "- İki girdi ilişkili olabilir; değişken önemi bağımsız nedensel katkı değildir.",
    "- Tek ve küçük test ayrımı belirsizlik taşır; güven aralığı veya operasyonel güvenilirlik iddiası yoktur.",
    "- 2025 UK küresel tabloda 950, aynı kaynak sayfasının UK metninde 951'dir; küresel tablo korunur.",
    "- Veri yılı ile erişim tarihi farklıdır: erişim 28.10.2026.",
    "",
    "## Üretilen dosyalar",
    "- csam_chapter4_harita.html: gözlenen CSAM ve ayrı test tahmini katmanı.",
    "- karar_agaci.png: budanmış ağaç; yapraklar okunabilirlik için URL ölçeğine geri dönüştürülür.",
    "- gozlenen_tahmin_karsilastirmasi.png: test gözlenen/tahmin grafiği.",
    "- budama_cv_hatasi.png, degisken_onemi.png: eğitim/model tanı grafikleri.",
    "- model_test_metrikleri.csv, model_test_tahminleri.csv: test sonuçları.",
    "- model_tum_kayitlar_egitim_test.csv: eğitim ve test etiketli tüm tahminler.",
    "- model_dislanan_kayitlar.csv: dışlama nedeni açık kayıtlar.",
    "- rpart_karar_agaci.rds: model, tohum, ülke ayrımı ve dönüşüm bilgisi.",
    "- R_sessionInfo.txt: kullanılan R ve paket sürümleri."
  )
  writeLines(enc2utf8(rapor), yol("model_raporu.md"), useBytes = TRUE)
  invisible(cikti_klasoru)
}

# ==============================================================================
# 3. PIPELINE ÇALIŞTIRMA MODÜLÜ
# ==============================================================================
cikti_klasoru <- file.path(getwd(), "csam_chapter4_ciktilari")
dir.create(cikti_klasoru, recursive = TRUE, showWarnings = FALSE)
adli_veri_seti <- olustur_adli_veri()
csam_veri_seti <- olustur_csam_veri()
model_verisi <- olustur_model_verisi(csam_veri_seti)
karar_agaci_sonucu <- egit_karar_agaci(model_verisi, tohum = 1234L)
dogrula_model_sonucu(karar_agaci_sonucu)
kaydet_model_ciktilari(karar_agaci_sonucu, model_verisi, cikti_klasoru)
haritalanamayan_kayitlar <- adli_veri_seti[
  adli_veri_seti$harita_durumu != "Gösteriliyor", , drop = FALSE
]
kurumsal_adli_harita <- ciz_kurumsal_adli_harita(
  adli_veri_seti, csam_veri = csam_veri_seti,
  model_sonucu = karar_agaci_sonucu
)

# CSAM ana tablosu ve eski kaynak tabloları ayrı dosyalardır; toplanmazlar.
utils::write.csv(
  adli_veri_seti, file.path(cikti_klasoru, "csam_resmi_istatistikler.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)
utils::write.csv(
  csam_veri_seti, file.path(cikti_klasoru, "csam_iwf_2025_ulke_istatistikleri.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)
utils::write.csv(
  haritalanamayan_kayitlar, file.path(cikti_klasoru, "csam_harita_disi_kayitlar.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)
utils::write.csv(
  csam_veri_seti[csam_veri_seti$harita_durumu != "Gösteriliyor", , drop = FALSE],
  file.path(cikti_klasoru, "csam_iwf_harita_disi_kayitlar.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8"
)

# Pandoc yoksa da HTML üretilir; bu durumda *_files klasörünü yanında tutun.
pandoc_var <- (
  requireNamespace("rmarkdown", quietly = TRUE) &&
    rmarkdown::pandoc_available()
)
cikti_dosyasi <- file.path(cikti_klasoru, "csam_chapter4_harita.html")
htmlwidgets::saveWidget(
  kurumsal_adli_harita, file = cikti_dosyasi,
  selfcontained = pandoc_var,
  title = "CSAM Barındırma ve Karar Ağacı | Chapter 4.2"
)
if (!pandoc_var) {
  warning(
    "Pandoc bulunamadı. HTML ile oluşan *_files klasörünü birlikte taşıyın.",
    call. = FALSE
  )
}
message("HTML çıktısı: ", normalizePath(cikti_dosyasi, mustWork = TRUE))
message("Model çıktıları: ", normalizePath(cikti_klasoru, mustWork = TRUE))
message("Eğitim ülkesi: ", nrow(karar_agaci_sonucu$egitim),
        " | Test ülkesi: ", nrow(karar_agaci_sonucu$test))
print(karar_agaci_sonucu$metrikler, row.names = FALSE)
message("Karar ağacı grafiği: karar_agaci.png | Yöntem ve sonuç: model_raporu.md")
# selfcontained = TRUE bile altlık karolarını gömmez; internet gereklidir.
print(kurumsal_adli_harita)
