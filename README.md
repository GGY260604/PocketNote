# PocketNote 📒💰

PocketNote is a modern offline-first personal finance recorder built with Flutter and Firebase.  
It integrates Google AI (Gemini) to assist users in recording expenses and income via text and receipt recognition.

---

# 🌐 Google Developer Technologies Used

PocketNote is built using the following Google technologies:

- **Flutter** – Cross-platform UI framework (Android, iOS, Web, Desktop ready)
- **Firebase Authentication** – Anonymous + Google Sign-In
- **Cloud Firestore** – Cloud data synchronization
- **Firebase AI (Gemini API)** – AI parsing engine
- **Google ML Kit (Text Recognition)** – OCR for receipt processing

---

# 🤖 Google AI Technology Used

## Gemini API (via Firebase AI)

Gemini is used to intelligently parse:

- Natural language expense input  
  Example:  
  `spend 12.5 lunch`
- Income statements  
  Example:  
  `income 300 salary`
- Transfer operations  
  Example:  
  `transfer 50 fee 1.2`
- Receipt images (OCR + AI extraction)

---

# 🧠 Where AI Is Implemented in PocketNote

AI is integrated in:

### 1️⃣ Chat Page
- Text-to-structured record parsing
- AI candidate suggestion (multiple possible drafts)
- Smart fallback parser when AI unavailable

### 2️⃣ Receipt Flow
- Image → OCR (Google ML Kit)
- OCR text → Gemini structured draft extraction
- Multiple candidate selection before saving

AI never directly writes to database.  
User confirmation is required before record persistence.

---

# 🌍 Sustainable Development Goals (SDGs)

PocketNote contributes to:

### SDG 8 – Decent Work and Economic Growth
Encourages responsible financial tracking and literacy.

### SDG 9 – Industry, Innovation and Infrastructure
Implements AI-driven finance tools.

### SDG 12 – Responsible Consumption and Production
Promotes awareness of spending habits and budgeting.

### SDG 13 – Climate Action (Indirect)
Encourages reduced unnecessary consumption through awareness.

---

# 🏗 Technical Architecture

PocketNote follows a **layered offline-first architecture**:

```text
UI Layer (Pages / Widgets)
↓
State Layer (ChangeNotifier Providers)
↓
Repository Layer
↓
Local Storage (Hive)
↓
Cloud Sync (Firestore)
```

## State Management
- `Provider` (ChangeNotifier-based architecture)
- Separation between UI logic and data logic
- Clear unidirectional data flow

## Data Strategy
- Offline-first with Hive
- Firestore sync on authenticated login
- Soft-delete pattern for conflict resolution
- SyncGate mechanism to control one-time sync per UID

## Security Strategy
- Firestore security rules
- Authentication required for cloud operations

---

# ⚙ Implementation Details

## 🧩 Core Modules

### Accounts Module
- Balance auto-adjustment
- Transfer with service charge support
- Delta-based balance mutation logic

### Categories Module
- Separate spending & income categories
- Dynamic icon storage (iconCodePoint + fontFamily)
- Seeded default categories

### Records Module
- Spending / Income / Transfer
- Include-in-statistics toggle
- Include-in-budget toggle
- Month-based filtering

### Budgets Module
- Category-level monthly budget
- Summary card with progress tracking
- Dismissible category budgets
- Spend-sorted budget list

### AI Module
- GeminiService abstraction
- Strict mode toggle
- Candidate sheet selection
- Offline fallback parser

---

# 🚧 Challenges Faced

## 1️⃣ Dynamic Icon Tree-Shaking Issue
Flutter release build failed due to dynamic `IconData` instantiation.  
Solution:
- Disabled icon tree shaking using:

```code
--no-tree-shake-icons
```

---

## 2️⃣ R8 Release Build Failure (ML Kit)
Release builds failed due to missing ML Kit language classes.

Solution:
- Disabled R8 minification:

```code
isMinifyEnabled = false
isShrinkResources = false
```

---

## 3️⃣ Firestore Sync UI Not Updating
Data synced but UI did not refresh until month changed.

Root cause:
- Providers not refreshing after sync.

Solution:
- Explicit provider reload after sync completion.

---

## 4️⃣ BuildContext Async Gap Warnings
Resolved by:
- Capturing providers before await
- Guarding with `if (!mounted) return`

---

## 5️⃣ Multi-device Sync Conflict Risk
Implemented:
- Soft delete
- Timestamp updates
- Explicit month reload logic

---

# 🔮 Future Roadmap

## Phase 1 – Stability & Security
- Enable ProGuard with proper ML Kit keep rules
- Improve sync conflict resolution
- Background sync optimization
- Strengthen Firestore rules

## Phase 2 – AI Enhancement
- Auto-categorization model training
- AI budgeting suggestions
- Spending anomaly detection
- Smart financial insights dashboard

## Phase 3 – UX Improvements
- Advanced analytics (pie, trend, comparison)
- Export to CSV / PDF
- Dark mode polish
- Custom icon picker expansion

## Phase 4 – Production Readiness
- Play Store AAB publishing
- CI/CD pipeline
- Crashlytics integration
- Performance profiling

---

# Firebase Build Configuration

- Create firebase project and enable the required Firebase services (Authentication, Firestore and Firebase AI Logic) in your Firebase console and set up the appropriate configurations for needed platform (Prefer Android) to ensure proper functionality of the app.

- Then, get the required keys and IDs, and fill in the following environment variables based on your platform needed in `.env.local` file at root before development and production builds:

```local
# ===== FIREBASE WEB =====
FIREBASE_WEB_API_KEY=
FIREBASE_WEB_APP_ID=
FIREBASE_WEB_MESSAGING_SENDER_ID=
FIREBASE_WEB_PROJECT_ID=
FIREBASE_WEB_AUTH_DOMAIN=
FIREBASE_WEB_STORAGE_BUCKET=
FIREBASE_WEB_MEASUREMENT_ID=

# ===== FIREBASE ANDROID =====
FIREBASE_ANDROID_API_KEY=
FIREBASE_ANDROID_APP_ID=
FIREBASE_ANDROID_MESSAGING_SENDER_ID=
FIREBASE_ANDROID_PROJECT_ID=
FIREBASE_ANDROID_STORAGE_BUCKET=

# ===== FIREBASE IOS =====
FIREBASE_IOS_API_KEY=
FIREBASE_IOS_APP_ID=
FIREBASE_IOS_MESSAGING_SENDER_ID=
FIREBASE_IOS_PROJECT_ID=
FIREBASE_IOS_STORAGE_BUCKET=
FIREBASE_IOS_CLIENT_ID=
FIREBASE_IOS_BUNDLE_ID=

# ===== GEMINI (IMPORTANT – REAL SECRET) =====
GEMINI_API_KEY=your_real_gemini_key_here
```

---

# 📦 Production Build Notes

Release APK:

```code
flutter build apk --release --no-tree-shake-icons
```

Release AAB:

```code
flutter build appbundle --release --no-tree-shake-icons
```

---

# 👨‍💻 Author

Developed as a modern AI-powered financial recording system using Flutter & Firebase ecosystem.

---

# 📜 License

Private project – not for public distribution.