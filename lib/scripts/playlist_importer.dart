import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String rawText = r"""
خاينه
راشد الماجد
جلسات وناسة 2009
8:40
لا خبر (Live)
راشد الماجد
جلسات وناسة 2010 (Live)
8:28

محلا اللقى
ماجد المهندس
محلا اللقى
4:29
خلاص
رابح صقر
رابح 2017, Vol. 1 & 2
4:10

ترا حقي
داليا
ترا حقي
6:04

Wallah Ma Yermesh
Ayed
Wallah Ma Yermesh
4:42

خلص حنانك
عبدالمجيد عبدالله
عبد المجيد عبد الله 2011
5:54

Ma Arda Aaleh
Jaber Al Kaser
Beda Yetghayar
5:01

Al Hob Al Awal (feat. Abdul Majeed Abdullah)
Rashed Al Majed
Honey Rashed
6:29
أبشر من عيوني
راشد الماجد
حفلة دبي 2016
6:12

La Tekhaf
Assala
Sawaha Qalbi
5:15

Ketha Momken
Dalia
Ketha Momken
4:44

Walhan
Rashed Al Majed
Walhan
5:33

مكانك مبين
نوال الكويتية
الحنين
3:50

Ya Bad Haldinya Leh
Rashed AlMajid
Ala Meen Telabha
4:15

حضرة الموقف
Assala Nasri
4:41

Btewsefni Bteksefni
Angham
Hala Khasa Gedan
4:28

نوال - انت طيب  (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
5:13

نوال - خذاني الشوق (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
5:19
عشيري
راشد الماجد
حفلة دبي 2016
6:05
يوجعونك
انغام
راح تذكرني
4:49
محتاجك
ماجد المهندس
إنسى
4:58

Talabtk
Assala
Sawaha Qalbi
6:17

الحب الكبير
Majed Al Mohandes 
 & 
Dalia Mubarak
الحب الكبير
8:21

الظروف
اصيل هميم
الظروف
6:08

Sehyswy
Rashed Al Majed
شيسوي
4:13

Yhizak Al Shooq
Majid al Muhandis
Yhizak Al Shooq
4:12

Enta Kolshay
Aseel Hameem
Enta Kolshay
4:49

كان ودي
داليا
كان ودي
5:17

نحن هنا
شمه حمدان
نحن هنا
5:10

Hanet Aliek
Abdul Majeed Abdullah
Hanet Aliek
4:58

بيني وبينك
داليا و اسماعيل مبارك
بيني وبينك
5:34

درب المضيع
داليا
درب المضيع
3:29
طيبة
شيما هلالي
بتقوم
4:22

El Zeman
Fouad Abdulwahed
Fouad Abdulwahed 2020
5:08
Asoulef Lel Matar
Oumaima Taleb, Nasser Al Quaima, Khaled, and Mohamad Al Koraithly
Asoulef Lel Matar
4:15

Bel Bont El3areedh
Hussain Aljassmi
Bel Bont El3areedh
3:23

Hattan
Majid Almuhandis
Hattan
4:37

سر الحياه
Aseel Hameem
سر الحياه
3:32

وش اخباري
داليا
جلسات وناسه 2017 الجزء 2
6:38

Been Edyah
Majid al Muhandis
Enjaneat
4:56
على طاري الفراق
ماجد المهندس
الدنيا دوارة, Vol. 1 & 2
4:53

Hala Khasa Gedan
Angham
Hala Khasa Gedan
4:46

الحب الجديد
Abdul Majeed Abdullah
4:41

بكره خير
نوال الكويتية
الحنين
3:58

Ela Mata
Assala
Qanuon kefak
5:09

Nadman
Nabeel Shuail
Kebir El Fan 2020
4:14
Ana W Ana
Oumaima Taleb, Wid, & Aazouf
Ana W Ana
4:30

مامات حبي لك (جلسات وناسه)
نوال الكویتیة
مامات حبي لك (جلسات وناسه)
4:26
شرطان الذهب
راشد الماجد
حفلة دبي 2016
5:42
مسافر في سما النسيان (Live)
راشد الماجد
جلسات وناسة 2010 (Live)
5:17
وين تروح
انغام
راح تذكرني
5:35
أعذرك
شيما هلالي
بتقوم
4:51

نوال  - طيب (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
6:30

Tadrun Shqali
Mahmoud Al-Turky
Tadrun Shqali
4:07

المفروض
اصيل هميم
المفروض
4:03

Yabakhty Feek
Mohammed Abdul Majeed
Yabakhty Feek
3:29

Mo Dharoori
Majid Almuhandis
Mo Dharoori
4:27

طلال سلامه - مستغربه | Talal Salama - Mestagrebha ( النسخة الأصلية ) 2019م
Nasser Alsaleh - ناصر الصالح
6:59

Ma Anadilek
Abdallah Al Rowaished
Abdullah Al Ruwaished 2019
7:02

Faman Allah
Rashed AlMajid
Shertan Al Thahab
5:05

Twassi Shai
Rashed AlMajid
Al Hadaya
5:27

Nesenakom
Rashed AlMajid
Al Hal Al Saab
5:27

Karhtek
Abdallah Al Rowaished
Abdullah Al Ruwaished 2019
4:56

Awedek Arhal
Fouad Abdulwahed
Fouad Abdulwahed 2020
4:41

Yaretak Fahemni
Angham
Hala Khasa Gedan
5:33

Wahashteeni
Rashed AlMajid
Al Msafer
6:26
سولف علي
عبدالله الرويشد
سولف علي
5:18

Alamtni
Rashed AlMajid
Shamat Hayati
8:10

ما سأل - عايض و راكان | Ma Saal - Ayed & Rakan ( دويتو )
Ahmad Naif
3:01

Ma Mal Galbek
Eman AlShmety
Ma Mal Galbek
4:48

ماعاد في الأحلام (جلسات وناسه)
راشد الماجد
ماعاد في الأحلام (جلسات وناسه)
6:48

ندامة - زياد و عبدالله
A2Z Music
5:02

صاير كلامك غير
عبدالله سالم و محمد العامر
صاير كلامك غير
3:40

لاتسامحني ولكن لاتضيق
فيصل الساهم
لاتسامحني ولكن لاتضيق
4:19

Gaza Allah Khair
Ayed
Thaman Alam
5:23

الله على ذا الليل ل عمر وريانه
نغمة وتر عمر
روائع الإستماع
5:25
اعتذر له
راشد الفارس
ناوي
4:01
مرماي
سهم
سهم
4:59

خذني
داليا
جلسات وناسه 2017 الجزء 7
5:45

Salam
Rashed AlMajid
Al Hal Al Saab
3:41

علميني
vpadya
علميني
4:34

من الآخر
برهان
من الآخر
5:19

الحاجة
ماجد المهندس و سهم
حفلة الثمامة الخاصة
6:23

صعب افهمك
فهد العمري
صعب افهمك
3:41

ماني مصدق (جلسات وناسه)
رابح صقر
ماني مصدق (جلسات وناسه)
5:38

رابح صقر غرام أطفال روقان الف 👌🏽😌
رابحيات
7:48

منت قادر تنسى غلطه
نغمة وتر عمر
الأعلى استماع
3:42

Rohy Jerby
Abdallah Al Rowaished
Abdullah Al Ruwaished 2019
4:21

Ghair Elnas
Rashed AlMajid
Weily
6:04

رابح صقر و نوال الكوتية - كل ما في الامر | فبراير الكويت  2019 | Rabih Sagr & Nawal Al Kuwaitia
Turki Alalshikh
9:24

رابح صقر اللي ماخطر عالبال دمار 😭😭💔
رابحيات
9:42

Eshtagtilak
Assala
La Testaslem
4:36

عبدالله المانع || احب شمسك واحب ظلك / امنتك الله :( ♥️
🏛
4:05

يا ليل يا جامع على الود قلبين
نغمة وتر عمر
روائع
5:55

عبدالله المانع وعايض ياما حاولت الفراق
Abdulrhman
6:45

ماقلت لك
ماجد المهندس
ماقلت لك
5:11
أنا زعلت
نوال
نوال 2016, Vol. 1 & 2
4:00

Weelah
Rashid Al Majid
Nour Eini
3:56

Brwazt Taifak
Rashed Al Majid
Brwazt Taifak
6:26

ماجد المهندس - هدوء (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
5:03

Eid Al Nazhar
Rashed Al Majed
Eid Al Nazhar
4:39
ناقصك شي
سهم
سهم
5:00

تحبك روحي
ماجد المهندس
تحبك روحي
6:21

حي هذا الشوف
ماجد المهندس
حي هذا الشوف
7:04

رفوف الذكريات
ماجد المهندس و سهم
حفلة الثمامة الخاصة
5:18

Gal AlWadaa Live
Rashed Al Majed
Dubai 2020 Live
4:52
تحسب إنك
راشد الماجد
حفلة دبي 2016
4:58

Melyon Khater
Abdul Majeed Abdullah
Melyon Khater
3:50

Minho Gherak
Rabeh Saqer
Rabeh Saqer 2019
4:30

على كثر القصيد
رابح صقر
جلسة الرياض 2013
7:46
غرقان (Live)
راشد الماجد
جلسات وناسة 2010 (Live)
5:38

لك سوالف
برهان
لك سوالف
3:14

لي غاب حبيبي
Borhan
5:14

ليه جيت
سلطان خليفة
ليه جيت
4:17

برهان | عايش معي "عود وبيانو" حصرياً
Borhan
4:16

Fezi Lah Ya Ard
Abdul Majeed Abdullah
Esmaany 2015
4:52

بطلبك حاجه
ماجد المهندس
جلسات وناسه 2017 الجزء 5
5:54

الطواريق
عبدالمجيد عبدالله
جلسات وناسه 2017 الجزء 7
5:41

Bokra
Rashed Al Majid
جلسات وناسه 2017 الجزء 4
5:52
عيرتني بالشيب (Live)
راشد الماجد
جلسات وناسة 2010 (Live)
4:42

Gefn El Lail
Majid al Muhandis
Shahd El Horouf
5:14

Keef AlMesa
Majid al Muhandis
Keef AlMesa
4:20

Yally Ahebak Mout
Majid al Muhandis
Shahd El Horouf
5:49
انا للآن
ماجد المهندس
الدنيا دوارة, Vol. 1 & 2
4:50
علمي علمك
ماجد المهندس
منوعات غنائية من اشعار خالد المريخي
4:19
Rohi Tedommak
Se 2017, SE & 80t S9
Se 2017
5:31
يدي على قلبي
ماجد المهندس
الدنيا دوارة, Vol. 1 & 2
5:18

Besmela Ala Galbek
Majid al Muhandis
Akh Qalby
3:45
لو تزاعلنا
ماجد المهندس
الدنيا دوارة, Vol. 1 & 2
3:44

رغم البعاد
ماجد المهندس
رغم البعاد
5:12

أورق العمر
ماجد المهندس
أورق العمر
5:42

Hatek
Majid al Muhandis
Hatek
5:03

ياهو قوي
عصام كمال
ياهو قوي
4:43

Ahbes El Aabraat
Abdul Majeed Abdullah
El Khataya Aashar
5:54

Holm
Abdul Majeed Abdullah
Law Yom Ahad
3:57
مستحيل
انغام
راح تذكرني
3:16

Qeltah
Rabeh Saqer
Rabeh Saqer 2019
3:36
عذاب العاشقينا
راشد الماجد
حفلة دبي 2016
7:05
تفنن
راشد الماجد
حفلة دبي 2016
5:45

كل من حولي ابتعد
نغمة وتر عمر
الأعلى استماع
4:12

تطمن
مبهم
تطمن
2:04

Entitharak Saab
Majid al Muhandis
Majid Almuhandis 2015
5:06

Gerak F La
Majid al Muhandis
Gerak F La
4:06

وانت غايب كنت حاضر في النواظر
نغمة وتر عمر
الأعلى استماع
4:19

Ala Allah
Majid Al Mohandis
Ala Allah
4:39

Men Hagi Agher
Rashed Al Majid
Men Hagi Agher
4:39

Habibi Naterf
Rashed Al Majed
Habibi Naterf
6:10
انا آسف
ماجد المهندس
انا آسف
4:23
ودي أنسى
ماجد المهندس
الدنيا دوارة, Vol. 1 & 2
4:28
Mohami
Majid Almuhandis
Mohami
4:53

Shno Sayer
Nabeel Shuail
Shno Sayer
3:12

ترى ماهزني عمرٍ - دويتو عمر و ريانه ( عود ) | Tra Ma Hazzne - omar and ryanh 2020 حصرياً
نغمة وتر عمر
4:51

Wadaat Rouhi
Majid Al Mohandis
Wadaat Rouhi
4:36

Al Zaman
Rashed Al Majed
Al Zaman
4:54

عزيز في عيوني
نغمة وتر I عُمر
Single
4:38

Al Nas Tehlam
Rashed Al Majed
Al Nas Tehlam
5:06

Twassi Shai
Rashed AlMajid
Aghani Ala Al Oud Part 3
3:30

Ala Ya Waqat
Rashed AlMajid
Aghani Ala Al Oud Part 3
5:04
ساعات
راشد الماجد
أغاني على العود الجزء الرابع
4:02
تسلم عليك
عبد الله الرويشد
تسلم عليك
5:23

Bdait Ataab
Abdallah Al Rowaished
Abdullah Al Ruwaished 2019
4:41
حبينا بعض
عبد الله الرويشد
تسلم عليك
4:56

Wahshteni Sewaleefek
Rashed AlMajid
Aghani Ala Al Oud Part 1
4:19

روحي تحبك
Abdul Majeed Abdullah
5:52

سامحت جرحك
Majid Al Mohandis
4:56

تعبان
زايد الصالح
تعبان
4:27

الله يسامح قلبك
راشد الماجد
الله يسامح قلبك
4:36

بنلتقي (جلسات وناسه)
داليا
بنلتقي (جلسات وناسه)
6:40

Al Mesayeb
Mashael
Bent Aboy
4:13

Hala AlKaseer - Tanashi (Official Lyric Video) | (هالة القصير - طنشي - (حصرياً
Hala Al Kaseer
3:49

Abdul Majeed Abdullah ... Atbaak - Dubai 2016 | عبد المجيد عبد الله ... أتبعك - دبي 2016
Abdul Majeed Abdullah
5:28

Seket
Mohamed Nour
Wahshak Awi
3:10

La Zad
Abdul Majeed Abdullah
Melyon Khater
4:51

Aby Shourak
Rashed Al Majed
Aby Shourak
5:44

Alassad
Rashed Al Majed
Alassad
4:04

Tathekereen
Rashed Al Majid
Dubai Concert 2016
5:39

تصدقين
عبدالمجيد عبدالله
تصدقين
4:51

وداعتك قلبي / عبدالله المانع
Faisal B
5:07

ما للنجوم اوطان دام السما عيونك  - ماجد المهندس ♪
tqaseem ♪
6:39

كثير اللي
فهد الكبيسي
جلسة طرب
6:59

Tawhshni Wanta Bganbi
Galsat Tarab
Tawhshni Wanta Bganbi
6:15

Majid Almohandis Ft mohammed Abdo - Laytak maay Saher | ماجد المهندس و محمد عبده - ليتك معي ساهر
Majid Al Mohandis
6:25

ظروف الوقت
فيصل الساهم
ظروف الوقت
4:34

الواقع
عبدالله المانع
الواقع
3:37

Ezkerini
Majid Al Mohandis
Layali Februrair 2011
8:18

عبدالمجيد عبدالله - لا ما يكفيني (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
5:33
الأماني
عايض
الأماني
6:25
تحكي وتعيد ماعاد يفيد
Saleh 33
1:00

تحس فيني
عبدالله المانع
تحس فيني
3:24

فدوه لك الروح
ماجد المهندس
فدوه لك الروح
4:58
Abee3 Al Nas
Majid Al Mohandis
Single
4:35
يا هيه (Live)
راشد الماجد
جلسات وناسة 2010 (Live)
4:37
لا تهجي
انغام
راح تذكرني
4:33

جرحني حيل
داليا
جرحني حيل
3:48

شبيت ضو الذكريات وحكينا
نغمة وتر عمر
الأعلى استماع
3:59
ليلة عمر
ماجد المهندس
ليلة عمر
5:42

قهرني
داليا
قهرني
4:31

La Hedat Nafsee
Majid al Muhandis
Enjaneat
6:07
بعد ما ربك أنطاك (Live)
راشد الماجد
جلسات وناسة 2010 (Live)
8:07

Ensan Aktar
Abdul Majeed Abdullah
Ensan Aktar
4:39

ناديت
عبدالله المانع
ناديت
3:09

ياما حاولت
عبدالله المانع
ياما حاولت
3:23

Mazh
Angham
Mazh
3:00

أصيل أبو بكر & الملحن نواف عبدالله |  قصر حبك - صوت الخليج
droob6rb1
5:23

قبل ماتجرح
سلطان خليفة
قبل ماتجرح
4:43

Y Bad Mn Kam Wkaad
Rashed Al Majid
Y Bad Mn Kam Wkaad
4:32
على قدومك
ماجد المهندس
الدنيا دوارة, Vol. 1 & 2
4:25

مرت سنة
محمد عبده وعبد المجيد عبد الله
مرت سنه
4:24
الخسران
راشد الماجد & احمد الهرمي
الخسران
4:38

محمد عبده | توصيني على الكتمان .. وتبغى حبنا ما يبان ! HQ
Elite Music ايليت ميوزك
11:45

المحبة
عباس ابراهيم
لفتة
5:31

Qabel Nabaeid
Abdallah Al Rowaished
2008
5:31

Adawer
Angham
Mazh
5:41

Hattan Unofficial Version
Majid Al Mohandis
Hattan Unofficial Version
6:34

لا تعتقد
داليا
لا تعتقد
5:39

الله يكثر
فهد الكبيسي
أنت عشق
4:09

Tesmahi
Hamza Namira
Esmaani
3:23

أتخيل
فؤاد عبدالواحد
أتخيل
3:04

ترى الهوى
فهد الكبيسي
ترى الهوى
4:34

لا خط ولا هاتف
احمد الهرمي
جلسات وناسه 2017 الجزء 5
5:48

Yama Gelt Lak
Fahad Al Kubaisi
Yama Gelt Lak
4:06

المشكلة
وعد
المشكلة
4:17

Helm We Haeaaha
Majid Almohandis
Helm We Hakeeka
4:13
أبد يعني
رابح صقر
أبد يعني
12:06

Akhteet
Asmaa Lemnawer
Awsat Elnojoom
5:28

Akher Habib
Abdallah Al Rowaished
Watan Omri
5:52

ماجد المهندس انا مسير 🖤
ليان العلي
7:11

كان يا مكان
نوال
كان يا مكان
4:20

Ma Terhamlee
Marwan Mohammed
Ma Terhamlee
3:46

عزة نفسي
عبدالله المانع
عزة نفسي
3:54

برهان | نسيتك ! _ عود وبيانو "حصريا"
Borhan
4:11

متوله عليك
برهان
متوله عليك
3:50

Enta Maaya
Turki Abdullah
A7la Alfosool
4:53

Esha
Fouad Abdulwahed
Fouad Abdulwahed 2020
4:11

اعجبك في كل شي | عبدالمجيد عبدالله
FAHAD ARYT
6:02

Sodfa
Rabeh Saqer
Rabeh 2017
5:15

انا اصدق
فؤاد عبدالواحد
انا اصدق
8:14

تحبني
عبدالله المانع
تحبني
4:43

Akher Hobena
Nabeel Shuail
Kebir El Fan 2020
4:43

Kel Hezn
Waleed Alshami
Kel Hezn
6:04

البارت المحذوف من أغنية هتان - عيسى بن صالح
عيسى بن صالح
1:33

عصام كمال | على الذكرى .. ترى الميعاد باكر ..! HQ
Elite Music ايليت ميوزك
6:35

محبوب روحك
Abdullah Al Manea
مات الزمان
2:17

انسحب
عبدالرحمن البدر
انسحب
4:08

Md Alsneen
Abdullah Al Manea
Md Alsneen
5:41

Wesh Tabi
Rashed Al Majid
Wesh Tabi
5:54
عجزت اغفر
رابح صقر
رابح 2017, Vol. 1 & 2
5:36

Sayd Al Ahbab
Majid al Muhandis
Sayd Al Ahbab
3:35

أجمل غيمة - عبدالله المانع
الشاعر / ذهب
3:47

غروك عذالي
Abdullah Al Manea
صوتك يناديني
4:22

يا سيدي ( مع الكلمات ) - عبدالله المانع
Rula
3:22
إنتبه
ماجد المهندس
إنتبه
4:34
صرنا صلح
وائل كفوري
W.
3:39

Amaken El Sahar
Amr Diab
Amaken El Sahar
4:12

Salam
Tamer Ashour
ايام
3:22

Asameek Elketeera
Angham
Hala Khasa Gedan
3:12

Qesset Hob (Oriental Version)
Ramy Ayach
Qesset Hob
3:34

Mettamena
Angham
Hala Khasa Gedan
4:55

Hodna
Angham
Hala Khasa Gedan
5:18

Aintahaa Almishwar
Waleed Al Shami
Aintahaa Almishwar
3:24
Oufny
Sultan El Omani & Mostafa Ibrahim
Oufny
6:46
قالوا الحب
رابح صقر
رابح 2017, Vol. 1 & 2
5:29

Banaam
Majid Almuhandis
شهد الحروف: الجزء الثاني
5:27

مافي احد
راشد الماجد
مافي احد
4:59
تسيبني وتروح
ماجد المهندس
الدنيا دوارة, Vol. 1 & 2
4:20

Tabee Men Allah
Waleed Al Shami
Tabee Men Allah
5:54

Lahzat Haway
Majid al Muhandis
Shahd El Horouf
5:10

Shokran
Majid Almohandis
شكرا
4:56

La Tashtaki
Majid al Muhandis
La Tashtaki
4:13
عساك عالقوة
ماجد المهندس
الدنيا دوارة, Vol. 1 & 2
4:24

Qadi Gharami
Majid Almuhandis
شهد الحروف: الجزء الثاني
4:30

Mani Tabie
Majid al Muhandis
Akh Qalby
4:51

EL Rasaas
Rabeh Saqer
Awajeh Al Maana
4:56

Alsamt
Rabeh Saqer
Rabeh Saqer 2019
5:16
رجع الفرح
اصاله
مهتمه بالتفاصيل
5:10

Teslam Yedeenah
Angham
Mazh
4:00
لو تحلف
انغام
راح تذكرني
5:42

La Tezael
Abdallah Al Rowaished
Abdullah Al Ruwaished 2019
4:07

Tawla
Angham
Mazh
6:19

Etrek
Abdallah Al Rowaished
Abdullah Al Ruwaished 2019
4:31

Qamar Layli
Al Anean Ft Balqees
Ashyaa Wa Adad
4:32

Hatoul Lrabena Eh
Angham
Hala Khasa Gedan
4:01
Sanda Aleik
Angham
Sanda Aleik
4:52

Helw Alkalam
Ayed
Helw Alkalam
4:18

Farhety Feek
Ibrahim Al Hakmi
Farhety Feek
5:15
مشتاق لك ضامي
Angam
طربيات
3:04
ليه يادنيا
غنوة
طربيات كلاسيكية
6:02
بلا غيره بلا هم
Angam
طربيات
3:28
شفتك
غنوة
طربيات كلاسيكية
4:28
عامين احبك
Khaliji
خليجي استكنان
3:21

ما كنت أدري
راشد الماجد
ما كنت أدري
5:21

Serr Hobi
Majid Al-Muhandis
Namat Oyouni-Jalsah
4:33

مع الرأفه
فهد العمري
مع الرأفه
4:44

AlOyon Live
Rashed Al Majed
Dubai 2020 Live
5:53

جردت سيفك
عبدالمجيد عبدالله
جردت سيفك
4:45

انا عـشتك
برهان
انا عـشتك
3:34

ماسألتك
برهان
مـاسألتك
4:05

Ateeh Wagif
Abdul Majeed Abdullah
Ateeh Wagif
4:19

يا بعدهم
Abdul Majeed Abdullah
6:25

صريح بالكلمات
Abdullah Al Manea
اشتقت لك
3:20

صوتك يناديني
Abdullah Al Manea
صوتك يناديني
2:34

Naqadah
Rabeh Saqer
Marhaba
5:20

Abrak Al Saat
Rabeh Saqer
Marhaba
5:20

Adhak
Rabeh Saqer
Marhaba
3:50

Hala Beli
Rashed Al Majid
يا مرحبا الساع
5:12

گالب خلقته
ماجد المهندس
گالب خلقته
4:13
صاحي لهم
راشد الماجد
جلسات وناسة 2009
6:33
الله كريم
راشد الماجد
جلسات وناسة 2009
6:26

Khelst Khalas
Ahmed Batshan
Khelst Khalas
4:30

ياظالمه | عبد الله المانع
Faisal Bin saudS
4:07

Hekm El Alb
Wael Kfoury
Mdallaleti - Single
3:57

فيني انت
عصام كمال
هين
5:48

إلي كل من
عبدالعزيز الويس
إستثنائي
3:23

سر الاعجاب عجزت أغفر
Abdullah Al Manea
أبطى علي
3:16

Majid Al Mohandis ... Arsel Salamy - Video Clip | ماجد المهندس ... أرسل سلامي - كليب
Rotana
5:44

اهتم فيني | عبدالله المانع😍
A.A.A
2:54

عبدالله المانع - في امور
Fahad Sh
2:52

لا تصحي (جلسات وناسه)
رابح صقر
لا تصحي (جلسات وناسه)
4:30

رابح صقر عسى ما شر من روائع ابوصقر 👌🏾
رابحيات
6:56

Adri
Rashed Al Majid
Jalasat Wannasah 2013
5:21

End Al Lezoum
Rabeh Saqer
Marhaba
4:30

افهمك - عبدالله المانع
Ljn
5:14

Ashraat Ashiaa
Rabeh Saqer
Yehiqelak Jalsah
9:36

عبدالله المانع - سلام عيون
Abeer
3:16

Faqed Sheour
Rabeh Saqer
Marhaba
4:41

Mabalash
Hamaki
Omro M Yegheeb
4:09

زينة - اسمع كلامي | Cover by Zena - Esma3 kalami
Zena Emad
3:45

عاشقينك
راشد الماجد
عاشقينك
4:52

عبدالمجيد عبدالله - ماقدرت اصبر (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
5:03

Ejazt
Rabeh Saqer
Rabeh Saqer 2019
4:47

Fady Shewaya
Hamza Namira
Mawlood Sanat 80
3:52

لمين ابشكي غرامك
نغمة وتر عمر
الأعلى استماع
4:43

ميدلي ليلة السندباد - راشد الماجد (النسخة الأصلية) | 2020
Rashed Al-Majed
12:29

Al Farq Al Kabir
Assala
Al Farq Al Kabir
4:28

Hobbo Ganna - حبه جنة ( Cover ) | Sherine Abd El Wahab | By Menna Tarek
Menna tarek
3:49

بدونك
يزن السقاف
بدونك
5:42

عيد الحب
Sultan Khalifa
عيد الحب
4:50

برهان | أكيد (عود)
Borhan
3:54
أغلى حبيبة
راشد الماجد
حفلة دبي 2016
5:48

وليد الشامي -  ماانتظرتك (جلسات  وناسه) | 2017
 Tunes Arabia l تيونز أرابيا
8:10

لحظة (جلسات وناسه)
عبد الله الرويشد
لحظة (جلسات وناسه)

6:10
""";

