---
name: Viltrum demo and full-stack template
description: A request's trip through Viltrum, signed like a transit line, in the logo's black and white.
colors:
  signage-black: "#000000"
  field-white: "#ffffff"
  platform-gray: "#555555"
  night-gray: "#a3a3a3"
  hairline: "#d6d6d6"
  wash: "#f2f2f2"
typography:
  display:
    fontFamily: "Helvetica Neue, Helvetica, Nimbus Sans, Arial, sans-serif"
    fontSize: "clamp(2.75rem, 7vw, 5.25rem)"
    fontWeight: 800
    lineHeight: 0.95
    letterSpacing: "-0.04em"
  headline:
    fontFamily: "Helvetica Neue, Helvetica, Nimbus Sans, Arial, sans-serif"
    fontSize: "clamp(1.875rem, 3.4vw, 3rem)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.035em"
  title:
    fontFamily: "Helvetica Neue, Helvetica, Nimbus Sans, Arial, sans-serif"
    fontSize: "2.25rem"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.03em"
  station:
    fontFamily: "Helvetica Neue, Helvetica, Nimbus Sans, Arial, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  lede:
    fontFamily: "Helvetica Neue, Helvetica, Nimbus Sans, Arial, sans-serif"
    fontSize: "clamp(1.125rem, 1.6vw, 1.375rem)"
    fontWeight: 400
    lineHeight: 1.45
  body:
    fontFamily: "Helvetica Neue, Helvetica, Nimbus Sans, Arial, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Helvetica Neue, Helvetica, Nimbus Sans, Arial, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 700
    lineHeight: 1.5
  column-head:
    fontFamily: "Helvetica Neue, Helvetica, Nimbus Sans, Arial, sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 700
    letterSpacing: "0.02em"
  mono:
    fontFamily: "ui-monospace, SF Mono, Cascadia Mono, Menlo, Consolas, monospace"
    fontSize: "0.9375rem"
    fontWeight: 400
    lineHeight: 1.6
    fontFeature: "tnum"
rounded:
  none: "0"
  disc: "50%"
spacing:
  xxs: "0.25rem"
  xs: "0.5rem"
  sm: "0.75rem"
  md: "1rem"
  lg: "1.25rem"
  xl: "1.75rem"
  xxl: "2rem"
  gutter: "clamp(1rem, 4vw, 4rem)"
  rail: "15rem"
components:
  plate:
    backgroundColor: "{colors.signage-black}"
    textColor: "{colors.field-white}"
    rounded: "{rounded.none}"
    padding: "0 1.25rem"
    height: "3rem"
  plate-hover:
    backgroundColor: "{colors.field-white}"
    textColor: "{colors.signage-black}"
  plate-quiet:
    backgroundColor: "{colors.field-white}"
    textColor: "{colors.signage-black}"
    rounded: "{rounded.none}"
    padding: "0 1.25rem"
    height: "3rem"
  plate-quiet-hover:
    backgroundColor: "{colors.signage-black}"
    textColor: "{colors.field-white}"
  plate-on-black:
    backgroundColor: "{colors.field-white}"
    textColor: "{colors.signage-black}"
    rounded: "{rounded.none}"
    padding: "0 1.25rem"
    height: "3rem"
  plate-disabled:
    backgroundColor: "{colors.wash}"
    textColor: "{colors.platform-gray}"
  row-button:
    backgroundColor: "{colors.field-white}"
    textColor: "{colors.signage-black}"
    rounded: "{rounded.none}"
    padding: "0 0.875rem"
    height: "2.25rem"
  row-button-hover:
    backgroundColor: "{colors.signage-black}"
    textColor: "{colors.field-white}"
  input:
    backgroundColor: "{colors.field-white}"
    textColor: "{colors.signage-black}"
    rounded: "{rounded.none}"
    padding: "0 0.75rem"
    height: "3rem"
  field-label:
    typography: "{typography.label}"
  tag:
    backgroundColor: "{colors.field-white}"
    textColor: "{colors.signage-black}"
    rounded: "{rounded.none}"
    padding: "0 0.5rem"
  tag-solid:
    backgroundColor: "{colors.signage-black}"
    textColor: "{colors.field-white}"
    rounded: "{rounded.none}"
    padding: "0 0.5rem"
  rail-link:
    textColor: "{colors.night-gray}"
    padding: "0 0.5rem"
    height: "2.75rem"
  rail-link-current:
    textColor: "{colors.field-white}"
  flash:
    backgroundColor: "{colors.signage-black}"
    textColor: "{colors.field-white}"
    padding: "0.5rem 1rem"
    height: "2.75rem"
  departure-strip:
    backgroundColor: "{colors.signage-black}"
    textColor: "{colors.night-gray}"
    padding: "1rem clamp(1rem, 4vw, 4rem)"
  stop:
    backgroundColor: "{colors.field-white}"
    rounded: "{rounded.disc}"
    size: "2.25rem"
