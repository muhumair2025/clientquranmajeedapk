import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  // App Information
  @override
  String get appTitle => 'Quran Majeed';
  @override
  String get appDescription => 'Complete Quran with translation and commentary';

  // Navigation & Menu Items
  @override
  String get home => 'Home';
  @override
  String get quranNavigation => 'Quran Navigation';
  @override
  String get search => 'Search';
  @override
  String get settings => 'Settings';
  @override
  String get aboutUs => 'About Us';
  @override
  String get helpSupport => 'Help & Support';
  @override
  String get feedback => 'Feedback';

  // Main Screen Titles
  @override
  String get otherTools => 'Other Tools';
  @override
  String get documents => 'Documents';
  @override
  String get audioDownloads => 'Audio Downloads';
  @override
  String get videoDownloads => 'Video Downloads';
  @override
  String get quranMajeed => 'Quran Majeed';
  @override
  String get more => 'More';
  @override
  String get latest => 'Latest';

  // Home Page Cards (translated to English)
  @override
  String get aqeedah => 'Aqeedah';
  @override
  String get aqeedahSubtitle => 'Foundations of Islam';
  @override
  String get tafseerTranslation => 'Tafseer & Translation';
  @override
  String get tafseerSubtitle => 'Quran Commentary';
  @override
  String get fiqh => 'Fiqh';
  @override
  String get fiqhSubtitle => 'Islamic Jurisprudence';
  @override
  String get hadith => 'Hadith';
  @override
  String get hadithSubtitle => 'Prophetic Traditions';
  @override
  String get questionAnswer => 'Q & A';
  @override
  String get questionAnswerSubtitle => 'Your Questions';
  @override
  String get books => 'Books';
  @override
  String get booksSubtitle => 'Islamic Books';

  // Quran Navigation
  @override
  String get quranKareem => 'Quran Kareem';
  @override
  String get surahs => 'Chapters';
  @override
  String get paras => 'Parts';
  @override
  String get searchSurahPara => 'Search Surah/Para (Number, Name, English)';
  @override
  String get searchHint => 'Type to search...';

  // Quran Search
  @override
  String get quranSearch => 'Quran Search';
  @override
  String get textSearch => 'Text Search';
  @override
  String get directNavigation => 'Direct Navigation';
  @override
  String get searchInArabicText => 'Enter Arabic text from Quran...';
  @override
  String get searchPlaceholder => 'Enter Arabic text to search in Quran';
  @override
  String get smartSearchSystem => 'Smart Arabic Search System: Search only in Arabic text of Quran';
  @override
  String get searchFeatures => '• Diacritics missing or extra - no problem\n• Spacing issues - missing or extra spaces work fine\n• Text copied from other websites works perfectly\n• Only Arabic text is shown';
  @override
  String get noResultsFound => 'No results found';
  @override
  String get tryDifferentText => 'Try different Arabic text - make sure diacritics are not problematic';
  @override
  String get selectSurahFirst => 'First select a Surah, then enter verse number';
  @override
  String get enterAyahNumber => 'Enter verse number';
  @override
  String get navigate => 'Navigate';
  @override
  String get ayahNumberRange => 'Verse number must be between {min} and {max}';
  @override
  String get selectSurah => 'Select Surah';

  // Quran Reader
  @override
  String get loading => 'Loading...';
  @override
  String get ayah => 'Verse';
  @override
  String get page => 'Page';
  @override
  String get surah => 'Chapter';
  @override
  String get para => 'Part';
  @override
  String get fontSize => 'Font Size';
  @override
  String get fontFamily => 'Font Family';
  @override
  String get lineSpacing => 'Line Spacing';
  @override
  String get wordSpacing => 'Word Spacing';

  // Download Screens
  @override
  String get downloadAudio => 'Download Audio';
  @override
  String get downloadVideo => 'Download Video';
  @override
  String get downloaded => 'Downloaded';
  @override
  String get notDownloaded => 'Not Downloaded';
  @override
  String get downloading => 'Downloading...';
  @override
  String get downloadFailed => 'Download Failed';
  @override
  String get downloadSuccess => 'Download Success';
  @override
  String get downloadCancelled => 'Download Cancelled';
  @override
  String get retry => 'Retry';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get play => 'Play';
  @override
  String get pause => 'Pause';
  @override
  String get stop => 'Stop';

  // Error Messages & Dialogs
  @override
  String get error => 'Error';
  @override
  String get warning => 'Warning';
  @override
  String get information => 'Information';
  @override
  String get success => 'Success';
  @override
  String get ok => 'OK';
  @override
  String get cancelButton => 'Cancel';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';
  @override
  String get confirm => 'Confirm';
  @override
  String get dismiss => 'Dismiss';

  // Common UI Elements
  @override
  String get next => 'Next';
  @override
  String get previous => 'Previous';
  @override
  String get close => 'Close';
  @override
  String get back => 'Back';
  @override
  String get save => 'Save';
  @override
  String get edit => 'Edit';
  @override
  String get update => 'Update';
  @override
  String get refresh => 'Refresh';
  @override
  String get reset => 'Reset';
  @override
  String get clear => 'Clear';
  @override
  String get select => 'Select';
  @override
  String get deselect => 'Deselect';
  @override
  String get selectAll => 'Select All';
  @override
  String get deselectAll => 'Deselect All';

  // Status Messages
  @override
  String get dataLoading => 'Loading data...';
  @override
  String get dataLoaded => 'Data loaded';
  @override
  String get dataError => 'Data error';
  @override
  String get noDataFound => 'No data found';
  @override
  String get networkError => 'Network error';
  @override
  String get connectionError => 'Connection error';
  @override
  String get serverError => 'Server error';
  @override
  String get unknownError => 'Unknown error';

  // Settings
  @override
  String get language => 'Language';
  @override
  String get theme => 'Theme';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get lightMode => 'Light Mode';
  @override
  String get systemTheme => 'System Theme';
  @override
  String get notifications => 'Notifications';
  @override
  String get privacy => 'Privacy';
  @override
  String get termsConditions => 'Terms & Conditions';
  @override
  String get version => 'Version';

  // Quran Specific
  @override
  String get bismillah => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
  @override
  String get verse => 'Verse';
  @override
  String get verses => 'Verses';
  @override
  String get chapter => 'Chapter';
  @override
  String get chapters => 'Chapters';
  @override
  String get juz => 'Part';
  @override
  String get hizb => 'Hizb';
  @override
  String get ruku => 'Ruku';
  @override
  String get sajda => 'Sajda';
  @override
  String get makki => 'Makki';
  @override
  String get madani => 'Madani';

  // Media Options
  @override
  String get lughatText => 'Vocabulary - Text';
  @override
  String get lughatAudio => 'Vocabulary - Audio';
  @override
  String get lughatVideo => 'Vocabulary - Video';
  @override
  String get tafseerText => 'Commentary - Text';
  @override
  String get tafseerAudio => 'Commentary - Audio';
  @override
  String get tafseerVideo => 'Commentary - Video';
  @override
  String get faidiText => 'Benefits - Text';
  @override
  String get faidiAudio => 'Benefits - Audio';
  @override
  String get faidiVideo => 'Benefits - Video';
  @override
  String get comingSoon => 'Coming Soon';
  @override
  String get notAvailable => 'Not Available';

  // Time & Date
  @override
  String get today => 'Today';
  @override
  String get yesterday => 'Yesterday';
  @override
  String get tomorrow => 'Tomorrow';
  @override
  String get thisWeek => 'This Week';
  @override
  String get thisMonth => 'This Month';
  @override
  String get thisYear => 'This Year';

  // General Messages
  @override
  String get underDevelopment => 'This section is under development';
  @override
  String get featureNotAvailable => 'This feature is not available';
  @override
  String get pleaseWait => 'Please wait';
  @override
  String get tryAgain => 'Try again';
  @override
  String get somethingWentWrong => 'Something went wrong';

  // Language Switcher
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get languageChanged => 'Language changed';
  @override
  String get restartRequired => 'Restart required';
  @override
  String get changeLanguage => 'Change Language';
  @override
  String get currentLanguage => 'Current Language';

  // Search Related
  @override
  String get searchResults => 'Search Results';
  @override
  String get searchTerm => 'Search Term';
  @override
  String get searchEmpty => 'Enter something to search';
  @override
  String get searchLoading => 'Searching...';
  @override
  String get searchCompleted => 'Search completed';
  @override
  String get matchFound => 'Match found';
  @override
  String get matchesFound => 'Matches found';
  @override
  String get relevanceScore => 'Relevance Score';

  // File Operations
  @override
  String get fileNotFound => 'File not found';
  @override
  String get fileCorrupted => 'File corrupted';
  @override
  String get fileSize => 'File Size';
  @override
  String get downloadProgress => 'Download Progress';
  @override
  String get downloadCompleted => 'Download Completed';
  @override
  String get storagePermission => 'Storage Permission';
  @override
  String get insufficientStorage => 'Insufficient Storage';

  // Accessibility
  @override
  String get accessibilityLabel => 'Accessibility Label';
  @override
  String get semanticLabel => 'Semantic Label';
  @override
  String get hint => 'Hint';
  @override
  String get tooltip => 'Tooltip';

  // Modal and Dialog Content
  @override
  String get verseOptions => 'Verse Options';
  @override
  String get verseVocabulary => 'Verse Vocabulary:';
  @override
  String get verseCommentary => 'Verse Commentary:';
  @override
  String get verseBenefits => 'Verse Benefits:';
  @override
  String get text => 'Text';
  @override
  String get audio => 'Audio';
  @override
  String get video => 'Video';
  @override
  String get fontSettings => 'Font Settings';
  @override
  String get arabicTextFont => 'Arabic Text Font';
  @override
  String get downloadIssue => 'Download Issue';
  @override
  String get downloadedFileDeleted => 'Downloaded file deleted';

  // Error messages for media viewers
  @override
  String get audioPlaybackError => 'Audio playback error';
  @override
  String get videoPlaybackError => 'Video playback error';
  @override
  String get downloadError => 'Download error';
  @override
  String get networkConnectionError => 'Network connection error. Please check your internet connection and try again.';
  @override
  String get filePermissionError => 'File download permission not granted. Please check app settings.';
  @override
  String get insufficientSpaceError => 'Insufficient space on device. Please free up some space.';
  @override
  String get unsupportedFormatError => 'File format not supported. Try a different file.';
  @override
  String get fileNotFoundError => 'Requested file not found. It may have been removed from server.';

  // Success messages
  @override
  String get audioDownloadSuccess => 'Audio downloaded successfully';
  @override
  String get videoDownloadSuccess => 'Video downloaded successfully';
  @override
  String get fileDeletedSuccess => 'Downloaded file deleted successfully';

  // Download status messages
  @override
  String get audioNotDownloaded => 'Audio not downloaded';
  @override
  String get videoNotDownloaded => 'Video not downloaded';
  @override
  String get downloadInProgress => 'Downloading...';
  @override
  String get downloadCancelledStatus => 'Download cancelled';
  @override
  String get audioDownloaded => 'Audio downloaded';
  @override
  String get videoDownloaded => 'Video downloaded';

  // Empty state messages
  @override
  String get noAudioDownloads => 'No downloaded audio files';
  @override
  String get noVideoDownloads => 'No downloaded video files';
  @override
  String get downloadAudiosFromVerses => 'Download audio files from verses';
  @override
  String get downloadVideosFromVerses => 'Download video files from verses';

  // Verse-specific messages
  @override
  String get verseVocabularyTitle => 'Verse {verse} Vocabulary Commentary';
  @override
  String get vocabularyTextNotAvailable => 'Vocabulary commentary not available for this verse';
  @override
  String get vocabularyAudioNotAvailable => 'Vocabulary audio not available for this verse';
  @override
  String get vocabularyVideoNotAvailable => 'Vocabulary video not available for this verse';

  // Para-related
  @override
  String get paraNumber => 'Part {number}';
  @override
  String get paraLabel => 'Part';
  @override
  String get videosCount => '{count} videos';
  @override
  String get audiosCount => '{count} audios';
  @override
  String get ayahsCount => '{count} verses';

  // Font settings specific
  @override
  String get textSizeLabel => 'Text Size';
  @override
  String get fontTypeLabel => 'Font Type';
  @override
  String get fontSizeSmall => 'Small';
  @override
  String get fontSizeMedium => 'Medium';
  @override
  String get fontSizeLarge => 'Large';
  @override
  String get fontSizeXLarge => 'Extra Large';

  // Media type labels
  @override
  String get vocabularyVideo => 'Vocabulary - Video';
  
  // Favorites functionality
  @override
  String get favorites => 'Favorites';
  @override
  String get addedToFavorites => 'Added to favorites';
  @override
  String get removedFromFavorites => 'Removed from favorites';
  @override
  String get noFavorites => 'No favorite ayahs yet';
  @override
  String get addFavoritesFromReader => 'Add favorites from the Quran reader';
  @override
  String get removeFavorite => 'Remove Favorite';
  @override
  String get removeFavoriteConfirm => 'Are you sure you want to remove this ayah from favorites?';
  @override
  String get remove => 'Remove';
  
  // Notes functionality
  @override
  String get addNote => 'Add your note here...';
  @override
  String get noteSaved => 'Note saved';
  @override
  String get noteRemoved => 'Note removed';
  
  // Surah Modal
  @override
  String get searchByAyahNumber => 'Search by ayah number or text...';
  @override
  String get totalAyahsInfo => 'Total Ayahs';
  @override
  String get noAyahsFound => 'No ayahs found';
  
  // Bulk Audio Player
  @override
  String get bulkAudioPlayer => 'Bulk Audio Player';
  @override
  String get playbackSettings => 'Playback Settings';
  @override
  String get fromAyah => 'From Verse';
  @override
  String get toAyah => 'To Verse';
  @override
  String get playbackMode => 'Playback Mode';
  @override
  String get single => 'Single';
  @override
  String get sequential => 'Sequential';
  @override
  String get repeat => 'Repeat';
  @override
  String get autoPlayNext => 'Auto Play Next';
  @override
  String get playingRange => 'Playing Range';
  @override
  String get number => 'Number';

  // Additional localization strings
  @override
  String get downloads => 'Downloads';
  @override
  String get reserved => 'Reserved';
  @override
  String get downloadContent => 'Download Islamic content for offline access';
  @override
  String get vocabularyDescription => 'Word meanings and explanations';
  @override
  String get commentaryDescription => 'Detailed verse commentary';
  @override
  String get benefitsDescription => 'Spiritual benefits and lessons';

} 