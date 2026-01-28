import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Motareb Admin'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @addProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addProperty;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @amenitiesAndExtras.
  ///
  /// In en, this message translates to:
  /// **'Amenities & Extras ✨'**
  String get amenitiesAndExtras;

  /// No description provided for @rulesAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Rules & Conditions ⚠️'**
  String get rulesAndConditions;

  /// No description provided for @addCustomAmenity.
  ///
  /// In en, this message translates to:
  /// **'Add another amenity...'**
  String get addCustomAmenity;

  /// No description provided for @addCustomRule.
  ///
  /// In en, this message translates to:
  /// **'Add a new rule (e.g. No smoking)...'**
  String get addCustomRule;

  /// No description provided for @audienceAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Target Audience & Payment 🎯'**
  String get audienceAndPayment;

  /// No description provided for @males.
  ///
  /// In en, this message translates to:
  /// **'Males 👨'**
  String get males;

  /// No description provided for @females.
  ///
  /// In en, this message translates to:
  /// **'Females 👩'**
  String get females;

  /// No description provided for @paymentSystem.
  ///
  /// In en, this message translates to:
  /// **'Payment System'**
  String get paymentSystem;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @termly.
  ///
  /// In en, this message translates to:
  /// **'Per Term'**
  String get termly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @bookingSystem.
  ///
  /// In en, this message translates to:
  /// **'Booking System & Facilities 🛏️'**
  String get bookingSystem;

  /// No description provided for @unitSystem.
  ///
  /// In en, this message translates to:
  /// **'Unit System (By Room)'**
  String get unitSystem;

  /// No description provided for @bedSystem.
  ///
  /// In en, this message translates to:
  /// **'Bed System (By Bed)'**
  String get bedSystem;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @fullApartmentBooking.
  ///
  /// In en, this message translates to:
  /// **'Book Entire Apartment Only 🏠'**
  String get fullApartmentBooking;

  /// No description provided for @fullApartmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When enabled, student won\'t be able to select specific rooms'**
  String get fullApartmentSubtitle;

  /// No description provided for @roomDetails.
  ///
  /// In en, this message translates to:
  /// **'Room Details'**
  String get roomDetails;

  /// No description provided for @roomDetailsNote.
  ///
  /// In en, this message translates to:
  /// **'Note: These details are for information only, booking is for the whole apartment'**
  String get roomDetailsNote;

  /// No description provided for @noRoomsAdded.
  ///
  /// In en, this message translates to:
  /// **'No rooms added yet'**
  String get noRoomsAdded;

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add Room'**
  String get addRoom;

  /// No description provided for @totalBedsCount.
  ///
  /// In en, this message translates to:
  /// **'Total Beds Count'**
  String get totalBedsCount;

  /// No description provided for @roomsCount.
  ///
  /// In en, this message translates to:
  /// **'Rooms Count'**
  String get roomsCount;

  /// No description provided for @roomTypeDescription.
  ///
  /// In en, this message translates to:
  /// **'Room Type (General Description)'**
  String get roomTypeDescription;

  /// No description provided for @expectedBedPrice.
  ///
  /// In en, this message translates to:
  /// **'Expected Bed Price:'**
  String get expectedBedPrice;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currency;

  /// No description provided for @singleRoom.
  ///
  /// In en, this message translates to:
  /// **'Single Room'**
  String get singleRoom;

  /// No description provided for @doubleRoom.
  ///
  /// In en, this message translates to:
  /// **'Double Room (2 Beds)'**
  String get doubleRoom;

  /// No description provided for @tripleRoom.
  ///
  /// In en, this message translates to:
  /// **'Triple Room (3 Beds)'**
  String get tripleRoom;

  /// No description provided for @customRoom.
  ///
  /// In en, this message translates to:
  /// **'Custom Room'**
  String get customRoom;

  /// No description provided for @editRoom.
  ///
  /// In en, this message translates to:
  /// **'Edit Room Details'**
  String get editRoom;

  /// No description provided for @roomPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Room Price'**
  String get roomPrice;

  /// No description provided for @bedPrice.
  ///
  /// In en, this message translates to:
  /// **'Single Bed Price'**
  String get bedPrice;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @numBeds.
  ///
  /// In en, this message translates to:
  /// **'Number of Beds'**
  String get numBeds;

  /// No description provided for @bedModeDescription.
  ///
  /// In en, this message translates to:
  /// **'In this system, the price is calculated per bed. The total property price will be divided by the number of beds.'**
  String get bedModeDescription;

  /// No description provided for @addNewRoom.
  ///
  /// In en, this message translates to:
  /// **'Add New Room'**
  String get addNewRoom;

  /// No description provided for @roomType.
  ///
  /// In en, this message translates to:
  /// **'Room Type'**
  String get roomType;

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @double.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get double;

  /// No description provided for @triple.
  ///
  /// In en, this message translates to:
  /// **'Triple'**
  String get triple;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @bedsInRoom.
  ///
  /// In en, this message translates to:
  /// **'Beds in Room'**
  String get bedsInRoom;

  /// No description provided for @enterNumBeds.
  ///
  /// In en, this message translates to:
  /// **'Enter number of beds'**
  String get enterNumBeds;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @nearbyUniversities.
  ///
  /// In en, this message translates to:
  /// **'Nearby Universities 🎓'**
  String get nearbyUniversities;

  /// No description provided for @addCustomUniversity.
  ///
  /// In en, this message translates to:
  /// **'Add new university (specific to this property)...'**
  String get addCustomUniversity;

  /// No description provided for @universityAdded.
  ///
  /// In en, this message translates to:
  /// **'University added to property ✅'**
  String get universityAdded;

  /// No description provided for @universityAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This university is already added ⚠️'**
  String get universityAlreadyAdded;

  /// No description provided for @welcomeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Admin 👋'**
  String get welcomeAdmin;

  /// No description provided for @adminSubHeader.
  ///
  /// In en, this message translates to:
  /// **'You have full control to manage the application.'**
  String get adminSubHeader;

  /// No description provided for @manageReservations.
  ///
  /// In en, this message translates to:
  /// **'Manage all bookings'**
  String get manageReservations;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @technicalSupport.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get technicalSupport;

  /// No description provided for @newPropertyPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish new property'**
  String get newPropertyPublish;

  /// No description provided for @publicationRequests.
  ///
  /// In en, this message translates to:
  /// **'Publication Requests'**
  String get publicationRequests;

  /// No description provided for @reviewAcceptProperties.
  ///
  /// In en, this message translates to:
  /// **'Review & Accept properties'**
  String get reviewAcceptProperties;

  /// No description provided for @allApartments.
  ///
  /// In en, this message translates to:
  /// **'All Apartments'**
  String get allApartments;

  /// No description provided for @manageEditAll.
  ///
  /// In en, this message translates to:
  /// **'Manage & Edit everything'**
  String get manageEditAll;

  /// No description provided for @manageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get manageAccounts;

  /// No description provided for @universities.
  ///
  /// In en, this message translates to:
  /// **'Universities'**
  String get universities;

  /// No description provided for @manageUniversities.
  ///
  /// In en, this message translates to:
  /// **'Manage Universities'**
  String get manageUniversities;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @identityRequests.
  ///
  /// In en, this message translates to:
  /// **'Identity verification requests'**
  String get identityRequests;

  /// No description provided for @numbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get numbers;

  /// No description provided for @manageContactNumbers.
  ///
  /// In en, this message translates to:
  /// **'Manage contact numbers'**
  String get manageContactNumbers;

  /// No description provided for @propertyImages.
  ///
  /// In en, this message translates to:
  /// **'Property Images 📸'**
  String get propertyImages;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @propertyVideoOptional.
  ///
  /// In en, this message translates to:
  /// **'Property Video (Optional) 🎥'**
  String get propertyVideoOptional;

  /// No description provided for @videoUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video uploaded successfully ✅'**
  String get videoUploadedSuccess;

  /// No description provided for @uploadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading video...'**
  String get uploadingVideo;

  /// No description provided for @clickToUploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Click to upload video'**
  String get clickToUploadVideo;

  /// No description provided for @enterPropertyIdFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter property number first! ⚠️'**
  String get enterPropertyIdFirst;

  /// No description provided for @cannotUploadDuplicateId.
  ///
  /// In en, this message translates to:
  /// **'❌ Cannot upload: Serial already exists'**
  String get cannotUploadDuplicateId;

  /// No description provided for @imageDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image deleted successfully 🗑️'**
  String get imageDeleteSuccess;

  /// No description provided for @videoDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video deleted successfully 🗑️'**
  String get videoDeleteSuccess;

  /// No description provided for @ads.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get ads;

  /// No description provided for @manageAds.
  ///
  /// In en, this message translates to:
  /// **'Manage Ads and Spaces'**
  String get manageAds;

  /// No description provided for @addAd.
  ///
  /// In en, this message translates to:
  /// **'Add Ad or Space'**
  String get addAd;

  /// No description provided for @adName.
  ///
  /// In en, this message translates to:
  /// **'Place / Ad Name'**
  String get adName;

  /// No description provided for @adDescription.
  ///
  /// In en, this message translates to:
  /// **'Ad Description'**
  String get adDescription;

  /// No description provided for @adAddress.
  ///
  /// In en, this message translates to:
  /// **'Detailed Address'**
  String get adAddress;

  /// No description provided for @adType.
  ///
  /// In en, this message translates to:
  /// **'Ad Type / Category'**
  String get adType;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @whatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get whatsappNumber;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status (Active)'**
  String get activeStatus;

  /// No description provided for @translateToEn.
  ///
  /// In en, this message translates to:
  /// **'Translate to English'**
  String get translateToEn;

  /// No description provided for @adImages.
  ///
  /// In en, this message translates to:
  /// **'Place / Ad Images 📸'**
  String get adImages;

  /// No description provided for @pickType.
  ///
  /// In en, this message translates to:
  /// **'Pick Type'**
  String get pickType;

  /// No description provided for @nameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get nameAr;

  /// No description provided for @nameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get nameEn;

  /// No description provided for @descAr.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic)'**
  String get descAr;

  /// No description provided for @descEn.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get descEn;

  /// No description provided for @addrAr.
  ///
  /// In en, this message translates to:
  /// **'Address (Arabic)'**
  String get addrAr;

  /// No description provided for @addrEn.
  ///
  /// In en, this message translates to:
  /// **'Address (English)'**
  String get addrEn;

  /// No description provided for @sponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored Ad'**
  String get sponsored;

  /// No description provided for @banner.
  ///
  /// In en, this message translates to:
  /// **'Ad Banner'**
  String get banner;

  /// No description provided for @localStore.
  ///
  /// In en, this message translates to:
  /// **'Local Store / Restaurant'**
  String get localStore;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @noAdsFound.
  ///
  /// In en, this message translates to:
  /// **'No ads found yet'**
  String get noAdsFound;

  /// No description provided for @deleteAd.
  ///
  /// In en, this message translates to:
  /// **'Delete Ad'**
  String get deleteAd;

  /// No description provided for @deleteAdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this ad? This action cannot be undone.'**
  String get deleteAdConfirm;

  /// No description provided for @editAd.
  ///
  /// In en, this message translates to:
  /// **'Edit Ad'**
  String get editAd;

  /// No description provided for @googleMapLink.
  ///
  /// In en, this message translates to:
  /// **'Google Map Location Link'**
  String get googleMapLink;

  /// No description provided for @enterGoogleMapLink.
  ///
  /// In en, this message translates to:
  /// **'Paste Google Maps link here (optional)'**
  String get enterGoogleMapLink;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