---

# Design System: Viltrum demo and full-stack template

## Overview

**Creative North Star: "The Transit Line"**

Every surface is signage for a request's trip through Viltrum. Black bands and a black rail carry the identity the way a station sign does; the white field below is where the reading happens. The logo's disc-and-V is the system's bullet: a filled white disc means "here", an outlined disc means "elsewhere", a barred disc means "closed". A single 6px black rule is the line itself; it runs across the landing's first viewport, then turns and runs down the left edge past every section, which are its stops.

The palette is the logo's, nothing more: pure black, pure white, and grays that only exist to rule lines and step text down. Type is a system grotesk set heavy and tight at sign scale, with monospace reserved for code and measured values. Density is calm: one focal move per view, generous white field, and every number on the page is a live reading from the process serving it. There are no shadows, gradients, hosted fonts, images other than the logo, or color of any kind. The black and white palette, the system font stack, and the zero hosted-asset rule are user-pinned decisions, not defaults.

**Key Characteristics:**
- Monochrome: black #000 and white #fff, grays for rules and secondary text only.
- Square corners everywhere; the only round shapes are discs (stops, bullets, the logo).
- 2px black rules for structure, 1px hairlines for rows, 6px black for the line.
- Interaction is inversion: black becomes white and white becomes black.
- System grotesk at weight 700 to 800 with negative tracking for headings; mono for code and live values.

## Colors

Two signage values and a short gray ladder; color is never used.

### Primary
- **Signage Black** (`signage-black`): bands, the dashboard rail, plates, the departure strip, code blocks, the line, all 2px structural rules, body text, and the focus outline on white.

### Neutral
- **Field White** (`field-white`): the page field, inverted plates on black, text on black, the focus outline on black, the filled "you are here" disc.
- **Platform Gray** (`platform-gray`): secondary text on white (notes, section prose, descriptions, counts, placeholders, empty states). 7.4:1 on white.
- **Night Gray** (`night-gray`): secondary text on black (inactive rail links, strip labels, footer text). 8.6:1 on black.
- **Hairline** (`hairline`): 1px row dividers in tables and definition lists; the border of a disabled plate. Never text.
- **Wash** (`wash`): the fill of a disabled (in-progress) plate. Nothing else.

### Named Rules
**The Logo Palette Rule.** Black and white are the identity; grays only rule lines or step text down. No hue, no gradient, no tint enters the system.

**The Inversion Rule.** A state change swaps black and white (hover, current, selected, solid tag). There is no third "accent" state color.

## Typography

**Display Font:** Helvetica Neue (with Helvetica, Nimbus Sans, Arial, sans-serif)
**Body Font:** the same grotesk stack
**Label/Mono Font:** ui-monospace (with SF Mono, Cascadia Mono, Menlo, Consolas, monospace)

**Character:** One sign-shop grotesk carries everything, heavy and tight at sign scale, plain at reading size. Mono marks what the machine says: code, commands, ids, and measured values, always with tabular figures.

