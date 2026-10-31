# Smart Match Pro

دليل عربي تفاعلي لتوفيقات قطع غيار الهواتف. هذا المستودع يحتوي على تطبيق Android بسيط يفتح معاينة Smart Match Pro محليًا داخل WebView.

## ما الموجود

- واجهة عربية RTL متجاوبة.
- بحث وتصنيف تجريبي، مفضلة، سجل، مقارنة، إدارة مخزون، بلاغات، إعدادات ونسخ احتياطي محلي.
- بيانات العرض أمثلة مصطنعة فقط، وليست توصيات تركيب أو بيانات توافق موثقة.
- لا يوجد خادم مزامنة أو قاعدة توافق حقيقية في هذه المعاينة.

## بناء APK

يتطلب Android SDK وJDK 17 وGradle 8.9. المشروع يستخدم Android Gradle Plugin 8.7.3 ويستهدف Android 14 (API 34) مع compileSdk 35.

من جذر المستودع:

```sh
gradle assembleDebug
```

ينتج APK تحت `app/build/outputs/apk/debug/app-debug.apk`.

## ملفات التطبيق

- `app/src/main/assets/index.html`: الواجهة والوظائف المحلية.
- `app/src/main/java/com/smartmatchpro/preview/MainActivity.java`: حاوية WebView مع اختيار الصور.
- `app/src/main/AndroidManifest.xml`: إعدادات التطبيق.
