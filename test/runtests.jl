using Test

test_set =  Dict("AR" => "النشوة وتمجيد الألم نشأت بالفعل، وسأعرض لك التفاصيل",
                 "CS" => "Chraň ji, nedovede-li už ona sebe chránit! Ty ji miluješ? Tedy se obětuj!",
                 "DA" => "Forældre har førsteret til at vælge den form for undervisning, som deres børn skal have.",
                 "DE" => "Vergnugt fu ri vornamen se wo burschen schuftet. Bei als ganzen musset tische tur harten nur. Es vornamen liebsten fu arbeiter sa.",
                 "EL" => "Διάφορες εκδοχές έχουν προκύψει με το πέρασμα των χρόνων, άλλες φορές κατά λάθος, άλλες φορές σκόπιμα.",
                 "EN" => "One advanced diverted domestic sex repeated bringing you old. Possible procured her trifling laughter thoughts property she met way.",
                 "ES" => "Indicarse resonaban sin reconocio complacia tio sea tormentos irascible. Esclavo glorias voz oro agujero tufillo muy ano encogia.",
                 "FA" => "مجله در ستون و سطرآنچنان که لازم است و برای شرایط فعلی تکنولوژی مورد نیاز و کاربردهای متنوع با هدف بهبود ابزارهای کاربردی می باشد",
                 "FI" => "On todistettu, että lukijaa häiritsee sivun ulkoasu lukiessaan sivua.",
                 "FR" => "Certes sol hordes globes ame raison. Au pentes je bourse me durcis la espace. Demeure ouvrent obtenue partout etaient une feu.",
                 "HE" => "היסטוריה כתב, שכל על ערכים הגולשות. מה ספורט בעברית אתנולוגיה אתה.",
                 "HI" => "होभर बाटते सहायता परिवहन ज्यादा आंतरजाल सम्पर्क संसाध सुनत सक्षम संपादक माध्यम सिद्धांत हैं। पहोचाना विश्वव्यापि प्राण उनको मुखय पहोचने",
                 "HU" => "Szüksége van egy könnyű, teljes megoldás a Magyar szöveget beszéddé?",
                 "IT" => "Quando essa veniva elogiata, tali aspetti erano visti come un miglioramento per la società",
                 "JP" => "さらに安倍さんが、「事務所が補塡した事実はない」などとしてきた答弁は、結果として虚偽だった可能性が高まっています。",
                 "KO" => "국회는 상호원조 또는 안전보장에 관한 조약. 국민에 대하여 책임을 진다. 원장은 국회의 동의를 얻어 대통령이 임명하고. 대법원장의 임기는 6년으로 하며.",
                 "NL" => "Komst deele de telde te er zeker. Meenemen dan gestegen cultures men getracht schijnen omwonden rug met.",
                 "NO" => "Så ville han Pål i veien og friste om ikke han hadde lykken til å bygge skip og vinne kongsdatteren og halve kongeriket.",
                 "PL" => "Nie chcę być niemiły, ale....nie będę mógł wyjść do toalety. Pomogę panu ją podnieść.",
                 "PT" => "Sem passeios dir penetrou dissesse arrojado absoluta sao. Frioleiras nao das recordarei excellente sao iii.",
                 "RU" => "кто. Звездны богачей неправд. Бледному принести звездной подобные теряться проблеск.",
                 "SV" => "Julklappar och presentkort till de inom vården. Men inte till timvikarierna.",
                 "TR" => "Ancak bunların büyük bir çoğunluğu mizah katılarak veya rastgele sözcükler eklenerek değiştirilmişlerdir.",
                 "UK" => "Оля, почитай щось з художньої літератури, яка краще передасть інтонації живої мови.",
                 "ZH" => "欢迎您到“跨年之城”海口参加湖南卫视跨年演唱会。根据跨年演唱会服务保障工作总体部署，为了您和大家的身体健康，请您仔细阅读本通告，严格遵守有关要求。")

L = LanguageFind

@testset "Test Random Lorem Ipsum" begin
for (key,value) in test_set
        @test lowercase(key) == L(value, 0).lang end end