# IndiGo Flight Booking & Check-in

**Cross Platform Application Development · Case #115 · Kishan Ojha**

A Flutter case-study prototype covering flight search, fare families, seat selection, web check-in, a QR boarding pass, flight status and baggage tracking. It is built with Material 3 and runs on Android, iOS and the web.

## Problem statement

> **Industry:** Aviation. **Problem Statement:** IndiGo Airlines requires a comprehensive Flutter application for flight booking, web check-in, boarding pass generation, and real-time flight status updates to enhance passenger experience and reduce airport counter congestion.
>
> **Technical Implementation:** Multi-city flight search with calendar fare view · Seat selection with interactive aircraft cabin map · Mobile boarding pass with QR code generation · Real-time flight tracking with push notifications for delays/gate changes · Baggage tracker with RFID integration
>
> **Product Building:** Show flight details including duration, layover time, meal options, and baggage allowance with add-on upgrade options.
>
> **Pricing Strategy:** Fare families: Lite (hand baggage only), Classic (1 check-in + meal), Flex (full flexibility) · Dynamic pricing based on booking window (advance purchase discount) · Seat selection fees: ₹199–799 based on legroom · Priority boarding: ₹299 per passenger
>
> **Product Features to be Visible:** (F1) Flight search with calendar showing lowest fares · (F2) Flight list with departure/arrival, duration, stops, price · (F3) Seat selection map with available seats, pricing, legroom info · (F4) Fare family comparison: Lite, Classic, Flex features side-by-side · (F5) Web check-in section with PNR input and seat selection · (F6) Mobile boarding pass with QR code and flight details · (F7) Flight status tracker with real-time updates and notifications · (F8) Baggage tracker with RFID scan and location updates · (F9) Meal pre-order with cuisine options and dietary preferences · (F10) Add-ons section: extra baggage, priority boarding, lounge access · (F11) Trip summary with fare breakdown and cancellation policy · (F12) Profile with frequent flyer number and saved travelers

## Feature map

| Ref | Requirement | Where it is implemented |
|---|---|---|
| F1 | Flight search with fare calendar | `lib/screens/search_screen.dart` (one-way, round trip, multi-city with 2–4 segments, searchable airport picker, 1–6 passengers); `lib/screens/fare_calendar_screen.dart` (60 days, lowest fare per day via `PricingEngine.lowestFareForDay`, cheapest days highlighted) |
| F2 | Flight list | `lib/screens/flight_results_screen.dart` (times, duration, non-stop / stop via, "from ₹", sort chips) |
| F3 | Seat map with price and legroom | `lib/screens/seat_selection_screen.dart` + `lib/widgets/cabin_map.dart` (30 rows x A–F, tiers, occupied seats disabled); tiers in `lib/models/seat.dart` |
| F4 | Fare family comparison | `lib/screens/flight_detail_screen.dart` + `lib/widgets/fare_family_card.dart`; terms in `lib/models/fare_family.dart` |
| F5 | Web check-in (PNR + seat) | `lib/screens/checkin_screen.dart`, rules in `lib/logic/checkin_rules.dart`, `BookingStore.checkIn` |
| F6 | Boarding pass with QR | `lib/screens/boarding_pass_screen.dart` (`qr_flutter`), payload from `CheckInRules.bcbpPayload` |
| F7 | Flight status and notifications | `lib/screens/flight_status_screen.dart`, `lib/state/flight_status_service.dart`, `lib/state/notification_store.dart`, `lib/screens/notifications_screen.dart` (simulated) |
| F8 | Baggage tracker with RFID | `lib/screens/baggage_screen.dart`, `lib/state/baggage_service.dart`, `lib/models/bag.dart` (simulated) |
| F9 | Meal pre-order | `lib/screens/extras_screen.dart` (cuisine and dietary filter chips), 14 meals in `lib/data/sample_data.dart` |
| F10 | Add-ons | `lib/screens/extras_screen.dart`, prices in `lib/models/add_on.dart` |
| F11 | Trip summary, fare breakdown, cancellation policy | `lib/screens/trip_summary_screen.dart`, `PricingEngine.quote` / `cancellationRefund` |
| F12 | Profile, frequent flyer, saved travellers | `lib/screens/profile_screen.dart`, `lib/state/profile_store.dart` |
| Tech | Multi-city search with calendar fare view | `search_screen.dart` + `fare_calendar_screen.dart` |
| Tech | Interactive cabin map | `cabin_map.dart`, reused by seat selection and check-in |
| Tech | Boarding pass QR | `boarding_pass_screen.dart`, `checkin_rules.dart` |
| Tech | Real-time tracking + push for delay/gate | `flight_status_service.dart` (timer + clock), in-app SnackBar in `lib/main.dart` (simulated) |
| Tech | Baggage tracker with RFID | `baggage_service.dart` (simulated) |
| Product | Duration, layover, meals, baggage allowance | `flight_detail_screen.dart` (leg timeline, layover callout, baggage per family) |
| Pricing | Fare families Lite / Classic / Flex | `lib/models/fare_family.dart`, `PricingEngine.familyCharge` |
| Pricing | Booking-window dynamic pricing | `PricingEngine.bookingWindowMultiplier` / `dynamicBaseFare` in `lib/logic/pricing.dart` |
| Pricing | Seat fees ₹199–799 | `lib/models/seat.dart` (`SeatTier.price`), `PricingEngine.seatFee` |
| Pricing | Priority boarding ₹299 per passenger | `lib/models/add_on.dart`, `PricingEngine.addOnCharge` |

