# Plán vylepšení – Platba LeQR.SK

Tento dokument sleduje identifikované problémy a ich implementáciu v `index.html` a `sw.js`.

## Krok A – Kritické opravy

### A1: Zlúčiť duplicitné message handlery a CHECK_UPDATES
- **Problém:** Dva oddelené `message` listenery pre `UPDATE_AVAILABLE` (head + bottom). Dva `load` listenery posielajú `CHECK_UPDATES` (po 1s + 30min interval, po 3s + 1h interval).
- **Súbor:** `index.html`
- **Riešenie:** Odstránený head handler. Zlúčené oba load listenery do jedného: `CHECK_UPDATES` po 3s + interval každých 30 min.
- **Stav:** ✅ DONE

### A2: Opraviť settings-success notifikáciu
- **Problém:** `#settings-success` div má triedu `hidden`, ale v `saveSettings()` sa nikdy nevolá `classList.remove('hidden')`.
- **Súbor:** `index.html`
- **Riešenie:** Pridané `classList.remove('hidden')`, zobrazenie na 1.5s potom skrytie + prepnutie na tab Platba.
- **Stav:** ✅ DONE

### A3: Odstrániť mŕtvy Google Chart API fallback
- **Problém:** Google Chart Image API je vypnuté. Fallback nikdy nebude fungovať.
- **Súbor:** `index.html`
- **Riešenie:** Celý catch blok nahradený jednoduchým `showErrorModal` + GTM tracking.
- **Stav:** ✅ DONE

### A4: Pinout bysquare na konkrétnu verziu
- **Problém:** `bysquare@latest` sa môže kedykoľvek zmeniť a zlomiť aplikáciu.
- **Súbory:** `index.html` (import), `sw.js` (urlsToCache)
- **Riešenie:** Zmenené na `bysquare@3.2.0` v oboch súboroch.
- **Stav:** ✅ DONE

### A5: Odstrániť duplicitné volanie loadSettings()
- **Problém:** `loadSettings()` sa volala 2× (window.onload + DOMContentLoaded listener).
- **Súbor:** `index.html`
- **Riešenie:** Odstránený `addEventListener('DOMContentLoaded', loadSettings)`. Ponechaný len `window.onload`.
- **Stav:** ✅ DONE

## Krok B – Stredné priority a vylepšenia

### B1: event.waitUntil(self.skipWaiting()) v SW
- **Problém:** `self.skipWaiting()` vracia Promise, ale nie je obalené v `event.waitUntil()`.
- **Súbor:** `sw.js`
- **Riešenie:** Zmenené na `event.waitUntil(self.skipWaiting())`.
- **Stav:** ✅ DONE

### B2: Sanitizácia innerHTML v update notifikácii
- **Problém:** `notification.innerHTML` vkladá `event.data.newVersion` priamo. Potenciálne XSS riziko.
- **Súbor:** `index.html`
- **Riešenie:** Nahradené programatickou DOM konštrukciou (`createTextNode` + `createElement('button')`).
- **Stav:** ✅ DONE

### B3: Prune starých dailyCounters
- **Problém:** Staré kľúče v `dailyCounters` (localStorage) sa nikdy nemažú.
- **Súbor:** `index.html`
- **Riešenie:** Pridaný prune v `commitVS()` — kľúče staršie ako 7 dní sa automaticky mažú.
- **Stav:** ✅ DONE

### B4: Odstrániť dead code
- **Problém:** Duplicitný IBAN check (nedosiahnuteľný). `isSw` check v SW fetch handleri (dead code).
- **Súbory:** `index.html`, `sw.js`
- **Riešenie:** Odstránené oba kusy mŕtveho kódu.
- **Stav:** ✅ DONE

### B5: Cache-busting pre pay-bottom-dark.png + var→const v SW
- **Problém:** CSS `background-image` nemá cache-busting parameter. `var` v SW activate handleri.
- **Súbory:** `index.html`, `sw.js`
- **Riešenie:** Pridané `?v=1.1.3` do CSS URL. Zmenené `var` na `const`.
- **Stav:** ✅ DONE

## Krok C – Manifest opravy

