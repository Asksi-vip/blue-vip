<?php
/**
 * Blue VIP — إعدادات عامة للـ PHP (API + لوحة الإدارة).
 * عدّل APP_API_URL في التطبيق (app/lib/config.dart) ليطابق رابط هذا المجلد.
 */

// ظهور الأخطاء — أطفئه في الإنتاج (غيّر إلى 0)
ini_set('display_errors', '0');
error_reporting(E_ALL);

// المنطقة الزمنية للمباريات والتواريخ
date_default_timezone_set('Asia/Baghdad');
