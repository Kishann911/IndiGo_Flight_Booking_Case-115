# Pricing and Rules

All amounts are whole rupees. The logic lives in `lib/logic/pricing.dart` and `lib/logic/checkin_rules.dart` (pure Dart, unit-tested).

## 1. Booking-window multiplier

`daysBefore` is the number of calendar days from the booking date to the departure date (time of day ignored). Negative values fall into the last-minute band.

| Days before departure | Multiplier | Meaning |
|---|---|---|
| 30 or more | 0.85 | advance-purchase discount |
| 15 – 29 | 0.95 | |
| 7 – 14 | 1.00 | standard |
| 3 – 6 | 1.15 | |
| 0 – 2 | 1.30 | last minute |

`dynamicBaseFare = round(flight.baseFare x multiplier)`, per passenger per segment. The fare calendar shows the lowest such Lite fare for each day.

## 2. Fare families

The family charge is added to the dynamic base fare, per passenger per segment.

| | Lite | Classic | Flex |
|---|---|---|---|
| Charge on top of base fare | +₹0 | +₹800 | +₹2,200 |
| Hand baggage | 7 kg | 7 kg | 7 kg |
| Check-in baggage | none | 15 kg | 15 kg |
| Meal | not included (pre-order available) | 1 complimentary meal | 1 complimentary meal |
| Date change | ₹2,999 + fare difference | ₹1,999 | free |
| Cancellation | ₹3,999 fee | ₹2,999 fee | free up to 2 h before departure |
| Seat | paid | paid | standard seats free (xl and front still paid) |

## 3. Seat tiers (A320neo, 30 rows x A–F, aisle between C and D)

| Tier | Rows / position | Fee | Legroom |
|---|---|---|---|
| xl | rows 1, 12, 13 | ₹799 | Extra legroom, 34–36 in pitch |
| front | rows 2–5 | ₹449 | Front rows, quick exit |
| standard | other rows, window (A/F) or aisle (C/D) | ₹299 | 28–29 in pitch |
| standardMiddle | other rows, middle (B/E) | ₹199 | 28–29 in pitch |

Flex passengers pay ₹0 for standard and standardMiddle seats.

**Seat changes at check-in never cost money and never raise the price paid.** A passenger with a booked seat may move only to a seat whose fee (`PricingEngine.seatFee` for that segment's fare family) is at most the fee of the booked seat. A passenger with no seat may take only standard or standardMiddle seats ("free seat at check-in (standard seats only)"). Higher-fee seats are locked on the check-in cabin map with "Fee applies — choose paid seats while booking".

## 4. Add-ons

| Add-on | Price | Charged |
|---|---|---|
| Extra baggage 5 kg | ₹1,800 | per booking (flat) |
| Extra baggage 10 kg | ₹3,400 | per booking (flat); mutually exclusive with 5 kg |
| Priority boarding | ₹299 | per passenger |
| Lounge access | ₹1,500 | per passenger |

Meals: 14 meals priced ₹220–₹500. On Classic and Flex each passenger's first meal per segment is free; on Lite every meal is charged.

## 5. Taxes and fees

```
fareSubtotal = baseFare + familyCharges
taxes        = round(0.05 x fareSubtotal) + 450 x segments x passengers
total        = base + family + seats + meals + add-ons + taxes
```

## 6. Cancellation and refund

- **All segments Flex:** full total refunded if cancelled at or before (first departure - 2 h); otherwise 0.
- **Otherwise (Lite / Classic, or mixed):** `max(0, total - sum of per-segment cancellation fee - add-on charges)`. The fee is ₹3,999 per Lite segment and ₹2,999 per Classic segment; a Flex segment inside a mixed booking counts as ₹0.
- Lite / Classic / mixed bookings refund 0 once the first flight has departed; the app explains this in the cancel dialog.
- A booking cannot be cancelled once any passenger has checked in; the Cancel button is disabled and the reason is shown.
- An already-cancelled booking refunds 0.
- Demo only: no money moves.

## 7. Check-in window and boarding zones

- Web check-in opens 48 h before departure (open at exactly 48 h) and closes 60 min before departure (closed at exactly 60 min).
- Window label examples: "Opens in 3 d 4 h", "Open — closes in 5 h 10 m", "Closed".
- Boarding time is departure minus 45 min.

| Boarding zone | Who |
|---|---|
| 1 | priority boarding, or seat rows 1–5 |
| 2 | rows 6–17 |
| 3 | rows 18–30 |

## 8. Worked example

Setup (also asserted in `test/pricing_example_test.dart`, which calls the real `PricingEngine`):
DEL to BOM, one Classic segment, 2 passengers, base fare ₹5,000, booked on 1 Oct 2026 for departure on 20 Oct 2026 (19 days ahead). Seats 12A (xl) and 14C (standard), one meal each, add-ons: priority boarding and extra baggage 5 kg.

| Line | Calculation | Amount |
|---|---|---|
| Multiplier | 19 days falls in 15–29 | x 0.95 |
| Base fare | round(5,000 x 0.95) = 4,750 x 2 passengers | ₹9,500 |
| Family charge | Classic 800 x 2 | ₹1,600 |
| Seat fees | 12A 799 + 14C 299 | ₹1,098 |
| Meals | first meal free on Classic | ₹0 |
| Add-ons | priority 299 x 2 + baggage 1,800 | ₹2,398 |
| Taxes and fees | round(0.05 x 11,100) = 555, plus 450 x 1 x 2 = 900 | ₹1,455 |
| **Total** | 9,500 + 1,600 + 1,098 + 0 + 2,398 + 1,455 | **₹16,051** |
| Refund if cancelled (Classic) | 16,051 - 2,999 - 2,398 | ₹10,654 |
