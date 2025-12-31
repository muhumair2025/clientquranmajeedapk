import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // App Information
  String get appTitle;
  String get appDescription;

  // Navigation & Menu Items
  String get home;
  String get quranNavigation;
  String get search;
  String get settings;
  String get aboutUs;
  String get helpSupport;
  String get feedback;

  // Main Screen Titles
  String get otherTools;
  String get documents;
  String get audioDownloads;
  String get videoDownloads;
  String get quranMajeed;
  String get more;
  String get latest;
  String get live;

  // Home Page Cards (Core content - keep in Pashto)
  String get aqeedah;
  String get aqeedahSubtitle;
  String get tafseerTranslation;
  String get tafseerSubtitle;
  String get fiqh;
  String get fiqhSubtitle;
  String get hadith;
  String get hadithSubtitle;
  String get questionAnswer;
  String get questionAnswerSubtitle;
  String get books;
  String get booksSubtitle;
  
  // New Home Page Cards
  String get seerahHistory;
  String get seerahHistorySubtitle;
  String get scientificCourses;
  String get scientificCoursesSubtitle;
  String get ethicsManners;
  String get ethicsMannersSubtitle;
  String get adhkarDuas;
  String get adhkarDuasSubtitle;
  String get variousStatements;
  String get variousStatementsSubtitle;

  // Quran Navigation
  String get quranKareem;
  String get surahs;
  String get paras;
  String get searchSurahPara;
  String get searchHint;

  // Quran Search
  String get quranSearch;
  String get textSearch;
  String get directNavigation;
  String get searchInArabicText;
  String get searchPlaceholder;
  String get smartSearchSystem;
  String get searchFeatures;
  String get noResultsFound;
  String get tryDifferentText;
  String get selectSurahFirst;
  String get enterAyahNumber;
  String get navigate;
  String get ayahNumberRange;
  String get selectSurah;

  // Quran Reader
  String get loading;
  String get ayah;
  String get page;
  String get surah;
  String get para;
  String get fontSize;
  String get fontFamily;
  String get lineSpacing;
  String get wordSpacing;

  // Download Screens
  String get downloadAudio;
  String get downloadVideo;
  String get downloaded;
  String get notDownloaded;
  String get downloading;
  String get downloadFailed;
  String get downloadSuccess;
  String get downloadCancelled;
  String get retry;
  String get cancel;
  String get delete;
  String get play;
  String get pause;
  String get stop;

  // Error Messages & Dialogs
  String get error;
  String get warning;
  String get information;
  String get success;
  String get ok;
  String get cancelButton;
  String get yes;
  String get no;
  String get confirm;
  String get dismiss;

  // Common UI Elements
  String get next;
  String get previous;
  String get close;
  String get back;
  String get save;
  String get edit;
  String get update;
  String get refresh;
  String get reset;
  String get clear;
  String get select;
  String get deselect;
  String get selectAll;
  String get deselectAll;

  // Status Messages
  String get dataLoading;
  String get dataLoaded;
  String get dataError;
  String get noDataFound;
  String get networkError;
  String get connectionError;
  String get serverError;
  String get unknownError;

  // Settings
  String get language;
  String get theme;
  String get darkMode;
  String get lightMode;
  String get systemTheme;
  String get notifications;
  String get privacy;
  String get termsConditions;
  String get version;
  String get appearance;

  // Quran Specific
  String get bismillah;
  String get verse;
  String get verses;
  String get chapter;
  String get chapters;
  String get juz;
  String get hizb;
  String get ruku;
  String get sajda;
  String get makki;
  String get madani;

  // Media Options
  String get lughatText;
  String get lughatAudio;
  String get lughatVideo;
  String get tafseerText;
  String get tafseerAudio;
  String get tafseerVideo;
  String get faidiText;
  String get faidiAudio;
  String get faidiVideo;
  String get comingSoon;
  String get notAvailable;

  // Time & Date
  String get today;
  String get yesterday;
  String get tomorrow;
  String get thisWeek;
  String get thisMonth;
  String get thisYear;

  // General Messages
  String get underDevelopment;
  String get featureNotAvailable;
  String get pleaseWait;
  String get tryAgain;
  String get somethingWentWrong;

  // Language Switcher
  String get selectLanguage;
  String get languageChanged;
  String get restartRequired;
  String get changeLanguage;
  String get currentLanguage;

  // Search Related
  String get searchResults;
  String get searchTerm;
  String get searchEmpty;
  String get searchLoading;
  String get searchCompleted;
  String get matchFound;
  String get matchesFound;
  String get relevanceScore;

  // File Operations
  String get fileNotFound;
  String get fileCorrupted;
  String get fileSize;
  String get downloadProgress;
  String get downloadCompleted;
  String get storagePermission;
  String get insufficientStorage;

  // Accessibility
  String get accessibilityLabel;
  String get semanticLabel;
  String get hint;
  String get tooltip;

  // Tools Screen
  String get islamicTools;
  String get qiblaFinder;
  String get qiblaFinderDesc;
  String get calibrateCompass;
  String get movePhoneFigure8;
  String get skipCalibration;
  String get qiblaDirection;
  String get distanceToMakkah;
  String get compassActive;
  String get permissionsRequired;
  String get enablePermissions;
  String get prayerTimes;
  String get prayerTimesDesc;
  String get tasbeehCounter;
  String get tasbeehCounterDesc;
  String get hijriCalendar;
  String get hijriCalendarDesc;
  String get namesOfAllah;
  String get namesOfAllahDesc;
  String get islamicQuotes;
  String get islamicQuotesDesc;
  String get duaCollection;
  String get duaCollectionDesc;
  String get zakat;
  String get zakatDesc;

  // Modal and Dialog Content
  String get verseOptions;
  String get verseVocabulary;
  String get verseCommentary;
  String get verseBenefits;
  String get text;
  String get audio;
  String get video;
  String get fontSettings;
  String get arabicTextFont;
  String get downloadIssue;
  String get downloadedFileDeleted;
  
  // Ayah Modal Settings
  String get ayahModalSettings;
  String get showArabicText;
  String get showTranslation;
  String get arabicFont;
  String get translationFont;
  String get arabicFontSize;
  String get translationFontSize;
  String get adjustSettings;

  // Additional localization strings
  String get downloads;
  String get reserved;
  String get downloadContent;
  String get vocabularyDescription;
  String get commentaryDescription;
  String get benefitsDescription;
  String get verseVocabularyTitle;
  String get vocabularyTextNotAvailable;
  String get vocabularyAudioNotAvailable;
  String get vocabularyVideoNotAvailable;

  // Error messages for media viewers
  String get audioPlaybackError;
  String get videoPlaybackError;
  String get downloadError;
  String get networkConnectionError;
  String get filePermissionError;
  String get insufficientSpaceError;
  String get unsupportedFormatError;
  String get fileNotFoundError;

  // Success messages
  String get audioDownloadSuccess;
  String get videoDownloadSuccess;
  String get fileDeletedSuccess;

  // Download status messages
  String get audioNotDownloaded;
  String get videoNotDownloaded;
  String get downloadInProgress;
  String get downloadCancelledStatus;
  String get audioDownloaded;
  String get videoDownloaded;

  // Empty state messages
  String get noAudioDownloads;
  String get noVideoDownloads;
  String get downloadAudiosFromVerses;
  String get downloadVideosFromVerses;

  // Verse-specific messages (removed duplicates)

  // Para-related
  String get paraNumber;
  String get paraLabel;
  String get videosCount;
  String get audiosCount;
  String get ayahsCount;

  // Font settings specific
  String get textSizeLabel;
  String get fontTypeLabel;
  String get fontSizeSmall;
  String get fontSizeMedium;
  String get fontSizeLarge;
  String get fontSizeXLarge;

  // Media type labels
  String get vocabularyVideo;
  
  // Favorites functionality
  String get favorites;
  String get addedToFavorites;
  String get removedFromFavorites;
  String get noFavorites;
  String get addFavoritesFromReader;
  String get removeFavorite;
  String get removeFavoriteConfirm;
  String get remove;
  
  // Notes functionality
  String get addNote;
  String get noteSaved;
  String get noteRemoved;
  
  // Surah Modal
  String get searchByAyahNumber;
  String get totalAyahsInfo;
  String get noAyahsFound;
  
  // Bulk Audio Player
  String get bulkAudioPlayer;
  String get playbackSettings;
  String get fromAyah;
  String get toAyah;
  String get playbackMode;
  String get single;
  String get sequential;
  String get repeat;
  String get autoPlayNext;
  String get playingRange;
  String get number;
  
  // Latest Content Screen
  String get filter;
  String get clearFilter;
  String get loadingLatestContent;
  String get failedToLoadLatest;
  String get noNewContent;
  String get checkBackLater;
  String get newBadge;
  String get category;
  String get subcategory;
  String get ayahAudio;
  String get ayahVideo;

  // Prayer Times Screen
  String get prayerTimesTitle;
  String get fajr;
  String get sunrise;
  String get dhuhr;
  String get asr;
  String get maghrib;
  String get isha;
  String get nextPrayer;
  String get timeRemaining;
  String get calculationMethod;
  String get selectMethod;
  String get enableNotifications;
  String get notificationSettings;
  String get prayerReminder;
  String get minutesBefore;
  String get refreshData;
  String get lastUpdated;
  String get offline;
  String get usingCachedData;
  String get locationNotAvailable;
  String get fetchingPrayerTimes;
  String get prayerTimesError;
  String get hijriDate;
  
  // Alarm strings
  String get alarmAtPrayerTime;
  String get alarmMinutesBefore;
  String get adhanSound;
  String get alarmRemoved;
  String get alarmSet;
  String get setAlarm;
  String get selectAdhanSound;
  String get builtInSounds;
  String get customSound;
  String get saveSelection;
  
  // Mushaf Download
  String get quranScript;
  String get downloadToReadQuran;
  String get openQuran;
  String get downloadScript;
  String get scriptReady;
  String get extractingFiles;
  String get downloadComplete;
  String get downloadFailing;
  String get accessDenied;
  String get fileNotAvailable;
  String get connectionTimeout;
  String get downloadTimeout;
  String get mushafScript;
  String get uthmaniScript;
  String get pages;
  
  // Content Screen
  String get contentNotAvailable;
  String get openPdf;
  String get pdfDownloaded;
  String get downloadPdf;
  String get items;
} 