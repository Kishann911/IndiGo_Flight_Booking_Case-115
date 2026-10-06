"""
IndiGo Flight Booking Case 115 — Complete Professional Project PDF Generator
Executive-grade aviation theme: IndiGo Navy (#1A237E), Aero Sky Blue (#0288D1), Warm Amber (#D97706), Slate Grey (#374151).
Includes dynamically calculated TOC page numbers and embedded high-res diagrams.
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, KeepTogether, Image, Flowable
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT, TA_JUSTIFY
from reportlab.pdfgen import canvas as pdfcanvas
import os

PAGE_W, PAGE_H = A4
MARGIN = 2.0 * cm
INNER_W = PAGE_W - 2 * MARGIN

# ─── COLOUR PALETTE ────────────────────────────────────────────────────────────
NAVY       = colors.HexColor("#1A237E")   # IndiGo Deep Royal Navy – headers, accents
AERO       = colors.HexColor("#0288D1")   # Aero Sky Blue – tags, secondary accents
AMBER      = colors.HexColor("#D97706")   # Warm Amber – highlights, warning callouts
EMERALD    = colors.HexColor("#059669")   # Success green – passes, confirmed metrics
SLATE      = colors.HexColor("#374151")   # Slate grey – body text
LIGHT_GREY = colors.HexColor("#F8FAFC")   # Page accent backgrounds
MID_GREY   = colors.HexColor("#CBD5E1")   # Table borders, rules
WHITE      = colors.white
BLACK      = colors.HexColor("#111827")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DIAGRAMS_DIR = os.path.join(SCRIPT_DIR, "diagrams")
OUTPUT = os.path.join(SCRIPT_DIR, "IndiGo_Case115_Full_Report.pdf")

# ─── PAGE TRACKER FLOWABLE ─────────────────────────────────────────────────────
class PageTracker(Flowable):
    """Zero-size flowable that records its current page number into a dictionary."""
    def __init__(self, key, registry):
        super().__init__()
        self.key = key
        self.registry = registry
        self.width = 0
        self.height = 0

    def draw(self):
        self.registry[self.key] = self.canv._pageNumber

# ─── NUMBERED CANVAS FOR HEADER/FOOTER ─────────────────────────────────────────
class NumberedCanvas(pdfcanvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        pg = self._pageNumber
        if pg == 1:
            self.restoreState()
            return

        # Top Running Header
        self.setFont('Helvetica-Bold', 7.5)
        self.setFillColor(NAVY)
        self.drawString(MARGIN, PAGE_H - 1.2*cm, "IndiGo Flight Booking & Check-In  |  Case Study #115")
        self.setFont('Helvetica', 7.5)
        self.setFillColor(SLATE)
        self.drawRightString(PAGE_W - MARGIN, PAGE_H - 1.2*cm, "Cross-Platform Application Development")
        self.setStrokeColor(MID_GREY)
        self.setLineWidth(0.4)
        self.line(MARGIN, PAGE_H - 1.35*cm, PAGE_W - MARGIN, PAGE_H - 1.35*cm)

        # Bottom Navy Bar
        self.setFillColor(NAVY)
        self.rect(0, 0, PAGE_W, 1.0*cm, fill=1, stroke=0)
        
        # Bottom text
        self.setFont('Helvetica', 8)
        self.setFillColor(WHITE)
        self.drawCentredString(PAGE_W/2, 0.35*cm, f"IndiGo Case #115 · Kishan Ojha   |   Page {pg} of {page_count}")
        
        self.setFont('Helvetica', 7)
        self.setFillColor(MID_GREY)
        self.drawString(MARGIN, 0.35*cm, "B.Tech CSE 2025–29 · Semester III")
        self.restoreState()

# ─── STYLES ────────────────────────────────────────────────────────────────────
def build_styles():
    s = {}
    base = getSampleStyleSheet()

    s['cover_title'] = ParagraphStyle('cover_title',
        fontName='Helvetica-Bold', fontSize=26, leading=32,
        textColor=NAVY, spaceAfter=6)

    s['cover_sub'] = ParagraphStyle('cover_sub',
        fontName='Helvetica', fontSize=12, leading=16,
        textColor=SLATE, spaceAfter=4)

    s['section_tag'] = ParagraphStyle('section_tag',
        fontName='Helvetica-Bold', fontSize=8, leading=10,
        textColor=WHITE)

    s['h1'] = ParagraphStyle('h1',
        fontName='Helvetica-Bold', fontSize=16, leading=20,
        textColor=NAVY, spaceBefore=12, spaceAfter=6)

    s['h2'] = ParagraphStyle('h2',
        fontName='Helvetica-Bold', fontSize=11.5, leading=15,
        textColor=NAVY, spaceBefore=9, spaceAfter=4)

    s['h3'] = ParagraphStyle('h3',
        fontName='Helvetica-Bold', fontSize=9.5, leading=13,
        textColor=AERO, spaceBefore=6, spaceAfter=2)

    s['body'] = ParagraphStyle('body',
        fontName='Helvetica', fontSize=8.5, leading=12,
        textColor=SLATE, alignment=TA_JUSTIFY, spaceAfter=4)

    s['body_bold'] = ParagraphStyle('body_bold',
        fontName='Helvetica-Bold', fontSize=8.5, leading=12,
        textColor=BLACK, spaceAfter=4)

    s['bullet'] = ParagraphStyle('bullet',
        fontName='Helvetica', fontSize=8.2, leading=11.5,
        textColor=SLATE, leftIndent=12, firstLineIndent=-8, spaceAfter=2)

    s['callout_text'] = ParagraphStyle('callout_text',
        fontName='Helvetica', fontSize=8.2, leading=11.5,
        textColor=SLATE)

    s['callout_title'] = ParagraphStyle('callout_title',
        fontName='Helvetica-Bold', fontSize=8.8, leading=12,
        textColor=NAVY, spaceAfter=2)

    s['tbl_header'] = ParagraphStyle('tbl_header',
        fontName='Helvetica-Bold', fontSize=7.8, leading=10,
        textColor=WHITE, alignment=TA_CENTER)

    s['tbl_cell'] = ParagraphStyle('tbl_cell',
        fontName='Helvetica', fontSize=7.5, leading=10,
        textColor=SLATE)

    s['tbl_cell_bold'] = ParagraphStyle('tbl_cell_bold',
        fontName='Helvetica-Bold', fontSize=7.5, leading=10,
        textColor=BLACK)

    s['tbl_cell_center'] = ParagraphStyle('tbl_cell_center',
        fontName='Helvetica', fontSize=7.5, leading=10,
        textColor=SLATE, alignment=TA_CENTER)

    s['toc_title'] = ParagraphStyle('toc_title',
        fontName='Helvetica-Bold', fontSize=8.5, leading=11,
        textColor=NAVY)

    s['toc_page'] = ParagraphStyle('toc_page',
        fontName='Helvetica-Bold', fontSize=8.5, leading=11,
        textColor=AERO, alignment=TA_RIGHT)

    s['caption'] = ParagraphStyle('caption',
        fontName='Helvetica-Oblique', fontSize=7.2, leading=9.5,
        textColor=SLATE, alignment=TA_CENTER, spaceBefore=3, spaceAfter=6)

    return s

def make_tag(text, color=AERO):
    return Table(
        [[Paragraph(f"<b>{text.upper()}</b>", ParagraphStyle('t', fontName='Helvetica-Bold', fontSize=7.5, leading=9, textColor=WHITE))]],
        colWidths=[INNER_W],
        style=TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), color),
            ('TOPPADDING', (0,0), (-1,-1), 2.5),
            ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
            ('LEFTPADDING', (0,0), (-1,-1), 6),
            ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ])
    )

def make_callout(title, body, border_color=AERO, bg_color=LIGHT_GREY):
    styles = build_styles()
    content = []
    if title:
        content.append(Paragraph(f"<b>{title}</b>", styles['callout_title']))
    content.append(Paragraph(body, styles['callout_text']))
    t = Table([[content]], colWidths=[INNER_W],
              style=TableStyle([
                  ('BACKGROUND', (0,0), (-1,-1), bg_color),
                  ('BOX', (0,0), (-1,-1), 1.0, border_color),
                  ('LEFTPADDING', (0,0), (-1,-1), 9),
                  ('RIGHTPADDING', (0,0), (-1,-1), 9),
                  ('TOPPADDING', (0,0), (-1,-1), 6),
                  ('BOTTOMPADDING', (0,0), (-1,-1), 6),
              ]))
    return t

# ─── DOCUMENT BUILDER ──────────────────────────────────────────────────────────
def build_pdf(page_dict=None):
    if page_dict is None:
        page_dict = {}

    styles = build_styles()
    story = []

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 1: TITLE & COVER PAGE
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageTracker('cover', page_dict))
    story.append(Spacer(1, 0.5*cm))

    # Aviation Top Ribbon
    top_badge = Table(
        [[Paragraph("<b>INDIAN AVIATION CASE STUDY SERIES · CROSS-PLATFORM MOBILE ENGINEERING</b>", 
                    ParagraphStyle('tb', fontName='Helvetica-Bold', fontSize=8, leading=10, textColor=WHITE, alignment=TA_CENTER))]],
        colWidths=[INNER_W],
        style=TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), NAVY),
            ('TOPPADDING', (0,0), (-1,-1), 4),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ])
    )
    story.append(top_badge)
    story.append(Spacer(1, 0.8*cm))

    story.append(Paragraph("IndiGo Flight Booking &<br/>Contactless Check-In Platform", styles['cover_title']))
    story.append(Paragraph("An End-to-End Cross-Platform Aviation Solution (Flutter · Material 3 · Clean Architecture)", styles['cover_sub']))
    story.append(Spacer(1, 0.4*cm))

    meta_data = [
        [Paragraph("<b>Candidate Author:</b>", styles['tbl_cell_bold']), Paragraph("Kishan Ojha (@Kishann911)", styles['tbl_cell'])],
        [Paragraph("<b>Academic Programme:</b>", styles['tbl_cell_bold']), Paragraph("B.Tech Computer Science & Engineering (2025–29), Semester III", styles['tbl_cell'])],
        [Paragraph("<b>Course Specialisation:</b>", styles['tbl_cell_bold']), Paragraph("Cross-Platform Application Development (Flutter & Dart)", styles['tbl_cell'])],
        [Paragraph("<b>Case Study Ref:</b>", styles['tbl_cell_bold']), Paragraph("Case #115 · IndiGo Commercial Aviation Operations", styles['tbl_cell'])],
        [Paragraph("<b>Automated Test Suite:</b>", styles['tbl_cell_bold']), Paragraph("<b>137 / 137 Tests Passing (100% Success Rate in 9.2s)</b>", styles['tbl_cell'])],
        [Paragraph("<b>Core Technology:</b>", styles['tbl_cell_bold']), Paragraph("Flutter 3.13 · Dart · Material 3 (Seed #2A2F8F) · Provider State Management", styles['tbl_cell'])],
    ]
    meta_table = Table(meta_data, colWidths=[4.2*cm, INNER_W - 4.2*cm],
                       style=TableStyle([
                           ('BACKGROUND', (0,0), (-1,-1), LIGHT_GREY),
                           ('BOX', (0,0), (-1,-1), 0.8, MID_GREY),
                           ('INNERGRID', (0,0), (-1,-1), 0.3, MID_GREY),
                           ('TOPPADDING', (0,0), (-1,-1), 4),
                           ('BOTTOMPADDING', (0,0), (-1,-1), 4),
                           ('LEFTPADDING', (0,0), (-1,-1), 8),
                           ('RIGHTPADDING', (0,0), (-1,-1), 8),
                       ]))
    story.append(meta_table)
    story.append(Spacer(1, 0.6*cm))

    # Executive Overview Callout
    exec_text = (
        "<b>Executive Summary:</b> Airport counter congestion and manual check-in processing remain among the most significant "
        "operational cost drivers for low-cost commercial carriers. Case #115 specifies an end-to-end digital mobile platform "
        "for IndiGo Airlines engineered with Flutter. The solution incorporates an advance-purchase dynamic yield curve (0.85x–1.30x), "
        "three unbundled fare families (Lite, Classic, Flex), an interactive 30-row A320neo cabin map (₹199–₹799 legroom tiers), "
        "a strict 48h–60m web check-in temporal gate, IATA Resolution 792 BCBP 2D QR boarding passes, real-time push telemetry, "
        "and a 6-stage RFID baggage handling system. All domain logic is decoupled into pure Dart engines verified against 137 tests."
    )
    story.append(make_callout("EXECUTIVE OVERVIEW & PROBLEM STATEMENT", exec_text, border_color=NAVY))
    story.append(Spacer(1, 0.6*cm))

    # Key Quantitative Metrics Cards
    metrics_data = [
        [
            Paragraph("<font size=13><b>137</b></font><br/><b>Automated Tests</b><br/>Unit, Widget & E2E", styles['tbl_cell_center']),
            Paragraph("<font size=13><b>0.85 – 1.30x</b></font><br/><b>Dynamic Yield Curve</b><br/>Advance-Purchase Model", styles['tbl_cell_center']),
            Paragraph("<font size=13><b>30 Rows / 180</b></font><br/><b>A320neo Cabin Seats</b><br/>4 Legroom Pricing Tiers", styles['tbl_cell_center']),
            Paragraph("<font size=13><b>48h – 60m</b></font><br/><b>Web Check-In Window</b><br/>IATA BCBP 2D QR Pass", styles['tbl_cell_center']),
        ]
    ]
    metrics_table = Table(metrics_data, colWidths=[INNER_W/4.0]*4,
                          style=TableStyle([
                              ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#EEF2FF")),
                              ('BOX', (0,0), (-1,-1), 1.0, NAVY),
                              ('INNERGRID', (0,0), (-1,-1), 0.5, MID_GREY),
                              ('TOPPADDING', (0,0), (-1,-1), 6),
                              ('BOTTOMPADDING', (0,0), (-1,-1), 6),
                          ]))
    story.append(metrics_table)

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 2: TABLE OF CONTENTS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('toc', page_dict))
    story.append(make_tag("DOCUMENT NAVIGATION & INDEX", color=NAVY))
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Table of Contents", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.5, color=NAVY, spaceAfter=8))

    def get_pg(key, default="--"):
        return str(page_dict.get(key, default))

    toc_entries = [
        ("1. Aviation Industry Problem Space & Requirements Engineering", get_pg('sec1', '3')),
        ("2. Clean Software Architecture & Flutter / Dart Design Pattern", get_pg('sec2', '4')),
        ("3. Revenue Management & Dynamic Pricing Strategy (Yield Curve)", get_pg('sec3', '5')),
        ("4. Interactive Aircraft Cabin Map (A320neo 180-Seat Geometry)", get_pg('sec4', '7')),
        ("5. Contactless Travel-Day Flow & IATA BCBP Standards", get_pg('sec5', '8')),
        ("6. Real-Time Telemetry: Flight Status & 6-Stage RFID Baggage", get_pg('sec6', '9')),
        ("7. Quality Assurance, Test Suite & Boundary Value Verification", get_pg('sec7', '10')),
        ("8. Production Gap Analysis & Enterprise Roadmap (Redis, FCM, PCI)", get_pg('sec8', '11')),
        ("9. Comprehensive Technical Glossary & Viva Defense Cheat Sheet", get_pg('sec9', '12')),
    ]

    toc_table_data = []
    for title, pnum in toc_entries:
        toc_table_data.append([
            Paragraph(f"<b>{title}</b>", styles['toc_title']),
            Paragraph(f"<b>Page {pnum}</b>", styles['toc_page'])
        ])

    toc_table = Table(toc_table_data, colWidths=[INNER_W - 2.5*cm, 2.5*cm],
                      style=TableStyle([
                          ('LINEBELOW', (0,0), (-1,-1), 0.4, MID_GREY),
                          ('TOPPADDING', (0,0), (-1,-1), 4.5),
                          ('BOTTOMPADDING', (0,0), (-1,-1), 4.5),
                      ]))
    story.append(toc_table)
    story.append(Spacer(1, 0.8*cm))

    # Architecture Overview Callout
    story.append(make_callout("ABOUT THIS TECHNICAL REPORT", 
        "This engineering report serves as the formal architectural documentation and viva examination defense guide "
        "for Case #115. It details the operational problem space, software design patterns, dynamic yield algorithms, "
        "aircraft cabin mathematics, aviation barcode standards, verification logs, and enterprise production gaps.",
        border_color=AERO))

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 3: SECTION 1 — AVIATION PROBLEM SPACE & REQUIREMENTS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec1', page_dict))
    story.append(make_tag("SECTION 1 · PROBLEM STATEMENT & SPECIFICATIONS", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("1. Aviation Industry Problem Space & Requirements", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("1.1 The Operational Bottleneck in Low-Cost Aviation", styles['h2']))
    story.append(Paragraph(
        "Commercial domestic carriers operate under strict aircraft turnaround constraints (often 25–30 minutes at gates). "
        "When passengers rely on physical airport check-in counters, three critical system failures occur: "
        "(1) <b>Airport Counter Congestion:</b> Physical terminals experience intense queue spikes 90 minutes before flight departures, "
        "requiring large airport staffing allocations and leasing multiple desk spaces. "
        "(2) <b>Seat Allocation Friction:</b> Dispersed manual seat requests delay manifest finalization and boarding pass printing. "
        "(3) <b>Baggage Tracking Anxiety:</b> Passengers experience severe information asymmetry regarding checked baggage location, "
        "increasing inquiries at service counters. Case #115 delivers a unified cross-platform mobile system eliminating physical counter dependencies.",
        styles['body']))

    story.append(Paragraph("1.2 Functional Requirements Traceability Matrix (F1 to F12)", styles['h2']))
    
    fr_data = [
        [Paragraph("Ref", styles['tbl_header']), Paragraph("Feature Requirement", styles['tbl_header']), Paragraph("Technical Architecture & Implementation", styles['tbl_header']), Paragraph("Status", styles['tbl_header'])],
        [Paragraph("F1", styles['tbl_cell_bold']), Paragraph("Flight Search & Fare Calendar", styles['tbl_cell']), Paragraph("One-way, round-trip, multi-city; 60-day lowest fare evaluation via PricingEngine.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F2", styles['tbl_cell_bold']), Paragraph("Flight Results List", styles['tbl_cell']), Paragraph("Sort chips (cheapest, earliest, fastest), duration, stops, dynamic base fare.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F3", styles['tbl_cell_bold']), Paragraph("Interactive Cabin Map", styles['tbl_cell']), Paragraph("A320neo 30-row layout; color-coded legroom tiers; responsive down to 32px.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F4", styles['tbl_cell_bold']), Paragraph("Fare Family Comparison", styles['tbl_cell']), Paragraph("Side-by-side Lite (+₹0), Classic (+₹800), and Flex (+₹2,200) unbundled cards.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F5", styles['tbl_cell_bold']), Paragraph("Web Check-In Section", styles['tbl_cell']), Paragraph("PNR + Last Name authentication; strict 48h to 60m gate; zero-fee seat swaps.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F6", styles['tbl_cell_bold']), Paragraph("Mobile Boarding Pass", styles['tbl_cell']), Paragraph("IATA Resolution 792 2D BCBP QR payload, Zone 1/2/3 assignment, T-45m boarding.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F7", styles['tbl_cell_bold']), Paragraph("Flight Status Tracker", styles['tbl_cell']), Paragraph("Clock-anchored telemetry; simulated gate changes and delay push notifications.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F8", styles['tbl_cell_bold']), Paragraph("RFID Baggage Tracker", styles['tbl_cell']), Paragraph("6-stage simulated Baggage Handling System (BHS) telemetry tracking.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F9", styles['tbl_cell_bold']), Paragraph("Meal Pre-Order Selection", styles['tbl_cell']), Paragraph("14 gourmet meals with regional cuisine and dietary filter chips (Free on Classic/Flex).", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F10", styles['tbl_cell_bold']), Paragraph("Ancillary Add-ons", styles['tbl_cell']), Paragraph("Priority boarding (₹299), extra baggage 5kg/10kg, airport lounge access.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F11", styles['tbl_cell_bold']), Paragraph("Trip Summary & Policies", styles['tbl_cell']), Paragraph("Itemized fare breakdown, GST calculations, dynamic cancellation refund engine.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
        [Paragraph("F12", styles['tbl_cell_bold']), Paragraph("User Profile & Saved Pax", styles['tbl_cell']), Paragraph("6E Rewards frequent flyer profile, saved co-travelers with single-tap autofill.", styles['tbl_cell']), Paragraph("100% Pass", styles['tbl_cell_center'])],
    ]
    fr_table = Table(fr_data, colWidths=[1.1*cm, 4.2*cm, INNER_W - 6.8*cm, 1.5*cm],
                     style=TableStyle([
                         ('BACKGROUND', (0,0), (-1,0), NAVY),
                         ('BOX', (0,0), (-1,-1), 0.8, MID_GREY),
                         ('INNERGRID', (0,0), (-1,-1), 0.3, MID_GREY),
                         ('TOPPADDING', (0,0), (-1,-1), 3),
                         ('BOTTOMPADDING', (0,0), (-1,-1), 3),
                         ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, LIGHT_GREY]),
                     ]))
    story.append(fr_table)

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 4: SECTION 2 — CLEAN ARCHITECTURE & FLUTTER DESIGN
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec2', page_dict))
    story.append(make_tag("SECTION 2 · SOFTWARE ARCHITECTURE & PATTERNS", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("2. Clean Architecture & Flutter / Dart Framework", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("2.1 Architectural Layering & Decoupled State Design", styles['h2']))
    story.append(Paragraph(
        "The application strictly implements **Separation of Concerns (SoC)** by isolating domain business logic from the UI widget tree. "
        "Rather than mixing calculation code into view widgets, all revenue calculations (`PricingEngine`), check-in constraints (`CheckInRules`), "
        "and boarding barcode algorithms live in a pure Dart domain layer containing zero Flutter dependencies. "
        "State synchronization across screens is managed via the **Provider pattern** with scoped `ChangeNotifier` stores.",
        styles['body']))

    arch_img_path = os.path.join(DIAGRAMS_DIR, "architecture.png")
    if os.path.exists(arch_img_path):
        story.append(Image(arch_img_path, width=INNER_W, height=5.2*cm))
        story.append(Paragraph("Figure 2.1: Clean Architecture Diagram — Presentation, State Management, Domain Logic & Local Storage.", styles['caption']))

    story.append(Paragraph("2.2 Key Architectural Tenets", styles['h2']))
    story.append(Paragraph("• <b>Material 3 Dynamic Theming:</b> Master theme derived from seed token `#2A2F8F`, dynamically generating tonal surfaces for dark and light modes.", styles['bullet']))
    story.append(Paragraph("• <b>Selective Reactive Rebuilding:</b> Widgets consume `context.watch<T>()` strictly for reactive data display, and `context.read<T>()` within click callbacks, preventing redundant widget builds.", styles['bullet']))
    story.append(Paragraph("• <b>Defensive JSON Deserialization:</b> Local state is persisted into `shared_preferences` under versioned keys (`indigo_bookings_v1`) wrapped in try-catch guards to eliminate crash potential.", styles['bullet']))

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 5: SECTION 3 — REVENUE MANAGEMENT & DYNAMIC PRICING
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec3', page_dict))
    story.append(make_tag("SECTION 3 · REVENUE MANAGEMENT & MATHEMATICS", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("3. Revenue Management & Dynamic Pricing Strategy", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("3.1 Advance-Purchase Yield Management Multipliers", styles['h2']))
    story.append(Paragraph(
        "Commercial airlines practice yield management to incentivize early bookings and capture premium willingness-to-pay "
        "for urgent, last-minute travel. In `PricingEngine.bookingWindowMultiplier`, the base fare is dynamically scaled by a multiplier "
        "parameterized by calendar days before departure ($D$):", styles['body']))

    yield_data = [
        [Paragraph("Days to Departure ($D$)", styles['tbl_header']), Paragraph("Multiplier", styles['tbl_header']), Paragraph("Commercial Pricing Rationale", styles['tbl_header']), Paragraph("UI Callout Banner", styles['tbl_header'])],
        [Paragraph("30 or more days", styles['tbl_cell_bold']), Paragraph("<b>0.85x</b> (-15%)", styles['tbl_cell_center']), Paragraph("Advance-purchase discount to build early load factor", styles['tbl_cell']), Paragraph("15% advance-purchase discount applied", styles['tbl_cell'])],
        [Paragraph("15 to 29 days", styles['tbl_cell_bold']), Paragraph("<b>0.95x</b> (-5%)", styles['tbl_cell_center']), Paragraph("Moderate advance-purchase incentive", styles['tbl_cell']), Paragraph("5% advance-purchase discount applied", styles['tbl_cell'])],
        [Paragraph("7 to 14 days", styles['tbl_cell_bold']), Paragraph("<b>1.00x</b> (Base)", styles['tbl_cell_center']), Paragraph("Standard published inventory base fare", styles['tbl_cell']), Paragraph("Standard base fare", styles['tbl_cell'])],
        [Paragraph("3 to 6 days", styles['tbl_cell_bold']), Paragraph("<b>1.15x</b> (+15%)", styles['tbl_cell_center']), Paragraph("Close-in corporate and urgent travel demand surcharge", styles['tbl_cell']), Paragraph("Close-in booking demand rate", styles['tbl_cell'])],
        [Paragraph("0 to 2 days", styles['tbl_cell_bold']), Paragraph("<b>1.30x</b> (+30%)", styles['tbl_cell_center']), Paragraph("Last-minute emergency peak demand rate", styles['tbl_cell']), Paragraph("Last-minute booking demand rate", styles['tbl_cell'])],
    ]
    yield_table = Table(yield_data, colWidths=[3.2*cm, 2.2*cm, 6.2*cm, INNER_W - 11.6*cm],
                        style=TableStyle([
                            ('BACKGROUND', (0,0), (-1,0), NAVY),
                            ('BOX', (0,0), (-1,-1), 0.8, MID_GREY),
                            ('INNERGRID', (0,0), (-1,-1), 0.3, MID_GREY),
                            ('TOPPADDING', (0,0), (-1,-1), 3),
                            ('BOTTOMPADDING', (0,0), (-1,-1), 3),
                            ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, LIGHT_GREY]),
                        ]))
    story.append(yield_table)
    story.append(Spacer(1, 0.4*cm))

    yield_img_path = os.path.join(DIAGRAMS_DIR, "yield_curve.png")
    if os.path.exists(yield_img_path):
        story.append(Image(yield_img_path, width=INNER_W, height=5.0*cm))
        story.append(Paragraph("Figure 3.1: Dynamic Advance-Purchase Yield Management Curve Across Fare Families.", styles['caption']))

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 6: SECTION 3 (CONT.) — FARE FAMILIES & WORKED EXAMPLE
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(make_tag("SECTION 3 (CONT.) · FARE FAMILIES & WORKED EXAMPLE", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("3.2 Fare Family Comparison Matrix", styles['h2']))

    family_data = [
        [Paragraph("Feature Specification", styles['tbl_header']), Paragraph("Lite Tier", styles['tbl_header']), Paragraph("Classic Tier", styles['tbl_header']), Paragraph("Flex Tier", styles['tbl_header'])],
        [Paragraph("Family Charge on Base", styles['tbl_cell_bold']), Paragraph("<b>+₹0</b> per pax", styles['tbl_cell_center']), Paragraph("<b>+₹800</b> per pax", styles['tbl_cell_center']), Paragraph("<b>+₹2,200</b> per pax", styles['tbl_cell_center'])],
        [Paragraph("Cabin Baggage", styles['tbl_cell']), Paragraph("7 kg included", styles['tbl_cell_center']), Paragraph("7 kg included", styles['tbl_cell_center']), Paragraph("7 kg included", styles['tbl_cell_center'])],
        [Paragraph("Check-in Baggage", styles['tbl_cell']), Paragraph("<b>None (0 kg)</b>", styles['tbl_cell_center']), Paragraph("<b>15 kg included</b>", styles['tbl_cell_center']), Paragraph("<b>15 kg included</b>", styles['tbl_cell_center'])],
        [Paragraph("In-flight Meal", styles['tbl_cell']), Paragraph("Paid pre-order", styles['tbl_cell_center']), Paragraph("<b>1 Complimentary meal</b>", styles['tbl_cell_center']), Paragraph("<b>1 Complimentary meal</b>", styles['tbl_cell_center'])],
        [Paragraph("Seat Selection", styles['tbl_cell']), Paragraph("All seats paid", styles['tbl_cell_center']), Paragraph("All seats paid", styles['tbl_cell_center']), Paragraph("<b>Standard/Middle FREE</b>", styles['tbl_cell_center'])],
        [Paragraph("Date Change Penalty", styles['tbl_cell']), Paragraph("₹2,999 + fare diff", styles['tbl_cell_center']), Paragraph("₹1,999 + fare diff", styles['tbl_cell_center']), Paragraph("<b>FREE (₹0 penalty)</b>", styles['tbl_cell_center'])],
        [Paragraph("Cancellation Penalty", styles['tbl_cell']), Paragraph("₹3,999 fee", styles['tbl_cell_center']), Paragraph("₹2,999 fee", styles['tbl_cell_center']), Paragraph("<b>FREE up to 2h pre-flight</b>", styles['tbl_cell_center'])],
    ]
    family_table = Table(family_data, colWidths=[4.2*cm, 4.0*cm, 4.0*cm, INNER_W - 12.2*cm],
                         style=TableStyle([
                             ('BACKGROUND', (0,0), (-1,0), NAVY),
                             ('BOX', (0,0), (-1,-1), 0.8, MID_GREY),
                             ('INNERGRID', (0,0), (-1,-1), 0.3, MID_GREY),
                             ('TOPPADDING', (0,0), (-1,-1), 3.5),
                             ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
                             ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, LIGHT_GREY]),
                         ]))
    story.append(family_table)
    story.append(Spacer(1, 0.4*cm))

    story.append(Paragraph("3.3 Comprehensive Worked Numerical Calculation", styles['h2']))
    story.append(Paragraph(
        "To verify algorithmic determinism, this exact worked case is asserted in automated unit test `test/pricing_example_test.dart`:<br/>"
        "<b>Scenario:</b> Route DEL to BOM (1 segment), <b>2 passengers</b>, Base Fare ₹5,000, booked 19 days ahead (falling in the 15–29 day bracket). "
        "Fare Family: <b>Classic</b>. Seats: <b>12A (XL - ₹799)</b> and <b>14C (Standard - ₹299)</b>. Add-ons: <b>Priority Boarding (₹299 x 2 = ₹598)</b> "
        "and <b>Extra Baggage 5kg (₹1,800 flat)</b>. Meals: 1 free Classic meal per passenger.",
        styles['body']))

    calc_data = [
        [Paragraph("Itemized Fare Line", styles['tbl_header']), Paragraph("Formula / Multiplier Calculation", styles['tbl_header']), Paragraph("Computed Subtotal (₹)", styles['tbl_header'])],
        [Paragraph("Dynamic Base Fare", styles['tbl_cell_bold']), Paragraph("round(₹5,000 x 0.95) = ₹4,750 x 2 passengers", styles['tbl_cell']), Paragraph("₹9,500", styles['tbl_cell_center'])],
        [Paragraph("Fare Family Surcharge", styles['tbl_cell_bold']), Paragraph("Classic Tier surcharge ₹800 x 2 passengers", styles['tbl_cell']), Paragraph("₹1,600", styles['tbl_cell_center'])],
        [Paragraph("Seat Allocation Fees", styles['tbl_cell_bold']), Paragraph("Seat 12A (XL: ₹799) + Seat 14C (Standard: ₹299)", styles['tbl_cell']), Paragraph("₹1,098", styles['tbl_cell_center'])],
        [Paragraph("In-flight Catering", styles['tbl_cell_bold']), Paragraph("First meal included under Classic entitlement", styles['tbl_cell']), Paragraph("₹0", styles['tbl_cell_center'])],
        [Paragraph("Ancillary Add-ons", styles['tbl_cell_bold']), Paragraph("Priority Boarding (₹299 x 2 = ₹598) + Extra Baggage 5kg (₹1,800)", styles['tbl_cell']), Paragraph("₹2,398", styles['tbl_cell_center'])],
        [Paragraph("Statutory Taxes & Fees", styles['tbl_cell_bold']), Paragraph("5% GST on (₹9,500 + ₹1,600) = ₹555 + (₹450 x 1 seg x 2 pax) = ₹900", styles['tbl_cell']), Paragraph("₹1,455", styles['tbl_cell_center'])],
        [Paragraph("<b>FINAL TOTAL QUOTE</b>", styles['tbl_header']), Paragraph("<b>Sum of all itemized tariff components</b>", styles['tbl_header']), Paragraph("<b>₹16,051</b>", styles['tbl_header'])],
    ]
    calc_table = Table(calc_data, colWidths=[4.2*cm, INNER_W - 7.2*cm, 3.0*cm],
                       style=TableStyle([
                           ('BACKGROUND', (0,0), (-1,0), NAVY),
                           ('BACKGROUND', (0,-1), (-1,-1), AERO),
                           ('BOX', (0,0), (-1,-1), 0.8, MID_GREY),
                           ('INNERGRID', (0,0), (-1,-1), 0.3, MID_GREY),
                           ('TOPPADDING', (0,0), (-1,-1), 3),
                           ('BOTTOMPADDING', (0,0), (-1,-1), 3),
                           ('ROWBACKGROUNDS', (0,1), (-1,-2), [WHITE, LIGHT_GREY]),
                       ]))
    story.append(calc_table)

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 7: SECTION 4 — INTERACTIVE AIRCRAFT CABIN MAP
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec4', page_dict))
    story.append(make_tag("SECTION 4 · CABIN GEOMETRY & SEAT ALLOCATION", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("4. Interactive Aircraft Cabin Map (A320neo)", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("4.1 Cabin Geometry & Legroom Pricing Tiers", styles['h2']))
    story.append(Paragraph(
        "The aircraft layout simulates IndiGo's standard **Airbus A320neo** single-aisle configuration, consisting of "
        "**30 rows with 6 seats each (A, B, C | D, E, F)** totaling **180 seats**. The central aisle runs between columns C and D. "
        "Seats are dynamically classified into four discrete pricing and legroom tiers:", styles['body']))

    cabin_img_path = os.path.join(DIAGRAMS_DIR, "cabin_layout.png")
    if os.path.exists(cabin_img_path):
        story.append(Image(cabin_img_path, width=INNER_W, height=4.8*cm))
        story.append(Paragraph("Figure 4.1: A320neo Interactive Cabin Layout with Color-Coded Legroom Tiers.", styles['caption']))

    story.append(Paragraph("4.2 Seat Pricing Tiers & Check-In Locking Constraints", styles['h2']))
    story.append(Paragraph("• <b>XL Seats (Rows 1, 12, 13) — ₹799:</b> Extra legroom (34–36 in pitch). Located at front bulkhead and overwing emergency exits.", styles['bullet']))
    story.append(Paragraph("• <b>Front Seats (Rows 2–5) — ₹449:</b> Standard legroom (29–30 in pitch) optimized for rapid aircraft deboarding upon arrival.", styles['bullet']))
    story.append(Paragraph("• <b>Standard Seats (Rows 6–30, Window A/F & Aisle C/D) — ₹299:</b> Standard 28–29 in pitch.", styles['bullet']))
    story.append(Paragraph("• <b>Standard Middle (Rows 6–30, Middle B/E) — ₹199:</b> Center seats priced at a discount to incentivize voluntary selection.", styles['bullet']))
    story.append(Paragraph("• <b>Flex Entitlement:</b> Flex passengers receive Standard Window/Aisle and Middle seats for **₹0 (Free)**.", styles['bullet']))
    story.append(Paragraph("• <b>Zero-Fee Check-In Rule:</b> Seat modifications during web check-in can never increase the total amount paid. A passenger may only swap to a seat whose fee is &le; the fee previously paid. Premium XL seats are locked with the tooltip: <i>'Fee applies — choose paid seats while booking'</i>.", styles['bullet']))

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 8: SECTION 5 — CONTACTLESS TRAVEL-DAY FLOW & IATA STANDARDS
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec5', page_dict))
    story.append(make_tag("SECTION 5 · TRAVEL-DAY ENGINE & IATA STANDARDS", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("5. Contactless Travel-Day Flow & IATA Standards", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("5.1 Temporal Check-In Governance (48h to 60m Gate)", styles['h2']))
    story.append(Paragraph(
        "To ensure airport security compliance and prevent manifest desynchronization, web check-in is governed by a strict temporal window: "
        "Check-in strictly opens **48 hours** prior to departure and closes **60 minutes** prior to departure. "
        "Prior to the 48-hour boundary, the UI renders dynamic countdown badges (e.g. <i>'Opens in 1 d 8 h'</i>). "
        "After the 60-minute cutoff, check-in is locked and passengers are instructed to report to the airport counter.",
        styles['body']))

    flow_img_path = os.path.join(DIAGRAMS_DIR, "checkin_flow.png")
    if os.path.exists(flow_img_path):
        story.append(Image(flow_img_path, width=INNER_W, height=4.5*cm))
        story.append(Paragraph("Figure 5.1: Contactless Passenger Travel-Day Processing Pipeline.", styles['caption']))

    story.append(Paragraph("5.2 IATA Resolution 792 Bar Coded Boarding Pass (BCBP)", styles['h2']))
    story.append(Paragraph(
        "Rather than rendering an arbitrary URL or dummy payload, the digital boarding pass QR code encodes data strictly formatted "
        "according to **IATA Resolution 792 (BCBP standard)** for 2D barcode imagers:<br/>"
        "<code>M1OJHA/KISHAN EK7Q2ZP DELBOM6E 2175 273 Y 014C 0001</code><br/>"
        "• <b>M1:</b> Format code (Single segment electronic boarding pass).<br/>"
        "• <b>OJHA/KISHAN:</b> Passenger surname and given name.<br/>"
        "• <b>EK7Q2ZP:</b> Electronic ticket indicator ('E') concatenated with 6-character PNR.<br/>"
        "• <b>DELBOM6E:</b> Origin IATA (DEL), Destination IATA (BOM), Airline Designator (6E = IndiGo).<br/>"
        "• <b>2175:</b> Flight designator number.<br/>"
        "• <b>273:</b> Julian day of departure (Day 273 = September 30).<br/>"
        "• <b>Y:</b> Compartment / Cabin class code (Economy).<br/>"
        "• <b>014C:</b> Assigned seat number (Row 14, Seat C).<br/>"
        "• <b>0001:</b> Passenger check-in sequence number.",
        styles['body']))

    story.append(Paragraph("5.3 Boarding Zones & Cancellation Policies", styles['h2']))
    story.append(Paragraph("• <b>Zone 1:</b> Priority Boarding add-on holders and front rows 1–5. Boarding commences at $T-45\text{m}$.", styles['bullet']))
    story.append(Paragraph("• <b>Zone 2:</b> Rows 6–17. <b>Zone 3:</b> Rows 18–30 (Aft cabin boarding).", styles['bullet']))
    story.append(Paragraph("• <b>Cancellation Freeze:</b> Once any passenger has checked in, cancellation is strictly blocked.", styles['bullet']))

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 9: SECTION 6 — REAL-TIME TELEMETRY & RFID BAGGAGE
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec6', page_dict))
    story.append(make_tag("SECTION 6 · EVENT SIMULATION & TELEMETRY", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("6. Real-Time Telemetry: Flight Status & RFID Baggage", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("6.1 Clock-Anchored Flight Status Engine", styles['h2']))
    story.append(Paragraph(
        "Because this prototype operates autonomously on client devices without external cloud feeds, `FlightStatusService` runs "
        "an internal clock-anchored timer that evaluates the current system clock against scheduled flight times to transition "
        "states: <i>Scheduled $\rightarrow$ Boarding $\rightarrow$ Departed $\rightarrow$ En Route $\rightarrow$ Landed</i>. "
        "Manual simulation triggers allow evaluators to inject gate changes (e.g. Gate 4 to Gate 19) and weather delays on demand, "
        "broadcasting notification events to `NotificationStore` which renders custom in-app push snackbars.",
        styles['body']))

    rfid_img_path = os.path.join(DIAGRAMS_DIR, "rfid_pipeline.png")
    if os.path.exists(rfid_img_path):
        story.append(Image(rfid_img_path, width=INNER_W, height=4.2*cm))
        story.append(Paragraph("Figure 6.1: 6-Stage RFID Baggage Handling System (BHS) Telemetry Pipeline.", styles['caption']))

    story.append(Paragraph("6.2 6-Stage RFID Baggage Telemetry Process (IATA Resolution 753)", styles['h2']))
    story.append(Paragraph(
        "IATA Resolution 753 mandates airlines track baggage at four mandatory custody transfer points. Our `BaggageService` models "
        "an enhanced 6-stage finite state machine tracking UHF RFID luggage tags (e.g. `6E-RFID-0011523`):<br/>"
        "1. <b>Checked In:</b> Bag tag scanned and registered at Terminal 1 check-in counter.<br/>"
        "2. <b>Security Screened:</b> Inline explosive detection system (EDS) X-Ray scan completed.<br/>"
        "3. <b>Loaded on Aircraft:</b> Scanned by ramp agents into aft cargo hold of Flight 6E 2175.<br/>"
        "4. <b>Unloaded at Destination:</b> Offloaded onto baggage tugs at Mumbai Terminal 2 ramp.<br/>"
        "5. <b>On Luggage Belt:</b> Scanned entering Arrival Carousel Belt 04.<br/>"
        "6. <b>Collected:</b> Exit gate verification scanner confirms passenger pickup.",
        styles['body']))

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 10: SECTION 7 — QUALITY ASSURANCE & TEST SUITE
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec7', page_dict))
    story.append(make_tag("SECTION 7 · VERIFICATION & QUALITY ASSURANCE", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("7. Quality Assurance, Test Suite & Boundary Verification", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("7.1 Automated Test Execution Summary", styles['h2']))
    story.append(Paragraph(
        "The codebase is rigorously verified via an automated test suite executed via `flutter test`. "
        "A total of **137 automated tests execute in 9.2 seconds with a 100% pass rate (0 failures, 0 regressions)**. "
        "Testing encompasses unit boundary tests, widget layout integrity tests, and full end-to-end user journeys.",
        styles['body']))

    test_img_path = os.path.join(DIAGRAMS_DIR, "test_suite.png")
    if os.path.exists(test_img_path):
        story.append(Image(test_img_path, width=INNER_W, height=4.5*cm))
        story.append(Paragraph("Figure 7.1: Automated Test Suite Distribution & Verification Summary.", styles['caption']))

    story.append(Paragraph("7.2 Boundary Value & Defect Regression Log", styles['h2']))
    
    test_log_data = [
        [Paragraph("Test Case Ref", styles['tbl_header']), Paragraph("Target Module / Function", styles['tbl_header']), Paragraph("Boundary Condition & Assertion", styles['tbl_header']), Paragraph("Verification", styles['tbl_header'])],
        [Paragraph("TC-YIELD-01", styles['tbl_cell_bold']), Paragraph("PricingEngine.multiplier", styles['tbl_cell']), Paragraph("Days = 30 -> 0.85x; Days = 29 -> 0.95x; Days = 15 -> 0.95x; Days = 14 -> 1.00x", styles['tbl_cell']), Paragraph("PASS", styles['tbl_cell_center'])],
        [Paragraph("TC-YIELD-02", styles['tbl_cell_bold']), Paragraph("PricingEngine.multiplier", styles['tbl_cell']), Paragraph("Days = 3 -> 1.15x; Days = 2 -> 1.30x; Days = 0 -> 1.30x; Negative days -> 1.30x", styles['tbl_cell']), Paragraph("PASS", styles['tbl_cell_center'])],
        [Paragraph("TC-GATE-01", styles['tbl_cell_bold']), Paragraph("CheckInRules.isWindowOpen", styles['tbl_cell']), Paragraph("Exactly 48h 00m -> TRUE (Open); 48h 01m -> FALSE (Closed)", styles['tbl_cell']), Paragraph("PASS", styles['tbl_cell_center'])],
        [Paragraph("TC-GATE-02", styles['tbl_cell_bold']), Paragraph("CheckInRules.isWindowOpen", styles['tbl_cell']), Paragraph("Exactly 60m 00s -> FALSE (Closed); 60m 01s -> TRUE (Open)", styles['tbl_cell']), Paragraph("PASS", styles['tbl_cell_center'])],
        [Paragraph("TC-REFUND-01", styles['tbl_cell_bold']), Paragraph("PricingEngine.refund", styles['tbl_cell']), Paragraph("Flex cancelled at T-2h 00m -> 100% full refund; at T-1h 59m -> ₹0 refund", styles['tbl_cell']), Paragraph("PASS", styles['tbl_cell_center'])],
        [Paragraph("TC-RESP-01", styles['tbl_cell_bold']), Paragraph("CabinMap Layout", styles['tbl_cell']), Paragraph("Viewport width 360px -> Seat dimensions compute to 32px; 0 overflow errors", styles['tbl_cell']), Paragraph("PASS", styles['tbl_cell_center'])],
    ]
    test_log_table = Table(test_log_data, colWidths=[2.2*cm, 4.0*cm, INNER_W - 7.6*cm, 1.4*cm],
                           style=TableStyle([
                               ('BACKGROUND', (0,0), (-1,0), NAVY),
                               ('BOX', (0,0), (-1,-1), 0.8, MID_GREY),
                               ('INNERGRID', (0,0), (-1,-1), 0.3, MID_GREY),
                               ('TOPPADDING', (0,0), (-1,-1), 3),
                               ('BOTTOMPADDING', (0,0), (-1,-1), 3),
                               ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, LIGHT_GREY]),
                           ]))
    story.append(test_log_table)

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 11: SECTION 8 — PRODUCTION GAP ANALYSIS & ROADMAP
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec8', page_dict))
    story.append(make_tag("SECTION 8 · PRODUCTION GAP ANALYSIS & ROADMAP", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("8. Production Gap Analysis & Enterprise Roadmap", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("8.1 Engineering Transition: Prototype vs Enterprise Airline System", styles['h2']))
    story.append(Paragraph(
        "A rigorous engineering evaluation acknowledges the boundary between a local client-side prototype and an enterprise airline production system. "
        "The following matrix outlines the strategic transition architecture to scale Case #115 for millions of daily active passengers:",
        styles['body']))

    prod_data = [
        [Paragraph("Subsystem Component", styles['tbl_header']), Paragraph("Current Case #115 Prototype", styles['tbl_header']), Paragraph("Enterprise Production Architecture", styles['tbl_header']), Paragraph("Implementation Protocol", styles['tbl_header'])],
        [Paragraph("Seat Inventory Locking", styles['tbl_cell_bold']), Paragraph("Client-side collision bitmask check", styles['tbl_cell']), Paragraph("Distributed Redis Lock with 10-minute TTL", styles['tbl_cell']), Paragraph("SET flight:seat:14C NX EX 600", styles['tbl_cell'])],
        [Paragraph("Push Telemetry", styles['tbl_cell_bold']), Paragraph("In-app SnackBar + device timer loop", styles['tbl_cell']), Paragraph("Firebase Cloud Messaging (FCM) + APNs", styles['tbl_cell']), Paragraph("Topic subscribe: /topics/flight_6E2175", styles['tbl_cell'])],
        [Paragraph("Payment Processing", styles['tbl_cell_bold']), Paragraph("Simulated checkout (no money moves)", styles['tbl_cell']), Paragraph("PCI-DSS Level 1 Tokenized Gateway (Stripe/Juspay)", styles['tbl_cell']), Paragraph("Client-side hosted tokenization sheet", styles['tbl_cell'])],
        [Paragraph("Local Persistence", styles['tbl_cell_bold']), Paragraph("shared_preferences (JSON String)", styles['tbl_cell']), Paragraph("Encrypted SQLite via Drift / Floor ORM", styles['tbl_cell']), Paragraph("SQLCipher with AES-256 database key", styles['tbl_cell'])],
        [Paragraph("Baggage Telemetry", styles['tbl_cell_bold']), Paragraph("Client-side finite state stepper", styles['tbl_cell']), Paragraph("Airport Baggage Handling System (BHS) MQTT feed", styles['tbl_cell']), Paragraph("IATA Resolution 753 event webhook", styles['tbl_cell'])],
        [Paragraph("Boarding Pass Storage", styles['tbl_cell_bold']), Paragraph("In-app dynamic QR widget", styles['tbl_cell']), Paragraph("Apple Wallet (PKPass) & Google Wallet API", styles['tbl_cell']), Paragraph("Cryptographically signed pass JSON", styles['tbl_cell'])],
    ]
    prod_table = Table(prod_data, colWidths=[3.2*cm, 4.2*cm, 5.0*cm, INNER_W - 12.4*cm],
                       style=TableStyle([
                           ('BACKGROUND', (0,0), (-1,0), NAVY),
                           ('BOX', (0,0), (-1,-1), 0.8, MID_GREY),
                           ('INNERGRID', (0,0), (-1,-1), 0.3, MID_GREY),
                           ('TOPPADDING', (0,0), (-1,-1), 3.5),
                           ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
                           ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, LIGHT_GREY]),
                       ]))
    story.append(prod_table)
    story.append(Spacer(1, 0.5*cm))

    story.append(make_callout("ENTERPRISE SCALABILITY STATEMENT",
        "By enforcing strict Separation of Concerns in Case #115, transitioning to production requires zero modifications "
        "to the UI screens or pure Dart pricing models. The only engineering effort is swapping the mock data layer "
        "for REST/GraphQL network repositories and configuring FCM push listeners.",
        border_color=NAVY))

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 12: SECTION 9 — GLOSSARY & VIVA DEFENSE CHEAT SHEET
    # ══════════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(PageTracker('sec9', page_dict))
    story.append(make_tag("SECTION 9 · TECHNICAL GLOSSARY & VIVA CHEAT SHEET", color=NAVY))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("9. Technical Glossary & Viva Defense Cheat Sheet", styles['h1']))
    story.append(HRFlowable(width="100%", thickness=1.0, color=NAVY, spaceAfter=8))

    story.append(Paragraph("9.1 Core Architectural Definitions (Examiner Q&A)", styles['h2']))
    story.append(Paragraph("• <b>Widget:</b> An immutable, declarative description of part of a user interface configuration. Everything visible or structural in Flutter is a widget.", styles['bullet']))
    story.append(Paragraph("• <b>Provider Pattern:</b> Scoped dependency injection and state management framework utilizing `ChangeNotifier` and `notifyListeners()` for reactive UI updates.", styles['bullet']))
    story.append(Paragraph("• <b>Sound Null Safety:</b> Static type guarantees ensuring variables cannot hold `null` unless explicitly flagged with `?`, preventing runtime null-pointer crashes.", styles['bullet']))
    story.append(Paragraph("• <b>Encapsulation:</b> Protecting internal booking state (`_draftBooking`) inside `BookingStore` so UI screens cannot manipulate prices directly.", styles['bullet']))
    story.append(Paragraph("• <b>Abstraction:</b> Exposing a simple 'Check In' button while encapsulating the complex IATA BCBP algorithmic string formatting under the hood.", styles['bullet']))
    story.append(Paragraph("• <b>IATA Resolution 792:</b> The international aviation barcode standard governing 2D boarding passes, encoding PNR, flight, Julian date, and seat.", styles['bullet']))

    story.append(Spacer(1, 0.4*cm))
    story.append(Paragraph("9.2 The Golden Metrics Cheat Sheet", styles['h2']))

    golden_data = [
        [Paragraph("Metric / Parameter", styles['tbl_header']), Paragraph("Exact Value", styles['tbl_header']), Paragraph("Engineering Significance", styles['tbl_header'])],
        [Paragraph("Automated Test Suite", styles['tbl_cell_bold']), Paragraph("137 / 137 (100% Pass)", styles['tbl_cell_center']), Paragraph("Zero regressions across unit, widget, and journey tests", styles['tbl_cell'])],
        [Paragraph("Dynamic Yield Multiplier", styles['tbl_cell_bold']), Paragraph("0.85x to 1.30x", styles['tbl_cell_center']), Paragraph("15% advance discount (≥30d) to 30% close-in surcharge (0–2d)", styles['tbl_cell'])],
        [Paragraph("Fare Families", styles['tbl_cell_bold']), Paragraph("Lite (+0), Classic (+800), Flex (+2200)", styles['tbl_cell_center']), Paragraph("Unbundled commercial tiers balancing baggage, meals, and flexibility", styles['tbl_cell'])],
        [Paragraph("Cabin Seat Geometry", styles['tbl_cell_bold']), Paragraph("30 Rows x 6 Seats = 180 Seats", styles['tbl_cell_center']), Paragraph("A320neo cabin: XL (₹799), Front (₹449), Std (₹299), Middle (₹199)", styles['tbl_cell'])],
        [Paragraph("Check-in Window Gate", styles['tbl_cell_bold']), Paragraph("48h to 60m before departure", styles['tbl_cell_center']), Paragraph("Strict temporal window preventing gate manifest desynchronization", styles['tbl_cell'])],
        [Paragraph("Boarding Time Offset", styles['tbl_cell_bold']), Paragraph("T - 45 minutes", styles['tbl_cell_center']), Paragraph("Boarding Zones: Zone 1 (Priority/Rows 1–5), Zone 2, Zone 3", styles['tbl_cell'])],
        [Paragraph("Worked Example Total", styles['tbl_cell_bold']), Paragraph("₹16,051 (DEL -> BOM, 2 pax)", styles['tbl_cell_center']), Paragraph("Base 9,500 + Family 1,600 + Seats 1,098 + Add-ons 2,398 + Taxes 1,455", styles['tbl_cell'])],
    ]
    golden_table = Table(golden_data, colWidths=[3.5*cm, 4.0*cm, INNER_W - 7.5*cm],
                         style=TableStyle([
                             ('BACKGROUND', (0,0), (-1,0), NAVY),
                             ('BOX', (0,0), (-1,-1), 0.8, MID_GREY),
                             ('INNERGRID', (0,0), (-1,-1), 0.3, MID_GREY),
                             ('TOPPADDING', (0,0), (-1,-1), 3),
                             ('BOTTOMPADDING', (0,0), (-1,-1), 3),
                             ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, LIGHT_GREY]),
                         ]))
    story.append(golden_table)

    return story

def generate():
    print("Pass 1: Computing page numbers for dynamic TOC...")
    dummy_doc = SimpleDocTemplate(
        OUTPUT, pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=MARGIN, bottomMargin=MARGIN
    )
    page_dict = {}
    dummy_story = build_pdf(page_dict)
    dummy_doc.build(dummy_story, canvasmaker=NumberedCanvas)
    
    print(f"Captured page registry: {page_dict}")
    print("Pass 2: Building final publication-grade PDF report...")
    doc = SimpleDocTemplate(
        OUTPUT, pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=MARGIN, bottomMargin=MARGIN
    )
    final_story = build_pdf(page_dict)
    doc.build(final_story, canvasmaker=NumberedCanvas)
    print(f"Report generated successfully: {OUTPUT}")

if __name__ == "__main__":
    generate()
