# ⚡ Shree Shakti Electric – Billing Management Application

A modern, premium billing management application built with **Flutter and Dart** for Shree Shakti Electric. The application simplifies invoice creation, customer management, billing history, PDF generation, and invoice tracking through a clean, responsive interface.

## 📌 Project Overview

**Shree Shakti Electric** is a billing management solution designed to make everyday billing operations faster, easier, and more organized.

The application provides a structured invoice workflow, persistent local database storage, automatic bill numbering, PDF generation, and invoice management.

It supports mobile-first usage while adapting to larger screens such as tablets and Windows desktops.

## ✨ Key Features

### 🔐 Manager Authentication
- Secure login interface for authorized managers.
- Supports two predefined manager accounts.
- Session persistence using SharedPreferences.
- No public registration or sign-up functionality.
- Manager-specific invoice signatures.

### 📊 Dashboard
- Total invoices overview.
- Total revenue calculation.
- Customer statistics.
- Recent invoice activity.
- Quick access to important billing operations.
- Live statistics from the local database.

### 🧾 Invoice Creation
- Three-step invoice creation workflow:
  1. Customer Details
  2. Items & Pricing
  3. Review & Generate
- Add multiple products or services.
- Enter item descriptions, quantities, and rates.
- Automatic amount and total calculations.
- Quick item suggestions.
- Invoice preview before generation.

### 📄 PDF Invoice Generation
- Generate professional PDF invoices.
- Preserve the existing approved invoice layout.
- Include company information and customer details.
- Display item descriptions, quantities, rates, and totals.
- Include applicable terms and conditions.
- Add the authorized manager's signature.
- Share and print generated invoices.

### 📚 Invoice History
- View previously generated invoices.
- Search by invoice number, customer name, or mobile number.
- Filter invoices by date.
- View invoice details.
- Share or print existing PDFs.
- Delete invoices with appropriate confirmation.

### ✏️ Edit Invoice
- Update existing invoice information.
- Add, edit, or remove invoice items.
- Recalculate totals automatically.
- Preserve the original invoice ID and invoice number.
- Update the existing PDF instead of creating a duplicate invoice.

### 🎨 Premium User Interface
- Luxury white theme with balanced colorful accents.
- Clean cards, modern typography, and consistent spacing.
- Responsive mobile, tablet, and desktop layouts.
- Smooth transitions and micro-interactions.
- Toast notifications and confirmation dialogs.
- Navigation drawer for application navigation.

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform UI development |
| Dart | Application programming language |
| SQLite (sqflite) | Local database storage |
| SharedPreferences | Manager session persistence |
| PDF | Invoice PDF generation |
| Printing | PDF printing support |
| Share Plus | Invoice sharing |
| Intl | Currency and date formatting |
| Material Design | UI components and styling |

## 🏗️ Application Architecture

The application follows a structured and reusable architecture to keep the code maintainable and scalable.

```text
lib/
├── core/
│   ├── theme/
│   ├── constants/
│   ├── utils/
│   ├── widgets/
│   └── services/
│
├── data/
│   ├── database/
│   └── models/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── invoice/
│   ├── history/
│   └── settings/
│
├── main.dart
└── app.dart

assets/
└── images/
    ├── hiren.png
    └── suresh.png

test/
```

*Note: This is a conceptual overview. Refer to the actual project folders for the complete and current structure.*

## 🗄️ Database

The application uses a local SQLite database named:

`shree_shakti.db`

### Main Database Tables

| Table | Description |
|---|---|
| `managers` | Stores authorized manager account information |
| `invoices` | Stores invoice and customer information |
| `invoice_items` | Stores individual invoice products and services |

**Database details:**
- Current schema version: 3
- Transaction-based invoice saving and updating.
- Invoice items associated with their respective invoices.
- Sequential invoice numbering.
- Foreign key relationships and cascade handling.

### Invoice Number Format

```text
SE-yyMM-XXX
```

Example:

```text
SE-2611-001
SE-2611-002
SE-2611-003
```

Invoice numbers are generated sequentially.

## 🚀 Getting Started

### Prerequisites

Install the following before running the project:

- Flutter SDK
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code
- Android SDK for Android development
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/Hemang2601/Bill.git
```

### 2. Navigate to the Project

```bash
cd Bill
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Check Flutter Environment

```bash
flutter doctor
```

### 5. Run the Application

```bash
flutter run
```

### 6. Run Tests

```bash
flutter test
```

### 7. Analyze the Project

```bash
flutter analyze
```

## 📱 Supported Platforms

| Platform | Support |
|---|---|
| Android | Primary platform |
| Windows | Desktop support / build readiness |
| iOS | Not yet verified |
| Web | Not yet verified |

## 🔒 Data & Security

- Local SQLite database storage.
- Predefined manager authentication.
- Session persistence.
- Manager-specific invoice signatures.
- Transaction-based invoice operations.
- Confirmation before destructive actions.

**Important:** The current manager password storage implementation has not yet been migrated to a slow password-hashing algorithm. Do not treat the current implementation as production-grade authentication security without that improvement.

## 🧪 Quality Assurance

The latest reported QA results:

- **79 automated tests passed.**
- **Flutter analysis:** No issues found.
- Invoice calculation tests completed.
- Database and invoice workflow tests completed.
- Manager authentication requirements verified.

Windows executable generation still requires the appropriate Windows development environment, including Visual Studio Desktop development with C++ workload and Windows symlink support.

## 📂 Repository

**GitHub:** https://github.com/Hemang2601/Bill

## 👨‍💻 Developer

**Hemang Lakhadiya**

MCA Student | Flutter Developer | Full Stack Developer

## 📄 License

This project is developed for **Shree Shakti Electric**. All rights reserved unless a separate license is added to the repository.

---

<p align="center">
  <strong>⚡ Shree Shakti Electric</strong><br/>
  Smart Billing. Simple Management. Professional Invoices.
</p>
