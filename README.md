# ⚡ Shree Shakti Electric

<h3 align="center">Premium Billing Management Application</h3>

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1000&color=2563EB&center=true&vCenter=true&width=650&lines=Smart+Billing.+Simple+Management.;Create+Professional+Invoices.;Manage+Your+Business+Effortlessly.;Built+with+Flutter+%26+Dart." alt="Animated introduction" />
</p>

<p align="center">
  A modern, responsive, and feature-rich billing application designed to simplify everyday business operations for Shree Shakti Electric.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.5-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-Powered-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Database-SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Windows-10B981?style=for-the-badge" />
</p>

<p align="center">
  <a href="https://github.com/Hemang2601/Bill">
    <img src="https://img.shields.io/badge/View%20Repository-GitHub-181717?style=flat-square&logo=github" />
  </a>
  <img src="https://img.shields.io/badge/Status-Active-10B981?style=flat-square" />
  <img src="https://img.shields.io/badge/Version-1.0-blue?style=flat-square" />
</p>

---

## ✨ About the Project

**Shree Shakti Electric** is a modern billing management application developed using Flutter and Dart.

It helps manage invoices, customer information, billing history, and PDF documents through a simple and professional interface.

Designed with a premium white theme, colorful accents, and responsive layouts, the application provides a smooth experience across mobile devices and larger screens.

## 🚀 Features

<table>
<tr>
<td width="50%">
<h3>🔐 Manager Authentication</h3>
<ul>
<li>Predefined manager accounts</li>
<li>Session persistence</li>
<li>Manager-specific signatures</li>
<li>No public registration</li>
</ul>
</td>
<td width="50%">
<h3>📊 Smart Dashboard</h3>
<ul>
<li>Total invoice statistics</li>
<li>Revenue overview</li>
<li>Customer statistics</li>
<li>Recent invoice activity</li>
</ul>
</td>
</tr>
<tr>
<td width="50%">
<h3>🧾 Invoice Management</h3>
<ul>
<li>Three-step invoice workflow</li>
<li>Customer information</li>
<li>Multiple invoice items</li>
<li>Automatic calculations</li>
</ul>
</td>
<td width="50%">
<h3>📄 PDF Generation</h3>
<ul>
<li>Professional invoice PDFs</li>
<li>Manager signatures</li>
<li>Print and share support</li>
<li>Preserved invoice layout</li>
</ul>
</td>
</tr>
<tr>
<td width="50%">
<h3>📚 Billing History</h3>
<ul>
<li>Search and date filters</li>
<li>View invoice details</li>
<li>Share and print invoices</li>
<li>Safe invoice deletion</li>
</ul>
</td>
<td width="50%">
<h3>✏️ Edit Invoices</h3>
<ul>
<li>Update customer details</li>
<li>Modify invoice items</li>
<li>Automatic recalculation</li>
<li>Preserve existing bill number</li>
</ul>
</td>
</tr>
</table>

## 🎨 Application Design

<p align="center">
  <strong>Luxury White Theme · Colorful Accents · Responsive Interface</strong>
</p>

The application follows a consistent design system featuring:

- Clean white surfaces and soft neutral backgrounds.
- Electric blue and navy primary colors.
- Balanced violet, emerald, amber, and coral accents.
- Premium cards, modern typography, and subtle shadows.
- Smooth transitions and interactive feedback.
- Mobile-first layouts with desktop responsiveness.

## 🔄 How It Works

```mermaid
flowchart TD
    A([Launch Application]) --> B[Manager Login]
    B --> C[Dashboard]
    C --> D[Create Invoice]
    D --> E[Customer Details]
    E --> F[Items and Pricing]
    F --> G[Review Invoice]
    G --> H[Generate PDF]
    H --> I[(Save to SQLite)]
    I --> J[Share or Print]
    C --> K[Invoice History]
    K --> L[View / Edit / Delete]
    L --> I

    style A fill:#2563EB,color:#fff
    style H fill:#10B981,color:#fff
    style I fill:#7C3AED,color:#fff
```

## 🛠️ Technology Stack

<p align="center">
  <img src="https://skillicons.dev/icons?i=flutter,dart,sqlite,androidstudio,vscode,git,github" alt="Technology stack" />
</p>

| Technology | Usage |
|---|---|
| Flutter | Cross-platform UI |
| Dart | Application development |
| SQLite | Local database |
| SharedPreferences | Session persistence |
| PDF | Invoice generation |
| Printing | Print invoices |
| Share Plus | Share documents |
| Intl | Currency and date formatting |

