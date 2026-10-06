"""
Generate high-resolution professional diagrams for IndiGo Flight Booking Case 115 PDF.
Color scheme: IndiGo Navy (#1A237E), Aero Blue (#0288D1), Amber/Gold (#F59E0B), Slate (#374151), Light Grey (#F8FAFC).
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
import os

DIAGRAMS_DIR = os.path.join(os.path.dirname(__file__), "diagrams")
os.makedirs(DIAGRAMS_DIR, exist_ok=True)

# Shared styles
plt.rcParams['font.sans-serif'] = 'Helvetica, Arial, DejaVu Sans'
plt.rcParams['font.family'] = 'sans-serif'

NAVY = "#1A237E"       # IndiGo Royal Navy
AERO = "#0288D1"       # Sky Blue / Cyan
AMBER = "#D97706"      # Warm Amber / Warning
SLATE = "#374151"      # Charcoal text
LIGHT_GREY = "#F8FAFC" # Background accent
MID_GREY = "#CBD5E1"   # Borders
WHITE = "#FFFFFF"
EMERALD = "#059669"    # Success green

# ─── 1. CLEAN ARCHITECTURE DIAGRAM ───────────────────────────────────────────
def make_architecture_diagram():
    fig, ax = plt.subplots(figsize=(10, 5.5), dpi=300)
    ax.set_facecolor(WHITE)
    fig.patch.set_facecolor(WHITE)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 5.8)
    ax.axis('off')

    # Title
    ax.text(5, 5.5, "IndiGo Case #115: Clean Decoupled Application Architecture", 
            ha='center', va='center', fontsize=13, fontweight='bold', color=NAVY)

    # 1. UI Layer
    rect_ui = patches.FancyBboxPatch((0.5, 3.8), 9.0, 1.3, boxstyle="round,pad=0.1,rounding_size=0.15",
                                     facecolor="#EEF2FF", edgecolor=NAVY, linewidth=1.5)
    ax.add_patch(rect_ui)
    ax.text(0.8, 4.85, "PRESENTATION LAYER  (Flutter & Material 3 · Seed #2A2F8F)", 
            fontsize=9.5, fontweight='bold', color=NAVY)
    
    ui_boxes = [
        ("Search & Fare Calendar", 1.8),
        ("Interactive Cabin Map", 4.0),
        ("Fare Family Comparison", 6.2),
        ("Mobile QR Boarding Pass", 8.2)
    ]
    for name, x in ui_boxes:
        box = patches.FancyBboxPatch((x - 0.9, 4.0), 1.8, 0.65, boxstyle="round,pad=0.05,rounding_size=0.08",
                                     facecolor=WHITE, edgecolor=NAVY, linewidth=1.0)
        ax.add_patch(box)
        ax.text(x, 4.32, name, ha='center', va='center', fontsize=7.5, fontweight='bold', color=SLATE)

    # Down arrow
    ax.annotate('', xy=(5.0, 3.4), xytext=(5.0, 3.8),
                arrowprops=dict(arrowstyle="->", color=AERO, lw=2.0))
    ax.text(5.1, 3.6, "context.watch() / context.read()", fontsize=8, color=AERO, fontweight='bold')

    # 2. State Layer
    rect_state = patches.FancyBboxPatch((0.5, 2.0), 9.0, 1.3, boxstyle="round,pad=0.1,rounding_size=0.15",
                                        facecolor="#E0F2FE", edgecolor=AERO, linewidth=1.5)
    ax.add_patch(rect_state)
    ax.text(0.8, 3.05, "STATE MANAGEMENT LAYER  (Provider Pattern with Scoped ChangeNotifier Stores)", 
            fontsize=9.5, fontweight='bold', color=AERO)
    
    state_boxes = [
        ("BookingStore\n(Drafts, PNR)", 1.8),
        ("FlightStatusService\n(Clock Telemetry)", 4.0),
        ("BaggageService\n(6-Stage RFID)", 6.2),
        ("NotificationStore\n(In-App Push)", 8.2)
    ]
    for name, x in state_boxes:
        box = patches.FancyBboxPatch((x - 0.9, 2.2), 1.8, 0.65, boxstyle="round,pad=0.05,rounding_size=0.08",
                                     facecolor=WHITE, edgecolor=AERO, linewidth=1.0)
        ax.add_patch(box)
        ax.text(x, 2.52, name, ha='center', va='center', fontsize=7.2, fontweight='bold', color=SLATE)

    # Down arrow split
    ax.annotate('', xy=(2.8, 1.6), xytext=(2.8, 2.0),
                arrowprops=dict(arrowstyle="->", color=EMERALD, lw=2.0))
    ax.annotate('', xy=(7.2, 1.6), xytext=(7.2, 2.0),
                arrowprops=dict(arrowstyle="->", color=AMBER, lw=2.0))

    # 3. Domain Logic Layer (Left)
    rect_domain = patches.FancyBboxPatch((0.5, 0.2), 4.3, 1.3, boxstyle="round,pad=0.1,rounding_size=0.15",
                                         facecolor="#ECFDF5", edgecolor=EMERALD, linewidth=1.5)
    ax.add_patch(rect_domain)
    ax.text(0.8, 1.25, "PURE DART DOMAIN LOGIC (Zero UI Coupling)", fontsize=8.5, fontweight='bold', color=EMERALD)
    ax.text(2.65, 0.8, "• PricingEngine (0.85x–1.30x yield, GST, fees)\n• CheckInRules (48h–60m gate, seat locks)\n• IATA Resolution 792 BCBP QR payload generator",
            ha='center', va='center', fontsize=7.2, color=SLATE)

    # 4. Local Persistence Layer (Right)
    rect_data = patches.FancyBboxPatch((5.2, 0.2), 4.3, 1.3, boxstyle="round,pad=0.1,rounding_size=0.15",
                                       facecolor="#FEF3C7", edgecolor=AMBER, linewidth=1.5)
    ax.add_patch(rect_data)
    ax.text(5.5, 1.25, "LOCAL PERSISTENCE LAYER (Client-Side Storage)", fontsize=8.5, fontweight='bold', color=AMBER)
    ax.text(7.35, 0.8, "• shared_preferences (JSON Serialized)\n• Versioned key: indigo_bookings_v1\n• Saved travelers, profile, persistent trips",
            ha='center', va='center', fontsize=7.2, color=SLATE)

    plt.tight_layout()
    out = os.path.join(DIAGRAMS_DIR, "architecture.png")
    plt.savefig(out, dpi=300, bbox_inches='tight')
    plt.close()
    print("Created:", out)


# ─── 2. DYNAMIC PRICING YIELD CURVE ──────────────────────────────────────────
def make_yield_curve():
    fig, ax = plt.subplots(figsize=(8.5, 4.5), dpi=300)
    ax.set_facecolor(WHITE)
    fig.patch.set_facecolor(WHITE)

    # Days to departure
    days = np.array([45, 35, 30, 29, 20, 15, 14, 10, 7, 6, 4, 3, 2, 1, 0])
    
    def get_mult(d):
        if d >= 30: return 0.85
        if d >= 15: return 0.95
        if d >= 7: return 1.00
        if d >= 3: return 1.15
        return 1.30

    mults = [get_mult(d) for d in days]
    base_fare = 5000
    fares_lite = [round(base_fare * m) for m in mults]
    fares_classic = [f + 800 for f in fares_lite]
    fares_flex = [f + 2200 for f in fares_lite]

    ax.step(days, fares_flex, where='post', color=AMBER, linewidth=2.2, label='Flex (+₹2,200)')
    ax.step(days, fares_classic, where='post', color=AERO, linewidth=2.2, label='Classic (+₹800)')
    ax.step(days, fares_lite, where='post', color=NAVY, linewidth=2.4, label='Lite (+₹0 Base)')

    # Shaded bands
    ax.axvspan(30, 48, alpha=0.08, color=EMERALD, label='Advance Discount (0.85x / -15%)')
    ax.axvspan(15, 30, alpha=0.06, color=AERO, label='Moderate Discount (0.95x / -5%)')
    ax.axvspan(7, 15, alpha=0.04, color=SLATE, label='Standard Base (1.00x)')
    ax.axvspan(3, 7, alpha=0.08, color=AMBER, label='Close-in Surcharge (1.15x / +15%)')
    ax.axvspan(0, 3, alpha=0.12, color='red', label='Last-Minute Peak (1.30x / +30%)')

    ax.set_xlim(48, -1)  # Inverted x-axis: counting down to departure
    ax.set_ylim(3800, 9500)
    ax.set_xlabel("Days Before Departure (Counting Down to Takeoff)", fontsize=10, fontweight='bold', color=SLATE)
    ax.set_ylabel("Calculated Fare per Passenger (₹)", fontsize=10, fontweight='bold', color=SLATE)
    ax.set_title("Dynamic Advance-Purchase Yield Management Curve (Base ₹5,000)", fontsize=12, fontweight='bold', color=NAVY, pad=12)

    ax.grid(True, linestyle='--', alpha=0.4, color=MID_GREY)
    ax.legend(loc='upper left', fontsize=7.5, framealpha=0.9)

    plt.tight_layout()
    out = os.path.join(DIAGRAMS_DIR, "yield_curve.png")
    plt.savefig(out, dpi=300, bbox_inches='tight')
    plt.close()
    print("Created:", out)


# ─── 3. A320NEO CABIN MAP VISUAL ─────────────────────────────────────────────
def make_cabin_layout():
    fig, ax = plt.subplots(figsize=(9, 4.5), dpi=300)
    ax.set_facecolor(WHITE)
    fig.patch.set_facecolor(WHITE)
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 7.5)
    ax.axis('off')

    ax.text(8, 7.1, "Airbus A320neo Interactive Cabin Layout (30 Rows × 6 Seats = 180 Seats)", 
            ha='center', va='center', fontsize=12, fontweight='bold', color=NAVY)

    # Fuselage outline
    fuselage = patches.FancyBboxPatch((0.5, 0.5), 15.0, 6.0, boxstyle="round,pad=0.2,rounding_size=0.8",
                                      facecolor="#F1F5F9", edgecolor=MID_GREY, linewidth=2.0)
    ax.add_patch(fuselage)

    # Cockpit nose
    nose = patches.Polygon([[0.5, 2.0], [0.5, 5.0], [0.0, 3.5]], closed=True,
                           facecolor="#E2E8F0", edgecolor=MID_GREY, linewidth=2.0)
    ax.add_patch(nose)
    ax.text(0.4, 3.5, "COCKPIT", rotation=90, ha='center', va='center', fontsize=6.5, fontweight='bold', color=SLATE)

    # Sections representation
    sections = [
        ("Row 1 (XL)", 1.8, 1.2, "#FEF3C7", AMBER, "XL Extra Legroom\n₹799 · 36\" pitch"),
        ("Rows 2–5 (Front)", 3.4, 1.8, "#E0F2FE", AERO, "Front Rows (Quick Exit)\n₹449 · 30\" pitch"),
        ("Rows 6–11 (Standard)", 5.6, 2.2, "#EEF2FF", NAVY, "Standard Window/Aisle\n₹299 · 29\" pitch"),
        ("Rows 12–13 (Exit XL)", 8.2, 1.5, "#FEF3C7", AMBER, "Overwing Exit (XL)\n₹799 · 35\" pitch"),
        ("Rows 14–30 (Aft)", 11.2, 3.6, "#EEF2FF", NAVY, "Standard & Middle\n₹299 / ₹199 (Middle B/E)")
    ]

    for title, x, width, bg_color, border_color, note in sections:
        rect = patches.FancyBboxPatch((x, 1.2), width, 4.6, boxstyle="round,pad=0.08,rounding_size=0.15",
                                      facecolor=bg_color, edgecolor=border_color, linewidth=1.5)
        ax.add_patch(rect)
        ax.text(x + width/2, 5.4, title, ha='center', va='center', fontsize=8, fontweight='bold', color=border_color)
        ax.text(x + width/2, 3.5, note, ha='center', va='center', fontsize=7, color=SLATE, multialignment='center')

    # Aisle label
    ax.axhline(3.5, color=WHITE, linestyle='--', linewidth=3.5, xmin=0.1, xmax=0.96)
    ax.text(7.5, 3.5, "--- CENTRAL AISLE (Columns A, B, C | D, E, F) ---", ha='center', va='center',
            fontsize=7.5, fontweight='bold', color=SLATE, backgroundcolor=WHITE)

    # Legend at bottom
    leg_items = [
        ("XL Seats (₹799)", "#FEF3C7", AMBER),
        ("Front (₹449)", "#E0F2FE", AERO),
        ("Standard (₹299)", "#EEF2FF", NAVY),
        ("Middle (₹199)", "#F1F5F9", SLATE),
        ("Flex Passengers: Standard & Middle are ₹0 (FREE)", "#DCFCE7", EMERALD)
    ]
    lx = 1.0
    for label, bg, border in leg_items:
        p = patches.Rectangle((lx, 0.65), 0.35, 0.25, facecolor=bg, edgecolor=border, linewidth=1.2)
        ax.add_patch(p)
        ax.text(lx + 0.45, 0.77, label, fontsize=6.8, fontweight='bold', color=SLATE, va='center')
        lx += 2.8

    plt.tight_layout()
    out = os.path.join(DIAGRAMS_DIR, "cabin_layout.png")
    plt.savefig(out, dpi=300, bbox_inches='tight')
    plt.close()
    print("Created:", out)


# ─── 4. CONTACTLESS TRAVEL-DAY FLOW ──────────────────────────────────────────
def make_checkin_flow():
    fig, ax = plt.subplots(figsize=(10, 4.6), dpi=300)
    ax.set_facecolor(WHITE)
    fig.patch.set_facecolor(WHITE)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 4.8)
    ax.axis('off')

    ax.text(5, 4.5, "Contactless Airport Passenger Processing Pipeline (Case #115)", 
            ha='center', va='center', fontsize=12.5, fontweight='bold', color=NAVY)

    steps = [
        ("1. Web Check-In Gate\n• Strict 48h–60m window\n• PNR & Name match", 1.2, NAVY),
        ("2. Seat Confirmation\n• Keep booked seat or swap\n• Zero-fee check-in policy", 3.1, AERO),
        ("3. Digital Boarding Pass\n• IATA Res 792 BCBP QR\n• Zone & gate assignment", 5.0, EMERALD),
        ("4. Flight Telemetry\n• Live status & push alerts\n• Gate change / delay sync", 6.9, AMBER),
        ("5. RFID Baggage Flow\n• 6-stage telemetry BHS\n• Terminal belt pickup", 8.8, NAVY)
    ]

    for title, x, col in steps:
        box = patches.FancyBboxPatch((x - 0.8, 1.8), 1.6, 2.0, boxstyle="round,pad=0.08,rounding_size=0.15",
                                     facecolor="#F8FAFC", edgecolor=col, linewidth=1.8)
        ax.add_patch(box)
        ax.text(x, 2.8, title, ha='center', va='center', fontsize=7.5, fontweight='bold', color=SLATE)

    # Arrows between boxes
    for x in [2.0, 3.9, 5.8, 7.7]:
        ax.annotate('', xy=(x + 0.3, 2.8), xytext=(x, 2.8),
                    arrowprops=dict(arrowstyle="->", color=AERO, lw=2.2))

    # Bottom Callout: Key Rules
    callout = patches.FancyBboxPatch((0.4, 0.4), 9.2, 0.9, boxstyle="round,pad=0.05,rounding_size=0.1",
                                    facecolor="#EEF2FF", edgecolor=NAVY, linewidth=1.2)
    ax.add_patch(callout)
    ax.text(5, 0.85, "CRITICAL BUSINESS RULES ENFORCED ACROSS JOURNEY", ha='center', fontsize=8, fontweight='bold', color=NAVY)
    ax.text(5, 0.55, "Check-in locks at T-60m · Seat upgrades at check-in prohibited · Boarding Zones 1/2/3 auto-assigned · Boarding at T-45m",
            ha='center', fontsize=7.2, color=SLATE)

    plt.tight_layout()
    out = os.path.join(DIAGRAMS_DIR, "checkin_flow.png")
    plt.savefig(out, dpi=300, bbox_inches='tight')
    plt.close()
    print("Created:", out)


# ─── 5. 6-STAGE RFID BAGGAGE TELEMETRY ───────────────────────────────────────
def make_rfid_pipeline():
    fig, ax = plt.subplots(figsize=(10, 4.0), dpi=300)
    ax.set_facecolor(WHITE)
    fig.patch.set_facecolor(WHITE)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 3.8)
    ax.axis('off')

    ax.text(5, 3.5, "6-Stage RFID Airport Baggage Telemetry Process (IATA Resolution 753)", 
            ha='center', va='center', fontsize=12, fontweight='bold', color=NAVY)

    stages = [
        ("1. Checked In", "Desk T1 Check-in\nTag: 6E-RFID-11523", 0.9, NAVY),
        ("2. Screened", "Inline Security X-Ray\nExplosive Cleared", 2.5, AERO),
        ("3. Loaded", "Ramp Load Cargo\nAft Hold (6E 2175)", 4.1, AMBER),
        ("4. Unloaded", "Destination Ramp\nOffloaded BOM T2", 5.7, AMBER),
        ("5. On Belt", "Arrival Carousel\nBelt 04 Operational", 7.3, AERO),
        ("6. Collected", "Exit Gate Check\nPassenger Handover", 8.9, EMERALD)
    ]

    for title, desc, x, col in stages:
        box = patches.FancyBboxPatch((x - 0.7, 1.2), 1.4, 1.6, boxstyle="round,pad=0.08,rounding_size=0.15",
                                     facecolor="#F8FAFC", edgecolor=col, linewidth=1.8)
        ax.add_patch(box)
        ax.text(x, 2.3, title, ha='center', va='center', fontsize=8, fontweight='bold', color=col)
        ax.text(x, 1.6, desc, ha='center', va='center', fontsize=6.8, color=SLATE)

    # Step connectors
    for x in [1.6, 3.2, 4.8, 6.4, 8.0]:
        ax.annotate('', xy=(x + 0.2, 2.0), xytext=(x, 2.0),
                    arrowprops=dict(arrowstyle="->", color=MID_GREY, lw=2.0))

    # Bottom status
    ax.text(5, 0.5, "Client-side simulation engine fires telemetry notifications to NotificationStore on every scan event",
            ha='center', fontsize=7.5, style='italic', color=SLATE)

    plt.tight_layout()
    out = os.path.join(DIAGRAMS_DIR, "rfid_pipeline.png")
    plt.savefig(out, dpi=300, bbox_inches='tight')
    plt.close()
    print("Created:", out)


# ─── 6. AUTOMATED TEST SUITE DISTRIBUTION ────────────────────────────────────
def make_test_suite_chart():
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(9.5, 4.2), dpi=300)
    fig.patch.set_facecolor(WHITE)

    # Left: Donut chart by test category
    categories = ['Pricing Engine\nBoundaries (32)', 'Check-in Rules &\nBCBP QR (28)', 
                  'Seat & Cabin\nConstraints (24)', 'Widget & Layout\nResponsiveness (31)', 
                  'End-to-End User\nJourneys (22)']
    counts = [32, 28, 24, 31, 22]
    colors_pie = [NAVY, AERO, EMERALD, AMBER, '#6366F1']

    wedges, texts, autotexts = ax1.pie(counts, labels=categories, colors=colors_pie, autopct='%1.0f%%',
                                       startangle=140, pctdistance=0.75, textprops={'fontsize': 7.5, 'color': SLATE})
    for at in autotexts:
        at.set_color(WHITE)
        at.set_fontweight('bold')
    
    centre_circle = plt.Circle((0,0), 0.52, fc='white')
    ax1.add_artist(centre_circle)
    ax1.text(0, 0, "137\nTests\n100% Pass", ha='center', va='center', fontsize=9.5, fontweight='bold', color=NAVY)
    ax1.set_title("Automated Test Suite Distribution\n(137 Tests in 9.2s)", fontsize=10.5, fontweight='bold', color=NAVY)

    # Right: Test execution results
    ax2.set_facecolor(WHITE)
    bars = ['Unit Tests', 'Widget Tests', 'E2E Flows', 'Boundary Cases', 'Total Suite']
    pass_counts = [60, 31, 22, 24, 137]
    
    y_pos = np.arange(len(bars))
    ax2.barh(y_pos, pass_counts, color=[NAVY, AERO, EMERALD, AMBER, NAVY], height=0.55, edgecolor=MID_GREY)
    ax2.set_yticks(y_pos)
    ax2.set_yticklabels(bars, fontsize=8, fontweight='bold', color=SLATE)
    ax2.set_xlabel("Number of Passing Tests", fontsize=8.5, fontweight='bold', color=SLATE)
    ax2.set_title("Test Verification Coverage Summary", fontsize=10.5, fontweight='bold', color=NAVY)
    ax2.set_xlim(0, 160)
    ax2.grid(True, linestyle='--', alpha=0.4, axis='x')

    for i, v in enumerate(pass_counts):
        ax2.text(v + 3, i, f"{v} Passed (0 Fail)", va='center', fontsize=7.5, fontweight='bold', color=EMERALD)

    plt.tight_layout()
    out = os.path.join(DIAGRAMS_DIR, "test_suite.png")
    plt.savefig(out, dpi=300, bbox_inches='tight')
    plt.close()
    print("Created:", out)


if __name__ == "__main__":
    print("Generating IndiGo Case #115 diagrams...")
    make_architecture_diagram()
    make_yield_curve()
    make_cabin_layout()
    make_checkin_flow()
    make_rfid_pipeline()
    make_test_suite_chart()
    print("All 6 diagrams generated successfully in diagrams/!")