### Hierarchy
- **Display** (800, clamp 2.75rem to 5.25rem, line-height 0.95, -0.04em): the landing headline only; one per page.
- **Headline** (700, clamp 1.875rem to 3rem, 1.1, -0.035em): landing section titles, one shouting phrase per section.
- **Title** (700, 2.25rem, 1.1, -0.03em): the dashboard page title in the top bar.
- **Station** (700, 1.5rem, 1.1, -0.02em): station names on the line.
- **Brand** (700, 1.375rem; 2rem in the landing band; -0.02em): the wordmark beside the logo.
- **Lede** (400, clamp 1.125rem to 1.375rem, 1.45): one sentence under the display line, max 44rem.
- **Body** (400, 1rem, 1.5): prose, max about 34rem to 40rem per column.
- **Label** (700, 0.875rem): field labels above inputs.
- **Column head** (700, 0.8125rem, 0.02em, uppercase): table header cells only.
- **Mono** (400, 0.9em inline, 0.9375rem in blocks, 1.6 in code blocks, tabular figures): code, commands, ids, live readings (bold 700 in the strip and the round-trip result).

### Named Rules
**The Machine Voice Rule.** Mono appears only where the text is code or a measured value. Prose, labels, and headings are always the grotesk.

**The Bundled Type Rule.** Fonts come from the operating system. The binary serves no font files and the page loads none from anywhere else.

## Layout

The landing's first viewport is a fixed sequence filling `100svh` below the band: the hero (headline, lede, the action pair, a note), the route (title row with the "Send a request" plate, then the line of five stations in a five-column grid), and the departure strip pinned to the bottom edge. Below the fold the line becomes a 6px left border, inset by the gutter; each section sits on it with a stop disc on the rule, a two-column grid (text up to 22rem, then code or a spec list), and a 2px black rule between sections.

The dashboard is a two-column grid: a 15rem sticky black rail and the work column (top bar with a 2px bottom rule, then the pane). Content in the pane stacks with a 1.75rem gap.

Horizontal padding is always the gutter, `clamp(1rem, 4vw, 4rem)`. The rhythm steps through 0.25, 0.5, 0.75, 1, 1.25, 1.75, and 2rem; section padding scales with viewport height (`clamp(3rem, 8vh, 5.5rem)` top).

Responsive: at 900px two-column sections, the sign-in form, and the item composer collapse to one column, and the locked table preview is hidden. At 760px the band shrinks to 4.5rem and drops its nav, the line turns vertical (rule on the left, stops in a 2.25rem column, no rider), the rail becomes a top bar with its links in a scrolling row, and columns marked optional drop out of tables.

## Elevation & Depth

Flat. There are no drop shadows and no tonal layering; depth is figure and ground, black on white or white on black. The only `box-shadow` in the system is a structural signage stripe, not elevation: bands and the rail carry a 6px black top border with a 2px white inset line under it, the double rule of a station sign.

### Named Rules
**The Flat Sign Rule.** Nothing lifts, glows, or casts. Hierarchy comes from inversion, weight, and rules.

## Shapes

Square corners on every rectangle: plates, inputs, tags, code blocks, the clone box, the flash, tables. The disc is the only curve, and it is the logo's: stop discs on the line and section rules (2.25rem with a 6px black border), rail bullets (1rem with a 3px border), and the rider (a black disc with a white core). A disc with a diagonal 3px bar through it means a closed or locked destination.

Borders come in three weights: 1px hairline for rows, 2px black for every control edge and structural rule, 6px black for the line.

### Named Rules
**The Only Curve Rule.** If it is round, it is a disc from the logo's vocabulary. Every other corner is square.

## Components

