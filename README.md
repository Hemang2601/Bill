# ⚡ SHREE SHAKTI ELECTRIC

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=700&size=25&duration=3000&pause=1000&color=2563EB&center=true&vCenter=true&width=750&height=55&lines=Smart+Billing.+Simplified+Business.;Professional+Invoices.+Effortless+Management.;A+Modern+Billing+Experience." alt="Shree Shakti Electric" />
</p>

<p align="center">
  <b>A Premium Billing & Invoice Management Application</b>
  <br/>
  Built to make everyday business operations smarter, faster, and more organized.
</p>

<p align="center">
  <a href="https://github.com/Hemang2601/Bill">
    <img src="https://img.shields.io/badge/PROJECT%20REPOSITORY-181717?style=for-the-badge&logo=github&logoColor=white" />
  </a>
  <img src="https://img.shields.io/badge/BUILT%20WITH-FLUTTER-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/POWERED%20BY-DART-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Database-SQLite-003B57?style=flat-square&logo=sqlite" />
  <img src="https://img.shields.io/badge/Architecture-Modular-7C3AED?style=flat-square" />
  <img src="https://img.shields.io/badge/Design-Premium%20UI-10B981?style=flat-square" />
  <img src="https://img.shields.io/badge/Status-Active-2563EB?style=flat-square" />
</p>

---

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=0:172554,50:2563EB,100:0EA5E9&height=3&section=header" width="100%" />
</p>

## 01 — Overview

**Shree Shakti Electric** is a modern, Flutter-powered billing management solution designed to streamline invoice creation, customer billing, document generation, and business record management.

Built around a clean, premium interface and a reliable local database, it transforms traditional billing operations into a simple digital workflow.

The application focuses on three important principles:

<p align="center">
  <img src="https://img.shields.io/badge/01-Simplicity-2563EB?style=for-the-badge" />
  <img src="https://img.shields.io/badge/02-Reliability-7C3AED?style=for-the-badge" />
  <img src="https://img.shields.io/badge/03-Professionalism-0D9488?style=for-the-badge" />
</p>

## 02 — Core Capabilities

<table>
<tr>
<td width="50%" valign="top">

### ◈ Intelligent Dashboard

- Real-time invoice statistics
- Total revenue overview
- Customer insights
- Recent billing activity
- Quick navigation and actions

</td>
<td width="50%" valign="top">

### ◈ Manager Authentication

- Predefined manager accounts
- Persistent login sessions
- Manager-specific signatures
- Controlled application access
- No public registration

</td>
</tr>
<tr>
<td width="50%" valign="top">

### ◈ Smart Invoice Builder

- Three-step invoice workflow
- Customer information management
- Multiple product and service entries
- Automatic calculations
- Invoice review before generation

</td>
<td width="50%" valign="top">

### ◈ Professional PDF Engine

- Structured invoice generation
- Business and customer information
- Itemized billing details
- Authorized manager signatures
- Print and sharing support

</td>
</tr>
<tr>
<td width="50%" valign="top">

### ◈ Billing History

- Search by invoice number
- Customer and mobile search
- Flexible date filters
- Invoice details and PDF access
- Safe deletion operations

</td>
<td width="50%" valign="top">

### ◈ Invoice Editing

- Update existing invoices
- Modify products and quantities
- Automatic total recalculation
- Preserve original invoice identity
- Replace the associated PDF

</td>
</tr>
</table>

## 03 — Application Workflow

<p align="center">
  <b>From customer details to a professionally generated invoice.</b>
</p>

```mermaid
flowchart TD
    A([Application Launch]) --> B[Manager Authentication]
    B --> C[Business Dashboard]
    C --> D[Create New Invoice]
    D --> E[Customer Information]
    E --> F[Items and Pricing]
    F --> G[Review and Verification]
    G --> H[Generate PDF]
    H --> I[(SQLite Database)]
    I --> J[Share or Print]
    C --> K[Invoice History]
    K --> L[View / Edit / Delete]
    L --> I

    style A fill:#172554,color:#fff,stroke:#172554
    style H fill:#2563EB,color:#fff,stroke:#2563EB
    style I fill:#7C3AED,color:#fff,stroke:#7C3AED
    style J fill:#059669,color:#fff,stroke:#059669
```

## 04 — Design Philosophy

**A refined interface. A practical experience.**

The application follows a premium white-theme design system with carefully balanced colorful accents.

| Design Element | Direction |
|---|---|
| Primary Theme | Luxury White |
| Primary Color | Electric Blue |
| Secondary Color | Deep Navy |
| Accent Colors | Violet, Emerald, Amber, Coral |
| Interface | Clean and Minimal |
| Components | Modern Cards and Dialogs |
| Interaction | Smooth Micro-animations |
| Layout | Mobile-first and Responsive |

The design prioritizes readability, accessibility, consistency, and usability rather than unnecessary visual complexity.

## 05 — Technology Architecture

<p align="center">
  <img src="https://skillicons.dev/icons?i=flutter,dart,sqlite,androidstudio,vscode,git,github" alt="Development technologies" />
