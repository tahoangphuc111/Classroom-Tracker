(function () {
  var STORAGE_KEY = 'ct_lang';
  var VALID_LANGS = { vi: true, en: true };

  function detectInitialLang() {
    try {
      var params = new URLSearchParams(window.location.search);
      var queryLang = params.get('lang');
      if (queryLang && VALID_LANGS[queryLang.toLowerCase()]) {
        return queryLang.toLowerCase();
      }
      var saved = window.localStorage.getItem(STORAGE_KEY);
      if (saved && VALID_LANGS[saved]) {
        return saved;
      }
    } catch (_) {}
    var navLang = (navigator.language || navigator.userLanguage || '').toLowerCase();
    return navLang.indexOf('vi') === 0 ? 'vi' : 'en';
  }

  function applyLang(lang, persist) {
    if (!VALID_LANGS[lang]) return;
    var root = document.documentElement;
    root.classList.remove('lang-vi', 'lang-en');
    root.classList.add('lang-' + lang);
    root.setAttribute('lang', lang);

    var title = root.getAttribute('data-title-' + lang);
    if (title) {
      document.title = title;
    }

    var descMeta = document.querySelector('meta[name="description"]');
    var desc = root.getAttribute('data-desc-' + lang);
    if (descMeta && desc) {
      descMeta.setAttribute('content', desc);
    }

    var buttons = document.querySelectorAll('.lang-btn[data-set-lang]');
    for (var i = 0; i < buttons.length; i++) {
      var btn = buttons[i];
      var isSelected = btn.getAttribute('data-set-lang') === lang;
      btn.setAttribute('aria-pressed', isSelected ? 'true' : 'false');
    }

    if (persist) {
      try {
        window.localStorage.setItem(STORAGE_KEY, lang);
      } catch (_) {}
      try {
        var url = new URL(window.location.href);
        url.searchParams.set('lang', lang);
        window.history.replaceState(null, '', url.toString());
      } catch (_) {}
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    var currentLang = document.documentElement.classList.contains('lang-en') ? 'en' : detectInitialLang();
    applyLang(currentLang, false);

    var buttons = document.querySelectorAll('.lang-btn[data-set-lang]');
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].addEventListener('click', function () {
        applyLang(this.getAttribute('data-set-lang'), true);
      });
    }
  });
})();
