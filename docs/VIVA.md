# Viva Notes — Case 115: IndiGo Flight Booking & Check-in

## 60–90 second walkthrough

- **Problem.** An airline wants one app for booking, web check-in, boarding pass and live flight status, so fewer passengers need the airport counter.
- **Users.** Passengers booking a trip, and the same passengers on travel day checking in and tracking their flight and bag.
- **Inputs.** Route, date and passenger count; fare family; passenger details; seat and meal choices; add-ons. On travel day: PNR and last name.
- **Core logic.** `PricingEngine` applies a booking-window multiplier (0.85 to 1.30) to a base fare, then adds family charge, seat fee by legroom tier, meals, add-ons and tax (5% plus ₹450 per segment per passenger). `CheckInRules` opens check-in from 48 h to 60 min before departure. The boarding pass QR carries a BCBP-style string.
- **Technology.** Flutter and Dart, Material 3, Provider for state, `shared_preferences` for local storage, `qr_flutter` for the QR code.
- **Output.** A flight list with a fare calendar, side-by-side fare families, a seat map, a fare breakdown, a PNR, a boarding pass with QR, a status tracker and a bag tracker.
- **Validation.** The screens validate forms, and the pure logic is unit-tested at every boundary (multiplier steps, window edges, refund at exactly 2 h). End-to-end widget tests drive a full booking and a check-in.
- **Limitation.** There is no backend and no payment. Flight data is generated, and real-time, push and RFID are simulated on the device.

## Questions and answers

**Why Provider?**
The booking draft, bookings, notifications and status are shared across many screens. Provider with `ChangeNotifier` is simple, is the officially recommended starting point, and is easy to test because the stores take an injected clock and random source. Screens use `context.watch` to rebuild and `context.read` for one-off actions. A heavier option like Bloc would be overkill for a prototype this size.

**Why local persistence?**
The brief has no backend, so bookings, the profile, saved travellers and notifications are stored as JSON in `shared_preferences`. That lets the demo survive a restart, for example a booking still shows in My Trips after relaunch. Keys are versioned (`indigo_bookings_v1`).

**How does dynamic pricing work?**
The days between today and departure pick a multiplier: 30 or more days is 0.85, 15–29 is 0.95, 7–14 is 1.00, 3–6 is 1.15, and 0–2 is 1.30. The base fare is rounded after multiplying. The flight detail screen shows this multiplier ("Booked 34 days ahead · 15% advance-purchase discount applied") with the full table. Family charges (+0 / +800 / +2,200), seats, meals, add-ons and tax are then added. All of this is in `PricingEngine`, which is pure Dart, so it is easy to test. Worked example: base 5,000, 19 days ahead, gives 4,750; two Classic passengers with seats and add-ons total ₹16,051 (see `PRICING_AND_RULES.md`).

**How is the seat map built?**
`CabinLayout.build` generates 30 rows with letters A–F (aisle between C and D), so 180 seats. Each seat's tier comes from its row and letter: rows 1, 12, 13 are xl (₹799), rows 2–5 front (₹449), and the rest standard (₹299) or middle (₹199). About 40% of seats are marked occupied, chosen deterministically from the flight number and date. The `CabinMap` widget draws the grid, colours seats by tier, disables occupied ones, and is reused by both seat selection and check-in.

**How is the QR payload formed?**
`CheckInRules.bcbpPayload` builds a string modelled on the IATA boarding-pass format: `M1{LAST}/{FIRST} E{PNR} {FROM}{TO}6E {NUMBER} {julianDay} Y {SEAT} {sequence}`, for example `M1OJHA/KISHAN EK7Q2ZP DELBOM6E 2175 273 Y 014C 0001`. It is passed to `QrImageView`. It is BCBP-like, not a certified airline barcode.

**How are real-time status and push simulated, and what would production use?**
`FlightStatusService` runs a timer (started only from `main()`) that recomputes each flight's status (scheduled, boarding, departed, en route, landed) and progress from the clock, and occasionally adds a random delay or gate change. Each event goes to `NotificationStore`, which shows a SnackBar and updates the bell badge. In production the status would come from an airline or airport operations feed on a server, pushed to devices with Firebase Cloud Messaging (and APNs on iOS), with the app subscribing to the passenger's flights.

**How is RFID baggage simulated?**
Each bag has an RFID tag id and a list of scans. `BaggageService.scanNext` appends the next of six stages (checked in, security screened, loaded, unloaded, on belt, collected) with a location string and time, and raises a notification. A button or an optional timer triggers it. In production, airport readers would write scans to a backend that the app reads.

**What is the role of ListView, Card and Icon?**
`ListView` gives scrolling lists that build items lazily (flights, trips, notifications). `Card` groups each item as a tappable surface with elevation and rounded corners (a flight, a booking, a fare family). `Icon` gives quick visual meaning (plane, seat, luggage, bell) and is paired with text for accessibility.

**How is Material 3 theming done?**
`AppTheme` in `lib/theme.dart` builds light and dark `ThemeData` with `useMaterial3` from one seed colour (`#2A2F8F`). Widgets read colours from `Theme.of(context).colorScheme`, so the whole app changes consistently. Extra tokens cover fare-family, seat-tier and flight-status colours. Layout adapts with a `NavigationBar` on phones and a `NavigationRail` on wide screens, with content capped at about 1100 px.

**What are the main edge cases?**
Check-in outside 48 h to 60 min is refused; PNR and last name matching ignores case; occupied seats and duplicate seat picks are blocked; a later flight must depart at least 60 min after the previous arrival; check-in can never move a passenger to a dearer seat than the one paid for; a Flex refund is full up to exactly 2 h before departure and zero after (Lite/Classic are zero after departure, and cancelling is blocked after check-in); Lite/Classic refunds never go below zero; corrupt saved data does not crash the app; the demo booking is seeded only once (and re-seeded relative to now if it was untouched and has departed); and screens are checked at 360 px width. The full list is in `APP_FLOW.md`.

**What is stored locally and what is remote?**
Locally (device only): bookings, profile and saved travellers, and notifications, in `shared_preferences`. In memory only: the booking draft, flight tracking and baggage scans. Remote: nothing. There is no server, so all "remote" data is generated in `lib/data/sample_data.dart`.

**What would production improve?**
A backend and real APIs for schedules, inventory and pricing; secure authentication and a payment gateway; Firebase Cloud Messaging for real push; airport and RFID feeds for status and baggage; server-side seat locking so two people cannot take one seat; real BCBP barcodes and wallet passes; encrypted storage for personal data; localisation; and accessibility and integration testing on real devices.
