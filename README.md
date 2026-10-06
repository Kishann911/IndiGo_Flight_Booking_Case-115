<div align="center">

# ✈️ IndiGo Flight Booking & Check-in System

**Cross-Platform Aviation Application · Case Study #115**  
Developed by **[Kishan Ojha](https://github.com/Kishann911)**

[![Flutter](https://img.shields.io/badge/Flutter-3.13.4+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material_3-Expressive_UI-7B2CBF?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
[![Download APK](https://img.shields.io/badge/Download-Android_APK-2EA043?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Kishann911/IndiGo_Flight_Booking_Case-115/releases/latest)
[![Tests](https://img.shields.io/badge/Tests-137_Passing-success?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/Kishann911/IndiGo_Flight_Booking_Case-115)

---

<p align="center">
  A production-ready, cross-platform Flutter application powering <b>End-to-End Flight Booking</b>, <b>Dynamic Fare Engine</b>, <b>Interactive Seat Selection</b>, <b>Web Check-in & BCBP Mobile Boarding Pass</b>, <b>Real-time Flight Tracking</b>, and <b>Simulated RFID Baggage Logistics</b>.
</p>

</div>

---

## 📌 Executive Summary

> **Industry:** Aviation & Passenger Services  
> **Problem Statement:** IndiGo Airlines requires an end-to-end digital solution to streamline multi-segment flight discovery, dynamic pricing transparency, web check-in automation, QR boarding pass issuance, real-time delay tracking, and baggage visibility to mitigate airport counter congestion and enhance passenger retention.

```
       ┌────────────────┐      ┌────────────────┐      ┌────────────────┐
       │  Flight Search │ ───► │ Fare Family    │ ───► │ Cabin Map Seat │
       │  & Fare Grid   │      │ Selection      │      │ Selection      │
       └────────────────┘      └────────────────┘      └────────────────┘
                                                               │
       ┌────────────────┐      ┌────────────────┐              ▼
       │ Mobile Boarding│ ◄─── │ Web Check-In   │ ◄─── ┌────────────────┐
       │ Pass (QR BCBP) │      │ (PNR & Seat)   │      │ Extras & Trip  │
       └────────────────┘      └────────────────┘      │ Summary        │
               │                                       └────────────────┘
               ▼
       ┌────────────────┐      ┌────────────────┐
       │ Live Flight    │      │ RFID Baggage   │
       │ Status & Alert │ ───► │ Tracking       │
       └────────────────┘      └────────────────┘
```

---

## ✨ Key Feature Highlights

<table>
  <tr>
    <td width="50%">
      <h3>📅 Dynamic Fare Calendar (F1)</h3>
      <p>Interactive 60-day fare calendar visualizer powered by <code>PricingEngine.lowestFareForDay</code>. Highlights cheapest travel dates dynamically across search routes.</p>
    </td>
    <td width="50%">
      <h3>✈️ Multi-City Routing Engine</h3>
      <p>Supports 1 to 4 multi-city flight legs with chronological validation, ensuring mandatory 60-minute layover windows between connecting segments.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>💺 Interactive Cabin Map (F3)</h3>
      <p>30-row A–F aircraft seating map with dynamic tier pricing (Legroom, XL, Preferred, Standard), live occupied seat masking, and fee rule enforcement.</p>
    </td>
    <td width="50%">
      <h3>🏷️ Fare Family Matrix (F4)</h3>
      <p>Side-by-side comparison of <b>Lite</b> (Hand bag), <b>Classic</b> (Seat + Meal + 15kg Bag), and <b>Flex</b> (Free cancellation & changes) tier benefits.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>📲 Web Check-in & QR Pass (F5, F6)</h3>
      <p>Automated PNR check-in (T-48h window rule) generating IATA-compliant Barcoded Boarding Pass (BCBP) encrypted QR codes.</p>
    </td>
    <td width="50%">
      <h3>🧳 RFID Baggage Logistics (F8)</h3>
      <p>Real-time RFID luggage lifecycle tracking across 6 check-in to carousel checkpoints with simulated hardware state transitions.</p>
    </td>
  </tr>
</table>

---

## 🗺️ Feature Requirements & Implementation Matrix

| Ref | Requirement | Implementation Target | Key Logic & Data Structures |
|:---:|:---|:---|:---|
| **F1** | Flight Search & Fare Calendar | `lib/screens/search_screen.dart`<br>`lib/screens/fare_calendar_screen.dart` | 60-day price grid via `PricingEngine.lowestFareForDay` |
| **F2** | Flight Results & Sorting | `lib/screens/flight_results_screen.dart` | Sort chips: Cheapest, Earliest, Fastest |
| **F3** | Interactive Cabin Map | `lib/widgets/cabin_map.dart`<br>`lib/screens/seat_selection_screen.dart` | 30×6 grid (`SeatTier` pricing: ₹199–799) |
| **F4** | Fare Family Comparison | `lib/screens/flight_detail_screen.dart`<br>`lib/widgets/fare_family_card.dart` | Tier breakdown: Lite, Classic, Flex |
| **F5** | Web Check-In Module | `lib/screens/checkin_screen.dart` | Rules via `CheckInRules.canCheckIn` |
| **F6** | Mobile Boarding Pass | `lib/screens/boarding_pass_screen.dart` | Encrypted BCBP QR payload generation via `qr_flutter` |
| **F7** | Flight Tracker & Alerts | `lib/screens/flight_status_screen.dart`<br>`lib/state/flight_status_service.dart` | Device clock sync + simulated push event bus |
| **F8** | RFID Baggage Tracker | `lib/screens/baggage_screen.dart`<br>`lib/state/baggage_service.dart` | 6-stage RFID state machine for baggage tracking |
| **F9** | In-flight Meal Pre-Order | `lib/screens/extras_screen.dart` | Dietary & cuisine filtering across 14 menu choices |
| **F10**| Add-ons & Fast Forward | `lib/screens/extras_screen.dart` | Priority boarding (₹299), Excess baggage |
| **F11**| Summary & Pricing Quote | `lib/screens/trip_summary_screen.dart` | Complete itemized fare breakdown & refund policy |
| **F12**| Traveler Profile & Saved Flying | `lib/screens/profile_screen.dart` | Frequent flyer tiering & saved passenger auto-fill |

---

## 🛠️ Architecture & Tech Stack

```
   ┌─────────────────────────────────────────────────────────┐
   │                   Presentation Layer                    │
   │      (Material 3 Components, Screens, Custom Painters)   │
   └────────────────────────────┬────────────────────────────┘
                                │
   ┌────────────────────────────▼────────────────────────────┐
   │                    State Layer                          │
   │     (Provider Stores: Booking, Profile, Status, Bag)     │
   └────────────────────────────┬────────────────────────────┘
                                │
   ┌────────────────────────────▼────────────────────────────┐
   │                   Business & Logic                      │
   │    (PricingEngine, CheckInRules, FlightStatusService)   │
   └─────────────────────────────────────────────────────────┘
```

* **Framework:** Flutter (SDK `^3.13.4`) & Dart
* **Design System:** Material 3 with customized IndiGo Brand Theme Seed (`#2A2F8F`)
* **State Management:** `Provider` (`ChangeNotifier` reactive stores)
* **Local Storage:** `shared_preferences`
* **QR Engine:** `qr_flutter` for BCBP payloads

---

## 📁 Repository Structure

```
lib/
├── main.dart                 # Application root, MultiProvider setup, SnackBar event bus
├── theme.dart                # Material 3 color palettes, typography & spacing tokens
├── models/                   # Pure domain models (Flight, Booking, Seat, Bag, AddOn)
├── data/
│   └── sample_data.dart      # Airports dataset, flight generator & demo seed state
├── logic/                    # Pure Dart domain logic
│   ├── pricing.dart          # PricingEngine: Dynamic pricing & dynamic multiplier math
│   ├── checkin_rules.dart    # CheckInRules: Validation & BCBP QR generator
│   └── formatters.dart       # Currency, date-time & status text formatters
├── state/                    # Reactive state stores
│   ├── booking_store.dart    # Active bookings & checkout draft management
│   ├── flight_status_service.dart # Real-time simulated flight progress service
│   ├── baggage_service.dart  # RFID baggage stage progression service
│   └── profile_store.dart    # User profile & saved passenger directory
├── screens/                  # Feature screen views (Search, Seat Map, Pass, Status)
└── widgets/                  # Reusable UI widgets (CabinMap, FareFamilyCard, PriceText)
```

---

## 🚀 Quick Start Guide

### Prerequisites
* Flutter SDK (3.13.4 or higher)
* Dart SDK (3.0 or higher)

### Run Locally

```bash
# 1. Clone the repository
git clone https://github.com/Kishann911/IndiGo_Flight_Booking_Case-115.git
cd 01_IndiGo_Flight_Booking_Case-115

# 2. Install dependencies
flutter pub get

# 3. Launch Web application
flutter run -d chrome

# 4. Run automated test suite (137 tests)
flutter test
```

---

## 🧪 Testing & Quality Assurance

The codebase includes **137 unit, widget, and end-to-end integration tests** covering edge cases in pricing engines, check-in window rules, seat locks, layout boundaries, and reactive stores.

```bash
# Execute static code analysis
flutter analyze

# Run full test suite
flutter test --reporter=expanded
```

---

## 📜 Disclaimer & Licensing

This repository is a **case-study prototype built for academic & coursework evaluation** (Case #115). All trademarks, logos, and brand names belong to InterGlobe Aviation Limited (IndiGo).