## 🗂️ Project Structure

```text
Bill/
│
├── assets/
│   └── images/
│       ├── hiren.png
│       └── suresh.png
│
├── lib/
│   ├── core/
│   │   ├── theme/
│   │   ├── constants/
│   │   ├── utils/
│   │   ├── widgets/
│   │   └── services/
│   │
│   ├── data/
│   │   ├── database/
│   │   └── models/
│   │
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── invoice/
│   │   ├── history/
│   │   └── settings/
│   │
│   └── main.dart
│
├── test/
├── pubspec.yaml
└── README.md
```

*The structure above is a high-level overview. Refer to the repository for the actual implementation.*

## 🗄️ Database Design

Database: `shree_shakti.db`

Schema Version: `3`

| Table | Responsibility |
|---|---|
| `managers` | Authorized manager records |
| `invoices` | Invoice and customer details |
| `invoice_items` | Individual invoice items |

### Automatic Invoice Numbering

```text
SE-yyMM-XXX

SE-2611-001
SE-2611-002
SE-2611-003
```

Invoices use sequential numbering and transactional database operations.

## ⚙️ Installation & Setup

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android SDK
- Git

### Clone Repository

```bash
git clone https://github.com/Hemang2601/Bill.git
```

### Open Project

```bash
cd Bill
```

### Install Dependencies

```bash
flutter pub get
```

### Check Environment

```bash
flutter doctor
```

### Run Application

```bash
flutter run
```

### Run Tests

```bash
flutter test
```

### Analyze Code

```bash
flutter analyze
```

## 🧪 Quality Assurance

Latest reported project QA results:

<p align="center">
  <img src="https://img.shields.io/badge/Automated%20Tests-79%20Passed-10B981?style=for-the-badge&logo=flutter" />
  <img src="https://img.shields.io/badge/Flutter%20Analyze-No%20Issues-2563EB?style=for-the-badge" />
</p>

- Invoice calculation tests.
- Database operation tests.
- Authentication workflow tests.
- Invoice creation and editing tests.
- Application workflow validation.

*These results reflect the latest reported QA run and should be updated after future test runs.*

## 📸 Screenshots

<p align="center">
  <i>Application screenshots will be added here.</i>
</p>

<!--
Add your actual screenshots to a GitHub screenshots/ folder
and replace the placeholders below.

<p align="center">
  <img src="screenshots/login.png" width="30%" />
  <img src="screenshots/dashboard.png" width="30%" />
  <img src="screenshots/create-invoice.png" width="30%" />
</p>
-->

## 🔒 Data & Security

- Local SQLite database storage.
- Predefined manager authentication.
- Persistent login sessions.
- Manager-specific invoice signatures.
- Transaction-based invoice operations.
- Confirmation before destructive operations.

**Security note:** The current manager password implementation has not yet been migrated to a dedicated slow password-hashing algorithm. Additional security hardening is recommended before production deployment.

## 🖥️ Platform Support

| Platform | Status |
|---|---|
| Android | Primary platform |
| Windows | Development/build setup in progress |
| iOS | Not verified |
| Web | Not verified |

## 🗺️ Future Improvements

- Advanced sales analytics.
- Database backup and restore.
- Invoice export and reporting.
- Enhanced authentication security.
- Additional business configuration options.

## 👨‍💻 Developer

<p align="center">
  <strong>Hemang Lakhadiya</strong><br/>
  MCA Student · Flutter Developer · Full Stack Developer
  <br/><br/>
  <a href="https://github.com/Hemang2601">
    <img src="https://img.shields.io/badge/GitHub-Hemang2601-181717?style=for-the-badge&logo=github" />
  </a>
</p>

## 📄 License

Developed for **Shree Shakti Electric**. All rights reserved unless a separate license is provided in this repository.

---

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=18&pause=1200&color=2563EB&center=true&vCenter=true&width=500&lines=Thank+you+for+visiting!;Built+with+Flutter+%E2%9D%A4%EF%B8%8F;Smart+Billing.+Simple+Management." alt="Animated footer" />
</p>

<p align="center">
  <strong>⚡ SHREE SHAKTI ELECTRIC</strong><br/>
  <sub>Smart Billing. Simple Management. Professional Invoices.</sub>
</p>
