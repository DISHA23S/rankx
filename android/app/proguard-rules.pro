# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep Razorpay specific classes that R8 is complaining about
-keep class com.razorpay.LifecycleContext { *; }
-keep class com.razorpay.PerformanceUtil { *; }
-keep class com.razorpay.BaseCheckoutActivity { *; }
-keep class com.razorpay.CheckoutUtils { *; }
-keep class com.razorpay.CheckoutOptions { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve annotations
-keepattributes *Annotation*

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile
