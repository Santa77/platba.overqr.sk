# Dokumentácia Google Tag Manager eventov

Tento dokument obsahuje zoznam všetkých eventov, ktoré sú implementované v aplikácii Platba OverQR pre sledovanie pomocou Google Tag Manager.

## Základné eventy aplikácie

| Event | Popis | Parametre |
|-------|-------|-----------|
| **app_installed** | Detekcia keď je aplikácia spustená ako nainštalovaná PWA | - |
| **app_opened** | Detekcia otvorenia aplikácie | `user_type`: 'new' alebo 'returning' |
| **service_worker_registered** | Úspešná registrácia service workera | `sw_scope`: rozsah service workera |
| **service_worker_registration_failed** | Zlyhanie registrácie service workera | `error`: text chyby |
| **offline_mode_entered** | Detekcia keď používateľ pracuje v offline režime | - |
| **app_online** | Detekcia obnovenia pripojenia k internetu | - |
| **app_load_time** | Meranie času načítania aplikácie | `load_time_ms`: čas v milisekundách |

## Eventy používateľského rozhrania

| Event | Popis | Parametre |
|-------|-------|-----------|
| **payment_form_opened** | Prepnutie na záložku platby | - |
| **settings_opened** | Prepnutie na záložku nastavení | - |
| **payment_form_started** | Začiatok vypĺňania platobného formulára | `has_note`: true/false |
| **payment_amount_entered** | Zadanie sumy platby | `amount`: hodnota platby |
| **note_field_used** | Použitie poznámky k platbe | - |
| **return_to_payment_form** | Návrat späť z QR kódu na platobný formulár | - |

## Eventy nastavení a validácie

| Event | Popis | Parametre |
|-------|-------|-----------|
| **settings_form_submitted** | Odoslanie formulára nastavení | `has_swift`: true/false, `has_recipient`: true/false |
| **settings_saved** | Úspešné uloženie nastavení | `country_code`: kód krajiny IBAN, `has_swift`: true/false, `has_recipient`: true/false |
| **settings_save_error** | Chyba pri ukladaní nastavení | `error_type`: typ chyby |
| **iban_validation_error** | Neplatný formát IBAN | `input_length`: dĺžka vstupu |

## Eventy QR kódu a spracovania platieb

| Event | Popis | Parametre |
|-------|-------|-----------|
| **qr_code_generated** | Úspešné vygenerovanie QR kódu | `generation_time_ms`: čas generovania, `qr_method`: metóda generovania, `payment_amount`: suma platby, `has_note`: true/false |
| **qr_generation_error** | Chyba pri generovaní QR kódu | `error_type`: typ chyby |
| **vs_auto_generated** | Automatické vygenerovanie variabilného symbolu | `vs`: hodnota VS |
| **fallback_qr_method_used** | Použitie záložnej metódy generovania QR | - |
| ~~**qr_generation_amount_range**~~ | ~~Kategorizácia platieb podľa výšky sumy~~ | ~~`amount_category`: kategória sumy ('0-10', '10-50', '50+')~~ |

## Technické eventy

| Event | Popis | Parametre |
|-------|-------|-----------|
| **bysquare_library_loading** | Čakanie na načítanie bysquare knižnice | `action`: 'waiting' |
| **bysquare_library_load_success** | Úspešné načítanie bysquare knižnice | `load_type`: 'immediate' alebo 'delayed' |
| **bysquare_library_load_error** | Chyba pri načítaní bysquare knižnice | - |

## Implementácia dataLayer

Príklad implementácie dataLayer pre udalosť generovania QR kódu:

```javascript
dataLayer.push({
    'event': 'qr_code_generated',
    'generation_time_ms': Math.round(qrGenerationTime),
    'qr_method': 'qrcode-generator',
    'payment_amount': parseFloat(amount),
    'has_note': note.trim() !== ''
});
```

Pre správne merania je potrebné v Google Tag Manager nakonfigurovať triggery a premenné pre zachytávanie týchto eventov.
