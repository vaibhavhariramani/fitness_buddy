# flutter_local_notifications uses Gson reflection (TypeToken) to persist
# scheduled notifications to SharedPreferences. R8 strips the generic
# signatures that reflection needs unless these are kept, which throws
# "TypeToken must be created with a type argument" the first time the app
# calls cancel()/cancelAll() in a release build — silently breaking any
# caller that awaits it (see NotificationService.cancelWorkoutInProgress).
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-dontwarn com.google.gson.**