## Tech stack

- **Flutter** and **Dart** (SDK ^3.13.4)
- **Material 3** with a seed-colour theme (`#2A2F8F`), light and dark themes defined in `lib/theme.dart`
- **Provider** (`ChangeNotifier` stores) for shared state
- **shared_preferences** for local persistence
- **qr_flutter** for the boarding-pass QR code

## How to run

```bash
flutter pub get
flutter run -d chrome      # or any emulator / device
flutter test               # unit + widget tests
flutter analyze
flutter build web
```

## Demo script

1. Open the app. The **Book** tab shows the search form. Keep DEL to BOM and tap the date field to open the **fare calendar**. The cheapest days are highlighted; pick one.
2. Optionally switch to **Multi-city** to see segment rows added and removed. Later flights only list departures at least 60 minutes after the previous arrival (same-day connections are allowed). Return to one-way and tap **Search flights**.
3. In the **flight list**, compare times, duration, stops and the "from ₹" fare. Try the Cheapest / Earliest / Fastest chips. Tap a flight.
4. On the **flight detail** screen, read the timeline, layover, baggage and meals. The line under the fares shows the booking-window pricing (for example "Booked 34 days ahead · 15% advance-purchase discount applied"); tap it for the full table. Compare **Lite / Classic / Flex** side by side and choose **Classic**.
5. Fill in the **passenger form** (or use "Pick from saved travellers").
6. On the **seat map**, tap a seat to see its price and legroom. Occupied seats are grey and cannot be tapped. Choose a seat and continue.
7. On **Extras**, add **priority boarding** (₹299 per passenger), filter meals by cuisine and diet, and continue.
8. On the **trip summary**, read the fare breakdown and the cancellation policy, then tap **Confirm booking (demo — no payment)**. The **PNR** is shown, and the booking is listed in **My Trips**.
9. Go to **Check-in** and enter the pre-loaded PNR **K7Q2ZP** with last name **Ojha**. The window shows as open. Check in to get the **boarding pass** with a QR code and seat **14C**. At check-in you can move to another standard or middle seat, but paid seats (rows 1–5, exits) are locked with "Fee applies — choose paid seats while booking". The demo booking is re-seeded relative to the current time when it is loaded after its flight has already departed (and it was never cancelled or checked in), so this step always works.
10. Open **Flight Status** and press **Simulate delay** / **Simulate gate change**. A push-style SnackBar labelled "(simulated)" appears and the bell badge updates. Open the **Baggage** tracker (luggage icon) and press **Simulate RFID scan** to walk the bag `6E-RFID-0011523` through its stages.

## Project structure

```
lib/
  main.dart                 app entry, MultiProvider, MaterialApp, simulated push SnackBar
  theme.dart                Material 3 themes, colour tokens, spacing
  models/                   pure data classes (Flight, Booking, Seat, FareBreakdown, Bag, ...)
  data/sample_data.dart     airports, deterministic flight generator, meals, seeded demo booking
  logic/                    PricingEngine, CheckInRules (+ QR payload), Fmt formatters (pure Dart)
  state/                    BookingStore, ProfileStore, NotificationStore,
                            FlightStatusService, BaggageService, ShellController, AppServices
  screens/                  one file per screen (search ... profile)
  widgets/                  CabinMap, FareFamilyCard, JourneyProgress, PriceText, SectionCard, ...
test/                       unit, widget and end-to-end tests
docs/                       APP_FLOW.md, PRICING_AND_RULES.md, VIVA.md
```

## Simulated components

This is a prototype with no backend. These parts are simulated and are labelled "(simulated)" in the app:

- **Real-time flight status:** a local timer (started only from `main()`) recomputes each tracked flight's status and progress from the device clock. Random delays and gate changes are generated locally, and the demo buttons trigger them on demand. No airline or airport data feed is used.
- **Push notifications:** notifications are created inside the app and shown as an in-app SnackBar plus an inbox. There is no Firebase Cloud Messaging and no OS-level notification.
- **RFID baggage tracking:** a "Simulate RFID scan" button (or optional auto-scan timer) moves a bag through six stages. There is no RFID hardware or airport system.
- **Payment:** there is none. Confirming a booking says "Demo booking — no payment is taken". No card or UPI details are collected, and refunds are computed figures only.
- Flights, fares and seat occupancy are generated deterministically from the route and date; they are not real schedules.

## Disclaimer

Case-study prototype for coursework — not affiliated with InterGlobe Aviation / IndiGo.