class SongInfo {
  final String title;
  final String artist;
  SongInfo(this.title, this.artist);
  @override
  String toString() => "$artist - $title";
}

Future<void> main() async {
  print("Starting Import Script (Improved Parser)...");

  // 1. IMPROVED PARSE: Group lines into segments
  List<SongInfo> songs = [];
  final rawLines = rawText.split('\n').map((l) => l.trim()).toList();
  
  int i = 0;
  while (i < rawLines.length) {
    if (rawLines[i].isEmpty) {
      i++; continue;
    }
    
    // Attempt to grab Title and Artist
    String title = rawLines[i];
    String artist = (i + 1 < rawLines.length) ? rawLines[i+1] : "";
    
    // Heuristic: If artist looks like a duration (e.g. 4:29), it's not an artist
    if (RegExp(r'^\d+:\d+$').hasMatch(artist)) {
       // Single title line followed by duration? Unusual but skip
       i++; continue;
    }

    // Clean labels
    artist = artist.replaceAll(RegExp(r'\s?[\(\|].*?[\)\|\d].*'), '').trim();
    artist = artist.replaceFirst("Tunes Arabia l تيونز أرابيا", "").trim();
    title = title.replaceAll(RegExp(r'\s?[\(\|].*?[\)\|\d].*'), '').trim();
    title = title.replaceFirst("Tunes Arabia l تيونز أرابيا", "").trim();

    if (title.isNotEmpty && artist.isNotEmpty && !artist.contains(":") && !RegExp(r'^\d+$').hasMatch(artist)) {
       songs.add(SongInfo(title, artist));
       
       // Advance past this group
       // We skip the next 1-3 lines if they look like album/duration
       i += 2;
       while (i < rawLines.length && rawLines[i].isNotEmpty && 
              (RegExp(r'^\d+:\d+$').hasMatch(rawLines[i]) || i < i + 2)) {
          // If we see another potential title (no colon, etc.), we stop skipping
          // But usually we skip 2 more lines (context and duration)
          if (RegExp(r'^\d+:\d+$').hasMatch(rawLines[i])) {
             i++; break; // Stop after duration
          }
          i++;
          if (i > i + 4) break; // safety
       }
    } else {
      i++;
    }
  }

  print("Parsed ${songs.length} unique songs. Starting iTunes Search...");

  List<Map<String, dynamic>> results = [];
  int count = 0;
  var httpClient = http.Client();

  for (var song in songs) {
    count++;
    stdout.write("\rProgress: $count / ${songs.length} searching for ${song.title}...");
    
    bool found = false;
    
    // Strategy 1: Artist + Title
    final searchTerms = [
      "${song.artist} ${song.title}",
      song.title, // Fallback to just title (often helps if artist name is spelled differently)
    ];

    for (var query in searchTerms) {
      if (found) break;
      try {
        final uri = Uri.https('itunes.apple.com', '/search', {
          'term': query,
          'limit': '5',
          'media': 'music',
          'entity': 'song'
        });

        final response = await httpClient.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['resultCount'] > 0) {
            // Find best match in top 5
            var match = data['results'][0];
            
            // If we did a title-only search, check if artist matches loosely
            if (query == song.title) {
               bool artistMatch = false;
               for (var r in data['results']) {
                 final rArtist = r['artistName'].toString().toLowerCase();
                 final target = song.artist.toLowerCase();
                 if (rArtist.contains(target) || target.contains(rArtist)) {
                   match = r;
                   artistMatch = true;
                   break;
                 }
               }
               if (!artistMatch) continue; // Try next strategy or skip
            }

            String art = match['artworkUrl100'];
            art = art.replaceAll('100x100bb', '600x600bb');
            
            results.add({
              "id": "yt_${match['trackId']}",
              "title": song.title,
              "artist": song.artist,
              "title_itunes": match['trackName'],
              "artist_itunes": match['artistName'],
              "year": match['releaseDate'].toString().substring(0, 4),
              "link": match['previewUrl'],
              "artworkUrl": art,
              "styles": ["Pop"]
            });
            found = true;
          }
        }
      } catch (e) {
        // quiet
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  httpClient.close();
  print("\nDone! Found ${results.length} songs out of ${songs.length}.");

  final file = File('found_playlist_songs.json');
  await file.writeAsString(JsonEncoder.withIndent('  ').convert(results));
  print("Results saved to found_playlist_songs.json");
}
