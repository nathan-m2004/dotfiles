/** * SECURITY & PRIVACY 
 */
// Enable HTTPS-Only Mode
user_pref("dom.security.https_only_mode", true);

// Enable Fingerprinting Protection & Global Privacy Control
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.globalprivacycontrol.enabled", true);

// Enhanced Tracking Protection & Query Stripping (removes tracking params from URLs)
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.query_stripping.enabled", true);
user_pref("privacy.query_stripping.enabled.pbmode", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);

// Disable Safe Browsing (Google/Mozilla lookups) - Matches your current config
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);

// Network & Connectivity
user_pref("network.dns.disablePrefetch", true);
user_pref("network.prefetch-next", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.trr.mode", 2); // DNS over HTTPS (DoH) Enabled
user_pref("network.trr.uri", "https://mozilla.cloudflare-dns.com/dns-query");

/**
 * UI & NEW TAB 
 */
// Disable Sponsored content and ads on New Tab
user_pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);

// Sidebar & Vertical Tabs (Maintaining your current layout)
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.position_start", false); // Sidebar on the right

/**
 * MISC / BEHAVIOR
 */
// Form Autofill
user_pref("dom.forms.autocomplete.formautofill", true);

// Disable Nimbus Experiments
user_pref("nimbus.rollouts.enabled", false);

// Search Preferences
user_pref("browser.urlbar.placeholderName", "DuckDuckGo");
user_pref("browser.urlbar.placeholderName.private", "DuckDuckGo");