### Buttons (plates)
A plate is a sign: square, solid, one action.
- **Shape:** square corners, 2px black border, minimum height 3rem, padding 0 1.25rem, weight 700 at 1.0625rem.
- **Primary:** black plate with white text. A trailing inline SVG arrow (20px viewBox, 2.5 stroke) marks plates that go somewhere.
- **Hover / Focus:** inverts to white with black text over 120ms ease-out; the arrow slides 3px right. Focus is a 3px solid outline, offset 2px, black on white and white on black.
- **Quiet:** white plate with black border for a secondary action on white ("Send a request"); inverts to black on hover.
- **On black:** inside a band or the rail, the plate is white and inverts to black on hover.
- **Disabled:** wash fill, platform-gray text, hairline border, progress cursor; used while a request is in flight.
- **Row button:** the compact plate for table rows (2.25rem tall, 0.875rem text, white with black border, inverts on hover).

### Chips (tags)
- **Style:** inline, square, 2px black border, 0.8125rem weight 700, padding 0 0.5rem.
- **State:** outlined for the ordinary value ("user"), solid black with white text for the elevated one ("superuser").

### Inputs / Fields
- **Style:** white field, 2px black border, square, minimum height 3rem, padding 0 0.75rem, inherited type; placeholder in platform gray. A field is a label (0.875rem, 700) stacked 0.375rem above its input.
- **Focus:** the global 3px black outline with zero offset, so it thickens the border.

### Navigation
- **Band (landing):** a 6.5rem black band with the signage stripe, brand at 2rem with a 3.5rem logo, text links in weight 700 underlined only on hover, and a white plate at the end.
- **Rail (dashboard):** a sticky 15rem black column. Each link is a 1rem outlined disc and a 1.0625rem bold label in night gray; the current page has a filled white disc and white text; a locked page shows a barred disc and a not-allowed cursor. The foot holds the signed-in email and a full-width white plate. Under 760px it becomes a wrapping top bar.

### The Line (signature)
Five stations on a 6px black rule, each an outlined stop disc, a station name, and a one-line platform-gray description. "Send a request" fetches the health endpoint; a black rider disc with a white core travels the rule in 900ms linear while each stop fills black as the rider reaches it, then the measured round trip prints in bold mono at the terminus. With reduced motion there is no ride and the stops fill at once.

### Departure Strip
A black band across the bottom of the first viewport: night-gray labels with white bold mono values, all read from the running process. Values are live or absent, never sample data.

### Tables and spec lists
Header row in column-head type between two 2px black rules; body rows divided by 1px hairlines; ids in mono; titles in bold; descriptions in platform gray. Definition lists (the landing spec, account details) use the same rules: a 2px black top rule, hairline rows, bold terms.

### Code blocks and the clone box
Code blocks are black panels with white mono at 0.9375rem, padding 1.5rem, and inverted selection. The clone box is a 2px black outline holding the command in mono and a joined "Copy" button separated by a 2px black rule; the button inverts on hover.

### Flash
A black bar of bold white text, minimum height 2.75rem, shown only when there is a message.

## Do's and Don'ts

### Do:
- **Do** invert black and white for every state change; hover, current, and selected share one move.
- **Do** use 2px black borders for controls and structure, 1px hairline only between rows, and 6px only for the line.
- **Do** keep every corner square; use the disc only for stops, bullets, and the logo.
- **Do** set mono only for code, commands, ids, and measured values, with tabular figures.
- **Do** show the 3px focus outline in the opposite color of its ground.
- **Do** mark destinations with the logo's disc grammar: filled is here, outlined is elsewhere, barred is closed.
- **Do** show only live readings from the process in strips and counters.

### Don't:
- **Don't** introduce any hue, tint, or gradient; the palette is the logo's black and white.
- **Don't** add drop shadows or lifted surfaces; the only box-shadow is the band's inset signage stripe.
- **Don't** load fonts, images, icon sets, or scripts from anywhere but the binary; type comes from the system stack and icons are inline SVG.
- **Don't** round rectangles; no border-radius except the 50% disc.
- **Don't** use hairline gray for text, or platform gray on black (use night gray there).
