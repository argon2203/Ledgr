# Ledgr (लेजर) - AI Bookkeeping Assistant for Indian Traders & Wholesalers

**Ledgr** is a voice-first, AI-powered mobile bookkeeping application built using **Flutter** (Android first, iOS ready) and the **Gemini Multimodal API**. It is designed specifically for small Indian traders, distributors, and wholesalers who do not like typing into complex accounting software like Tally or Zoho.

Instead of manual data entry, business owners speak naturally in **Hindi, English, Gujarati, Marathi, Tamil, or Hinglish** (or take a photo of a handwritten bill). Ledgr extracts the structured transaction details, performs all strict GST and inventory calculations directly in Dart code, presents an audit confirmation card with warnings, updates stock and party ledgers, and generates a GST-compliant tax invoice PDF ready to share on WhatsApp.

---

## 📱 Core Features & Screens

1. **Home Screen**
   - **Central Mic Button**: Hold to record voice notes with dynamic ripple breathing animations, release to send.
   - **Bill Camera Button**: Capture or upload photos of handwritten bills or challans.
   - **Live Business Summary Cards**:
     - *Sales Today* (₹)
     - *To Collect* (₹)
     - *Low Stock Alert* with count of items needing immediate reorder.
   - **One-Tap Quick Demo Chip**: Instantly triggers the end-to-end voice demo flow.

2. **Confirmation Card Screen**
   - Shown immediately after a voice note or bill photo is analyzed.
   - Displays Party Name (with verified directory match badge), Items list, Quantity, Rate, HSN code, GST %, GST amount, and Total.
   - **Smart Audit Warnings**:
     - *Unknown Party* (if not in contacts or ambiguous match)
     - *Stock Alert* (warns if sale exceeds available warehouse stock)
     - *Rate Alert* (flags if entered price deviates > 25% from standard rates)
   - **Stock Remaining**: Shows warehouse balance remaining after the transaction.
   - **Actions**: Confirm & Save, Edit (voice command or typed adjustment), Cancel.

3. **Ask AI Screen (Grounded Q&A)**
   - Chat assistant answering business questions by voice or text in Hindi, Hinglish, or English:
     - *"Ramesh Bhai ka kitna baaki hai?"*
     - *"Aaj kitna sale hua?"*
     - *"PVC roll ka stock kitna hai?"*
   - **100% Grounded in Ledger Database**: Never hallucinates numbers; queries live party balances and inventory directly.

4. **Entries Screen**
   - Chronological ledger of all vouchers.
   - Filters by voucher type (*Sales, Purchase, Receipt, Payment*) and date (*Today, This Week, This Month, All*).
   - Search by party name, voucher number, or item.
   - Voucher Detail view with tax breakup and **1-tap WhatsApp GST Invoice PDF Sharing**.

5. **Parties and Stock Screen**
   - **Parties Tab**: Directory of customers and suppliers with nicknames (e.g., *"Ramesh Bhai"*, *"Ramesh"*), GSTIN, state codes, and balances (*Green for To Collect, Red for To Pay*).
   - **Stock Tab**: Inventory of items with HSN codes, GST tax rates, standard selling rates, and current stock with low-stock badges.

6. **Settings & Tally / Zoho Bridge**
   - **Bilingual Language Toggle**: Dynamic switch between English and हिन्दी.
   - **Business Profile**: Firm name, GSTIN, address, state code, and phone number.
   - **Tally Connector (Mock Bridge)**: Live XML inspector generating authentic TallyPrime XML payloads (`<ENVELOPE><HEADER><TALLYREQUEST>Import Data...`). Swappable architecture ready for Tally ODBC or Zoho Books REST API.
   - **Reset Demo Data**: Easily restore initial seed data at any time.

---

## 🎯 Verified End-to-End Demo Flow

