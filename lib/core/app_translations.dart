import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTranslations {
  static final ValueNotifier<String> localeNotifier = ValueNotifier<String>('en');

  static const Map<String, Map<String, String>> _translations = {
    // Navigation & Tabs
    'Home': {
      'en': 'Home',
      'bn': 'হোম',
      'hi': 'होम',
    },
    'Family': {
      'en': 'Family',
      'bn': 'পরিবার',
      'hi': 'परिवार',
    },
    'Settings': {
      'en': 'Settings',
      'bn': 'সেটিংস',
      'hi': 'सेटिंग्स',
    },
    'Rewards': {
      'en': 'Rewards',
      'bn': 'পুরস্কার',
      'hi': 'इनाम',
    },
    'Wallet': {
      'en': 'Wallet',
      'bn': 'ওয়ালেট',
      'hi': 'बटुवा',
    },
    'Profile': {
      'en': 'Profile',
      'bn': 'প্রোফাইল',
      'hi': 'प्रोफ़ाइल',
    },

    // Buttons
    'Add Task': {
      'en': 'Add Task',
      'bn': 'কাজ যোগ করুন',
      'hi': 'कार्य जोड़ें',
    },
    'Edit Profile': {
      'en': 'Edit Profile',
      'bn': 'প্রোফাইল সম্পাদনা করুন',
      'hi': 'प्रोफ़ाइल संपादित करें',
    },
    'Log Out': {
      'en': 'Log Out',
      'bn': 'লগ আউট',
      'hi': 'लॉग आउट करें',
    },
    'Save Changes': {
      'en': 'Save Changes',
      'bn': 'পরিবর্তন সংরক্ষণ করুন',
      'hi': 'परिवर्तन सहेजें',
    },
    'Approve & Pay': {
      'en': 'Approve & Pay',
      'bn': 'অনুমোদন ও পরিশোধ',
      'hi': 'मंजूर करें और भुगतान करें',
    },
    'Accept Task (Claim)': {
      'en': 'Accept Task (Claim)',
      'bn': 'কাজ গ্রহণ করুন (দাবি)',
      'hi': 'कार्य स्वीकार करें (दावा)',
    },
    'Submit for Approval': {
      'en': 'Submit for Approval',
      'bn': 'অনুমোদনের জন্য জমা দিন',
      'hi': 'मंजूरी के लिए सबमिट करें',
    },
    
    // Core Dashboard Texts
    'Total Family Allowance This Week': {
      'en': 'Total Family Allowance This Week',
      'bn': 'এই সপ্তাহের মোট পারিবারিক ভাতা',
      'hi': 'इस सप्ताह का कुल पारिवारिक भत्ता',
    },
    'Remaining Weekly Allowance': {
      'en': 'Remaining Weekly Allowance',
      'bn': 'অবশিষ্ট সাপ্তাহিক ভাতা',
      'hi': 'शेष साप्ताहिक भत्ता',
    },
    'Your Children': {
      'en': 'Your Children',
      'bn': 'আপনার সন্তানরা',
      'hi': 'आपके बच्चे',
    },
    'My Tasks': {
      'en': 'My Tasks',
      'bn': 'আমার কাজ',
      'hi': 'मेरे कार्य',
    },
    'Total Balance': {
      'en': 'Total Balance',
      'bn': 'মোট ব্যালেন্স',
      'hi': 'कुल शेष',
    },
    'Task Details': {
      'en': 'Task Details',
      'bn': 'কাজের বিবরণ',
      'hi': 'कार्य विवरण',
    },
    'Parents': {
      'en': 'Parents',
      'bn': 'পিতামাতা',
      'hi': 'माता-पिता',
    },

    // Settings & Profile
    'Preferences': {
      'en': 'Preferences',
      'bn': 'পছন্দসমূহ',
      'hi': 'प्राथमिकताएं',
    },
    'Language': {
      'en': 'Language',
      'bn': 'ভাষা',
      'hi': 'भाषा',
    },
    'Dark Mode': {
      'en': 'Dark Mode',
      'bn': 'ডার্ক মোড',
      'hi': 'डार्क मोड',
    },
    'Change Password': {
      'en': 'Change Password',
      'bn': 'পাসওয়ার্ড পরিবর্তন',
      'hi': 'पासवर्ड बदलें',
    },
    'Notifications': {
      'en': 'Notifications',
      'bn': 'বিজ্ঞপ্তি',
      'hi': 'सूचनाएं',
    },
    'Account': {
      'en': 'Account',
      'bn': 'অ্যাকাউন্ট',
      'hi': 'खाता',
    },
    'My Profile': {
      'en': 'My Profile',
      'bn': 'আমার প্রোফাইল',
      'hi': 'मेरी प्रोफ़ाइल',
    },
    
    // Alerts / Messages
    'Save': {
      'en': 'Save',
      'bn': 'সঞ্চয়',
      'hi': 'बचाएं',
    },
    'Spend': {
      'en': 'Spend',
      'bn': 'খরচ',
      'hi': 'खर्च',
    },
    'Give': {
      'en': 'Give',
      'bn': 'দান',
      'hi': 'दान',
    },
    'Today\'s Chores': {
      'en': 'Today\'s Chores',
      'bn': 'আজকের কাজ',
      'hi': 'आज के काम',
    },
    'Tasks completed': {
      'en': 'Tasks completed',
      'bn': 'কাজ সম্পন্ন হয়েছে',
      'hi': 'कार्य पूर्ण हुआ',
    },
    'Keep it up!': {
      'en': 'Keep it up!',
      'bn': 'চালিয়ে যান!',
      'hi': 'इसे जारी रखो!',
    },
    'Select Language': {
      'en': 'Select Language',
      'bn': 'ভাষা নির্বাচন করুন',
      'hi': 'भाषा चुनें',
    },
    'Cancel': {
      'en': 'Cancel',
      'bn': 'বাতিল করুন',
      'hi': 'रद्द करें',
    },
    'Delete Account': {
      'en': 'Delete Account',
      'bn': 'অ্যাকাউন্ট মুছুন',
      'hi': 'खाता हटाएं',
    },
    'Are you sure you want to delete your account? This action cannot be undone.': {
      'en': 'Are you sure you want to delete your account? This action cannot be undone.',
      'bn': 'আপনি কি নিশ্চিত যে আপনি আপনার অ্যাকাউন্ট মুছতে চান? এই পদক্ষেপ বাতিল করা যাবে না।',
      'hi': 'क्या आप वाकई अपना खाता हटाना चाहते हैं? इस कार्रवाई को पूर्ववत नहीं किया जा सकता है।',
    },
    'Delete': {
      'en': 'Delete',
      'bn': 'মুছুন',
      'hi': 'हटाएं',
    },
    'Request account deletion from your parent?': {
      'en': 'Request account deletion from your parent?',
      'bn': 'আপনার পিতামাতার কাছে অ্যাকাউন্ট মুছে ফেলার অনুরোধ করবেন?',
      'hi': 'क्या आप अपने माता-पिता से खाता हटाने का अनुरोध करना चाहते हैं?',
    },
    'Request': {
      'en': 'Request',
      'bn': 'অনুরোধ করুন',
      'hi': 'अनुरोध करें',
    },
    'Request sent to parent': {
      'en': 'Request sent to parent',
      'bn': 'পিতামাতার কাছে অনুরোধ পাঠানো হয়েছে',
      'hi': 'माता-पिता को अनुरोध भेजा गया',
    },
    'Approve Deletion': {
      'en': 'Approve Deletion',
      'bn': 'মুছে ফেলার অনুমোদন দিন',
      'hi': 'हटाने की मंजूरी दें',
    },
    'Deletion request pending': {
      'en': 'Deletion request pending',
      'bn': 'মুছে ফেলার অনুরোধ পেন্ডিং',
      'hi': 'हटाने का अनुरोध लंबित है',
    },
    'Deletion Approved': {
      'en': 'Deletion Approved',
      'bn': 'মুছে ফেলা অনুমোদিত',
      'hi': 'हटाना स्वीकृत',
    },
    'Reject Deletion': {
      'en': 'Reject Deletion',
      'bn': 'মুছে ফেলা বাতিল করুন',
      'hi': 'हटाना रद्द करें',
    },
  };

  static String get(String key) {
    final lang = localeNotifier.value;
    if (_translations.containsKey(key)) {
      return _translations[key]![lang] ?? key;
    }
    return key;
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language') ?? 'en';
      localeNotifier.value = savedLang;
    } catch(e) {
      // In case of exceptions during SharedPreferences
      debugPrint("Error loading language: $e");
    }
  }

  static Future<void> changeLanguage(String langCode) async {
    localeNotifier.value = langCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', langCode);
    } catch(e) {
      debugPrint("Error saving language: $e");
    }
  }
}

extension StringLocalization on String {
  String get tr => AppTranslations.get(this);
}
