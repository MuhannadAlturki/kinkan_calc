# حاسبة كنكان — دليل المشروع لـ Claude

## معلومات أساسية
- **اسم المشروع:** حاسبة كنكان (Kinkan Calc)
- **المسار:** `C:\Users\altur\kinkan_calc`
- **اللغة:** Flutter / Dart
- **المنصات المستهدفة:** Android + Windows
- **صاحب المشروع:** Muhannad Alturki

## قواعد العمل
- بعد كل تعديل على الكود، سوّ `git commit` بوصف **عربي** يعكس التغيير
- بعد الـ commit، سوّ `git push origin master` عشان يُبنى APK تلقائياً
- الكود كله في ملف واحد: `lib/main.dart`
- **إذا سأل المستخدم سؤالاً، جاوب فقط ولا تنفّذ أي شيء** — نفّذ فقط عند الأمر الصريح

## البنية والكلاسات الرئيسية

### كلاسات البيانات
- **`Player`** — لاعب له `name`, `score`, `out` (خرج من اللعبة)
- **`Round`** — جولة أو حدث. `isEvent` = true لو كانت إضافة/حذف لاعب وليست جولة حقيقية
- **`GameRecord`** — سجل لعبة كاملة: `players`, `limit`, `rounds`, `finalScores`, `durationSeconds`
- **`_RolesData`** — يحتوي `silent` (الساكتون) و`winners` (الفائزون) لجولة واحدة

### كلاسات التخزين
- **`SavedGames`** — حفظ وتحميل الألعاب من `SharedPreferences`
- **`SavedNames`** — أسماء اللاعبين المحفوظة للاقتراح
- **`ThemeManager`** — حفظ الوضع الداكن/الفاتح
- **`StatsManager`** — تاريخ إعادة تعيين الإحصائيات

### الشاشات
- **`PlayerSetupScreen`** — شاشة البداية لإدخال أسماء اللاعبين وحد النقاط
- **`GameScreen`** — شاشة اللعبة الرئيسية (الأطول والأهم)
- **`RoundsHistoryScreen`** — سجل جولات اللعبة الحالية
- **`HistoryScreen`** — سجل جميع الألعاب السابقة
- **`TopWinnersScreen`** — شاشة الإحصائيات والترتيب
- **`GameDetailScreen`** — تفاصيل لعبة محفوظة

### Widgets مهمة
- **`_EditPlayersSheet`** — ورقة تعديل اللاعبين: تدعم إضافة، حذف، وإعادة ترتيب بالسحب والإفلات
- **`_GameSettingsSheet`** — ورقة إعدادات اللعبة (حد النقاط، النوع)
- **`_PlayerEntry`** — يوحّد اللاعبين الموجودين والجدد في ورقة التعديل (`originalName == null` يعني لاعب جديد)
- **`_PlayerAdditionCard`** — بطاقة حمراء/خضراء تظهر في السجل عند إضافة لاعب
- **`_PlayerRemovalCard`** — بطاقة حمراء تظهر في السجل عند حذف لاعب
- **`PlayerAvatar`** — أفاتار اللاعب بلون مخصص حسب ترتيبه

## منطق مهم

### الساكتون والفائزون
- دالة `_sortByCircularOrder` تعتمد على ترتيب `widget.players` لتحديد الساكتين
- ترتيب اللاعبين في `widget.players` **يؤثر على النتيجة** — لذلك إعادة الترتيب في `_EditPlayersSheet` مهمة
- `_applyPlayerEdits(renames, newPlayers, finalOrder)` تطبّق التعديلات وتُعيد ترتيب `widget.players`

### نقطة بداية اللاعب الجديد
```dart
final startingScore = maxScore > 0 ? maxScore + 1 : 0;
```
لو كل اللاعبين عند 0، اللاعب الجديد يبدأ من 0 أيضاً.

### الجولات مقابل الأحداث
- `r.isEvent` = true → إضافة أو حذف لاعب (لا تُحسب في عدد الجولات ولا في المجاميع)
- `_realRoundsCount` يستخدم `!r.isEvent`
- `_recalcTotals` يتخطى الأحداث بـ `if (r.isEvent) continue`

### حذف لاعب
- اللاعبون في `widget.players` غير الموجودين في `finalOrder` يُعتبرون محذوفين
- يُسجَّل الحذف كـ `Round(isPlayerRemoval: true, removedPlayers: [...])`

## GitHub Actions (بناء APK تلقائياً)
- الملف: `.github/workflows/build-apk.yml`
- يُشغَّل تلقائياً عند كل `push` على `master`
- ينتج APK في Artifacts باسم `kinkan-calc-apk`
- Flutter version: `3.32.4` (مطابق للنسخة المحلية)
- للتنزيل: `https://github.com/MuhannadAlturki/kinkan_calc/actions`

## الحزم المستخدمة
```yaml
confetti: ^0.7.0          # احتفال عند الفوز
fl_chart: ^0.68.0         # الرسم البياني في الإحصائيات
share_plus: ^9.0.0        # مشاركة نتائج الألعاب
google_fonts: ^6.2.1      # خط Cairo
shared_preferences: ^2.2.2 # حفظ البيانات محلياً
uuid: ^4.3.3              # معرّف فريد لكل لعبة
flutter_localizations     # دعم اللغة العربية
```

## ما تم إنجازه
- [x] إعادة ترتيب اللاعبين بالسحب والإفلات في ورقة التعديل
- [x] حذف لاعب من اللعبة مع تسجيله في السجل
- [x] تسجيل إضافة/حذف اللاعبين في سجل اللعبة
- [x] نقطة بداية صحيحة للاعب الجديد (0 لو الجميع عند 0)
- [x] إزالة أزرار الحذف الجماعي (الإحصائيات والسجل)
- [x] متوسط النقاط لكل لاعب في الإحصائيات (مع استبعاد النقاط الشاذة)
- [x] أطول سلسلة فوز لكل لاعب في الإحصائيات
- [x] GitHub Actions لبناء APK تلقائياً