| Step | Action | Outcome |
|------|--------|---------|
| **1** | Hold mic or tap voice chip: *"Ramesh Bhai ko pachaas PVC roll bhejo, chaar sau bees ke rate pe, GST lagao aur entry kar do."* | Audio/text sent to Gemini multimodal engine with known parties and inventory directory. |
| **2** | Confirmation Card opens | **Party**: Ramesh Traders (matched from nickname *"Ramesh Bhai"*)<br>**Item**: 50 PVC Rolls @ ₹420 = ₹21,000<br>**GST 18%**: ₹3,780 (CGST ₹1,890 + SGST ₹1,890)<br>**Total**: ₹24,780<br>**Stock Remaining**: 100 rolls (150 initial - 50 sold). |
| **3** | Tap **Confirm & Save** | Voucher saved (`SAL-2026-082`), PVC Roll stock updates to 100, Ramesh Traders balance updates from ₹15,000 to ₹39,780, and GST invoice PDF opens with WhatsApp share option. |
| **4** | Go to **Ask** and say: *"Ramesh Bhai ka kitna baaki hai?"* | Ledgr replies: *"Ramesh Traders से कुल ₹39,780 लेना बाकी है।"* |

---

## 📐 Project Structure

```
WeeGo/
├── backend/
│   └── functions/
│       ├── index.js          # Firebase Cloud Function / Cloud Run for Gemini Multimodal
│       └── package.json      # Node.js dependencies (@google/generative-ai)
├── lib/
│   ├── main.dart             # App entry, multi-provider setup & bottom navigation
│   ├── core/
│   │   ├── constants/
│   │   │   ├── colors.dart   # Deep Forest Green (#0F5132), Indian business palette
│   │   │   ├── strings.dart  # English and Hindi bilingual translation dictionary
│   │   │   └── theme.dart    # Accessible typography (min 16sp font) and large buttons
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart # Indian number format (e.g. ₹1,24,780)
│   │   │   ├── gst_calculator.dart     # Intra-state (CGST+SGST) & Inter-state (IGST) in Dart
│   │   │   └── number_to_words.dart    # Converts amount to words for tax invoice
│   │   └── connectors/
│   │       ├── tally_connector.dart    # TallyConnector interface & Mock XML implementation
│   │       └── zoho_connector.dart     # Swappable Zoho Books connector interface
│   ├── models/
│   │   ├── party.dart        # Customer/Supplier with nicknames, GSTIN & balance
│   │   ├── item.dart         # Item with HSN, GST rate, unit, and stock threshold
│   │   ├── voucher.dart      # Header record with subtotal, tax breakdown, total
│   │   ├── voucher_item.dart # Line item record with tax details
│   │   └── ai_parse_result.dart # JSON schema matching Gemini structured output
│   ├── services/
│   │   ├── gemini_service.dart         # Multimodal Gemini caller (Flash -> Pro retry) + Vernacular engine
│   │   ├── audio_recorder_service.dart # Microphone recording handler
│   │   ├── storage_service.dart        # Seeds 8 parties, 15 items & 20 demo vouchers
│   │   └── pdf_invoice_service.dart    # Generates official GST tax invoice PDF
│   ├── providers/
│   │   ├── ledger_provider.dart        # Stock, balances, metrics & grounded Q&A
│   │   ├── settings_provider.dart      # Language, business profile, API settings
│   │   └── voice_entry_provider.dart   # Hold-to-record state & confirmation draft
│   └── screens/
│       ├── home/home_screen.dart
│       ├── confirmation/confirmation_screen.dart
│       ├── ask/ask_screen.dart
│       ├── entries/
│       │   ├── entries_screen.dart
│       │   └── voucher_detail_screen.dart
│       ├── parties_stock/parties_stock_screen.dart
│       └── settings/
│           ├── settings_screen.dart
│           └── tally_sync_screen.dart
└── test/
    ├── ledger_flow_test.dart # Full unit & integration test of end-to-end demo flow
    └── widget_test.dart      # Widget tests for home screen and navigation
```

---

## 🧪 Running the Tests

To verify all calculations, voucher saves, inventory deductions, balance updates, and Q&A responses:

```bash
flutter test
```
All test suites pass out-of-the-box.

---

## 🚀 Running the App

```bash
flutter run
```
You can run it on Android (physical phone or emulator), Chrome (web), or Windows desktop.
