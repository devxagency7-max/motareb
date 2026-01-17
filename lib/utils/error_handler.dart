import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'البريد الإلكتروني مسجل بالفعل. حاول تسجيل الدخول.';
        case 'invalid-email':
          return 'صيغة البريد الإلكتروني غير صحيحة.';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً. استخدم كلمة مرور أقوى.';
        case 'user-not-found':
          return 'هذا الحساب غير مسجل. يرجى إنشاء حساب جديد.';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة. حاول مرة أخرى.';
        case 'user-disabled':
          return 'تم تعطيل هذا الحساب.';
        case 'too-many-requests':
          return 'محاولات كثيرة خاطئة. يرجى المحاولة لاحقاً.';
        case 'operation-not-allowed':
          return 'تسجيل الدخول غير مفعل حالياً.';
        case 'network-request-failed':
          return 'لا يوجد اتصال بالإنترنت. تحقق من اتصالك.';
        case 'credential-already-in-use':
          return 'بيانات الاعتماد هذه مرتبطة بحساب آخر.';
        default:
          return 'حدث خطأ في المصادقة: ${error.message}';
      }
    } else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }
}
