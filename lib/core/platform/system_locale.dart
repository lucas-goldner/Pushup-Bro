export 'package:intl/intl_standalone.dart'
    if (dart.library.js_interop) 'package:intl/intl_browser.dart'
    show findSystemLocale;
