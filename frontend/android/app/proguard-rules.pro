# Kakao Maps SDK accesses these classes and fields from native code by name.
# R8 must preserve them in release builds so JNI lookups remain valid.
-keep class com.kakao.vectormap.** { *; }
-keep interface com.kakao.vectormap.**