</p>

| Layer | Technology | Responsibility |
|---|---|---|
| Frontend | Flutter | Responsive application UI |
| Language | Dart | Application logic |
| Database | SQLite | Persistent local storage |
| Session | SharedPreferences | Login session persistence |
| Documents | PDF | Invoice generation |
| Printing | Printing | Physical invoice printing |
| Sharing | Share Plus | Document sharing |
| Formatting | Intl | Currency and date formatting |

## 06 — Database Structure

**Database:** `shree_shakti.db`

**Schema Version:** `3`

| Table | Purpose |
|---|---|
| `managers` | Authorized manager records |
| `invoices` | Invoice and customer information |
| `invoice_items` | Individual invoice line items |

### Invoice Numbering System

Every invoice follows a structured sequential format:

```text
SE-yyMM-XXX
```

Example:

```text
SE-2611-001
SE-2611-002
SE-2611-003
```

**Data integrity principles:**

- Transaction-based invoice operations.
- Invoice and item records maintained together.
- Existing invoice numbers preserved during editing.
- Foreign key relationships and cascade handling.

## 07 — Project Structure

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

*High-level representation; actual folders may differ.*

## 08 — Getting Started

### Requirements

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android SDK
- Git

### Installation

**Step 1 — Clone the repository**

```bash
git clone https://github.com/Hemang2601/Bill.git
```

**Step 2 — Open the project**

```bash
cd Bill
```

**Step 3 — Install dependencies**

```bash
flutter pub get
```

**Step 4 — Verify the development environment**

```bash
flutter doctor
```

**Step 5 — Launch the application**

```bash
flutter run
```

### Development Commands

| Command | Purpose |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run application |
| `flutter test` | Execute automated tests |
| `flutter analyze` | Analyze Dart code |
| `flutter build apk` | Build Android APK |
| `flutter build windows` | Build Windows application |

## 09 — Quality & Testing

<p align="center">
  <img src="https://img.shields.io/badge/TESTS-79%20PASSED-059669?style=for-the-badge&logo=checkmarx&logoColor=white" />
  <img src="https://img.shields.io/badge/STATIC%20ANALYSIS-CLEAN-2563EB?style=for-the-badge&logo=flutter&logoColor=white" />
</p>

The latest reported QA run covered:

- Authentication workflows
- Invoice calculations
- Database operations
- Invoice creation and editing
- Application functionality

*Test results reflect the latest reported run and should be refreshed after subsequent code changes.*

## 10 — Application Preview

<p align="center">
  <b>Experience the interface</b>
  <br/>
  <sub>Real application screenshots will be added here.</sub>
</p>

<!-- Add actual screenshots to the screenshots/ directory. -->

<p align="center">
  <img src="screenshots/login.png" width="30%" alt="Manager Login" />
  <img src="screenshots/dashboard.png" width="30%" alt="Dashboard" />
  <img src="screenshots/create-invoice.png" width="30%" alt="Invoice Creation" />
</p>

<p align="center">
  <sub>Replace these image paths with real screenshots before publishing.</sub>
</p>

## 11 — Security & Data Management

- Local SQLite data persistence.
- Predefined manager authentication.
- Session persistence.
- Manager-specific invoice signatures.
- Transactional invoice updates.
- Confirmation for destructive operations.

> **Security consideration:** The current manager password implementation has not yet been migrated to a dedicated slow password-hashing algorithm. Further security hardening is recommended before production deployment.

## 12 — Platform Compatibility

| Platform | Availability |
|---|---|
| Android | Primary development platform |
| Windows | Build setup in progress |
| iOS | Not verified |
| Web | Not verified |

## 13 — Roadmap

- [ ] Enhanced password security
- [ ] Database backup and restoration
- [ ] Advanced sales analytics
- [ ] Detailed financial reports
- [ ] Additional business configuration
- [ ] Improved deployment and release workflow

## 14 — Developer

<p align="center">
  <img src="https://img.shields.io/badge/DEVELOPED%20BY-Hemang%20Lakhadiya-172554?style=for-the-badge" />
</p>

<p align="center">
  <a href="https://github.com/Hemang2601">
    <img src="https://img.shields.io/badge/GitHub-View%20Developer%20Profile-181717?style=for-the-badge&logo=github" />
  </a>
  <a href="https://github.com/Hemang2601/Bill">
    <img src="https://img.shields.io/badge/Repository-Explore%20Project-2563EB?style=for-the-badge&logo=github" />
  </a>
</p>

## 15 — License & Ownership

Developed for **Shree Shakti Electric**.

All rights reserved unless a separate license is explicitly provided in this repository.

---

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:172554,50:2563EB,100:0EA5E9&height=130&section=footer&text=SHREE%20SHAKTI%20ELECTRIC&fontSize=24&fontColor=ffffff&fontAlignY=55" width="100%" />
</p>

<p align="center">
  <b>SMART BILLING · SIMPLE MANAGEMENT · PROFESSIONAL INVOICES</b>
  <br/>
  <sub>Designed with purpose. Built with Flutter. ⚡</sub>
</p>