### C1: Opravy manifest.json
- **Problémy:**
  - `purpose: "any maskable"` v jednom zázname — prehliadač nesprávne použije maskable ikonu pre `any` kontext
  - Chýba `id`, `lang`, `dir`, `scope`
  - `start_url` a `shortcuts.url` mali hardcoded `?v=1.1.3` — spôsobovalo zmenu identity PWA pri verzii upgrade
  - `version` nie je štandardné PWA pole (neškodí, ale nemá efekt)
- **Súbor:** `manifest.json`
- **Riešenie:** Pridané `id`, `lang`, `dir`, `scope`. Ikony 192 a 512 rozdelené na `any` + `maskable`. `start_url` a `shortcuts.url` zmenené na `/`. Odstránené neštandardné `version` pole.
- **Stav:** ✅ DONE

## Krok D – SEO optimalizácia

### D1: Rozšírené meta tagy
- **Problémy:** Generický title, krátky description, chýba canonical, hreflang, keywords, robots, geo tagy
- **Riešenie:** Keyword-rich title, rozšírený description, 16 keyword fráz, canonical, hreflang sk + x-default, robots s max-image-preview, geo tagy SK, apple-touch-icon, viewport bez user-scalable=no
- **Stav:** ✅ DONE

### D2: Open Graph a Twitter Cards
- **Problémy:** Neoptimalizované tituly/popisy, chýbali og:image rozmery, locale, site_name
- **Riešenie:** Keyword-rich OG/Twitter tituly, og:image:width/height/alt, og:locale sk_SK, og:site_name, twitter:image:alt
- **Stav:** ✅ DONE

### D3: JSON-LD Structured Data
- **Problémy:** Žiadne structured data
- **Riešenie:** WebApplication (FinanceApplication, free offers, featureList, rating), FAQPage (4 otázky), BreadcrumbList
- **Stav:** ✅ DONE

### D4: Semantic HTML + noscript fallback
- **Problémy:** Chýba main, footer, noscript fallback
- **Riešenie:** main wrapper, footer s keywords, bohatý noscript blok s FAQ a funkciami pre crawlery bez JS
- **Stav:** ✅ DONE

### D5: robots.txt a sitemap.xml
- **Problémy:** Crawl-delay spomaľoval Google, blokované icons, zastaraný sitemap
- **Riešenie:** Odstránený Crawl-delay/Host, povolené icons, sitemap s 1 canonical URL a aktuálnym dátumom
- **Stav:** ✅ DONE

## Krok E – Cookie Consent & GDPR

### E1: Google Consent Mode v2
- **Problémy:** Žiadny consent management, GTM/GA zbierali údaje bez súhlasu používateľa
- **Riešenie:** Implementovaný `gtag('consent', 'default', {...})` pred GTM/gtag s 3 stavmi: granted, analytics, denied. Consent defaults sa načítavajú z localStorage pri každom načítaní stránky. `wait_for_update: 500` pre prípad asynchrónneho banneru.
- **Stav:** ✅ DONE

### E2: Cookie Consent Banner
- **Problémy:** Žiadny cookie banner, nesúlad s GDPR/ePrivacy
- **Riešenie:** Fixný banner na spodku stránky s 3 možnosťami: „Súhlasím so všetkými" (ad+analytics), „Len analytické" (len analytics_storage), „Odmietnuť" (všetko denied). Banner sa zobrazí len ak nie je uložený súhlas. Informácia o možnosti zmeny v Nastaveniach.
- **Stav:** ✅ DONE

### E3: Cookie Details Modal
- **Problémy:** Používateľ nemal informáciu o tom, aké cookies/údaje sa zbierajú
- **Riešenie:** Modal „Ochrana súkromia" s 4 kategóriami: Nevyhnutné (vždy aktívne), Analytické (GA), Marketingové (ads), Lokálne údaje (localStorage info). Prístupný z banneru aj z Nastavení.
- **Stav:** ✅ DONE

### E4: Správa cookies v Nastaveniach
- **Problémy:** Používateľ nemohol zmeniť rozhodnutie o cookies po prvom výbere
- **Riešenie:** Sekcia „Cookies a súkromie" v záložke Nastavenia s aktuálnym stavom súhlasu (typ + dátum) a tlačidlom „Zmeniť" pre opätovné zobrazenie banneru.
- **Stav:** ✅ DONE
