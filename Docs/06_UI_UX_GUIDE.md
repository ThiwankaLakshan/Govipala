# UI/UX Guide
## Govipala (v1.4)

**Goal:** a clean, friendly, good-looking app that anyone in Padaviya can use on an old, low-memory Android phone without lag.

Simple and attractive come from good colour, spacing, big icons, and clear layout. They do not come from heavy effects. Every rule below follows from that.

---

## 1. Design principles
1. **Few things per screen.** One main action per screen, shown as a big button.
2. **Icon + Sinhala label, always.** Never icon-only, never text-only walls.
3. **Big and thumb-friendly.** Main buttons sit at the bottom of the screen where a thumb reaches.
4. **Colour with meaning.** Green = good/confirmed, amber = waiting, red = problem. Never rely on colour alone (add an icon and a word).
5. **Light by design.** No blur, heavy shadows, big animations, or video. If an effect costs performance on a 2GB phone, drop it.
6. **Friendly, not boring.** Warm colours, rounded cards, large machine icons, small friendly empty-state illustrations. Not a default grey template.

---

## 2. Visual identity

### 2.1 Colour tokens (define once in code, never hard-code hex values in screens)
| Token | Hex | Use |
|---|---|---|
| `primary` | `#2E7D32` | Main buttons, selected tab, headers ("paddy green") |
| `primaryDark` | `#1B5E20` | Pressed state, app bar text on light |
| `primarySoft` | `#E8F5E9` | Tinted backgrounds, selected chips |
| `accent` | `#F2A900` | Highlights, "waiting" status, rating stars ("harvest gold"). Use dark text on top of it |
| `background` | `#FAF8F3` | Screen background (warm off-white, easier on the eyes than pure white) |
| `surface` | `#FFFFFF` | Cards |
| `border` | `#E3E8E0` | Card outlines (used instead of shadows) |
| `textPrimary` | `#1F2A1F` | Main text |
| `textSecondary` | `#5B665B` | Hints, captions |
| `info` | `#1565C0` | "In progress" status |
| `danger` | `#C62828` | Errors, cancel, reject |

These are starting choices. The agent must check contrast of every text/background pair (aim for WCAG AA, 4.5:1 for body text) and adjust a shade if one fails.

### 2.2 Status chips (colour + icon + word)
| Status | Colour | Icon |
|---|---|---|
| Requested | accent | hourglass |
| Confirmed | primary | check |
| In progress | info | tractor/play |
| Completed | textSecondary | double-check |
| Rejected / Cancelled | danger | close |

### 2.3 Typography
- **Sinhala:** Noto Sans Sinhala, **bundled inside the app** (Regular + Bold only). Do not download fonts at runtime: it fails offline, and some old phones render Sinhala badly without a bundled font.
- **English / numbers:** system default (Roboto). Do not bundle a second font.
- Sizes: body 16sp, section titles 20sp, screen titles 24sp, nothing below 14sp.
- Line height about 1.4–1.5 for Sinhala so marks above and below letters are not clipped.
- Layouts must not break when the user raises the system font size (test at 1.3×).

### 2.4 Shape and spacing
- Spacing scale: 4 / 8 / 12 / 16 / 24 dp. Screen side padding 16 dp.
- Cards: radius 16, 1 px `border`, **no shadow** (elevation 0). Buttons: radius 12, height 52 dp.
- Minimum tap target 48 × 48 dp.

### 2.5 Icons and imagery
- Machine type icons: one simple, consistent set of 4 (four-wheel tractor, two-wheel tractor, combine harvester, water pump). Use vector icons or an icon font, not photos or PNGs. Flutter's built-in agriculture icon can cover the tractor; draw or source simple matching icons for the rest.
- Machine photos come from owners. Compress them (see section 6) and show a coloured placeholder with the type icon while loading or when there is no photo.
- Empty states (no bookings, no machines): one small vector illustration + one friendly sentence + one button.

---

## 3. Navigation
- **Bottom navigation, max 4 tabs.**
  - Farmer: Home, My Bookings, Profile.
  - Owner: Home, Requests (with a number badge), My Machines, Profile.
  - Users with role "both" get a role switch on the Home screen header.
- No hamburger menus, no nested drawers. Back button always works as expected.

---

## 4. Key screens

### Farmer
1. **Home:** short greeting, a 2×2 grid of big machine-type tiles (icon + Sinhala name), a quick filter row (GN division, date) below, and "Upcoming booking" card if one exists.
2. **Machine list:** simple cards. Each card: small photo, **brand + machine type** as the title, drive type chip (4-wheel tractors only: 2WD/4WD), rate, star rating, and a green "Available [date]" chip. Load 15 at a time.
3. **Machine detail:** photo, details, owner name and rating, then the slot picker.
4. **Slot picker:** a horizontal strip of the next 14 days (a dot under days that have open slots), then large time-block chips for the chosen day. Selected chip turns `primary`.
5. **Booking confirm:** land location field, summary card, one big "Request booking" button. A clear success screen after sending.
6. **My Bookings:** list with status chips; tap for detail and review.

### Owner
1. **Home:** two summary cards ("Requests waiting (n)", "Today's jobs"), a big "Add availability" button, and the list of their machines.
2. **Add machine:** one scrolling form, in this order: machine type (4 big tiles) → brand (text field) → **drive type dropdown (2WD / 4WD), shown only for four-wheel tractors** → model → rate + unit (segmented control: hour / day / acre) → photo → GN divisions served (multi-select chips) → Save.
3. **Add availability:** pick the machine, tap dates on a month grid, choose time blocks, Save. Allow "repeat for these days" so owners don't enter every day by hand.
4. **Requests:** cards with farmer name, GN division, date/time, land location; two big buttons, "Accept" (green) and "Decline" (outlined).

### Shared
- **Offline banner:** a thin bar at the top, "No connection: showing saved data", plus a "Syncing…" state when it reconnects.
- **Language switch** on Profile (Sinhala default, English).
- Confirmation dialog before any destructive action (cancel booking, delete slot).

---

## 5. Motion
- Allowed: simple fade/slide page transitions (150–250 ms), button press feedback, a small success tick.
- Not allowed: parallax, blur, Lottie/Rive/video, long or looping animations, animated backgrounds.
- Loading: use static grey placeholder blocks (or a very light fade). No full-screen blocking spinners except during login.

---

## 6. Performance rules (the app must stay light)

### 6.1 Targets (acceptance goals, to be checked on a real low-end phone)
| Item | Target |
|---|---|
| Cold start to first usable screen | about 3 seconds or less on a 2GB RAM phone |
| Scrolling lists | no visible stutter |
| APK size | 25 MB or less per device architecture (build with `--split-per-abi`) |
| Machine photo upload | compressed to about 200 KB or less (longest side 1024 px) |
| List thumbnails | about 40 KB or less each (about 400 px wide) |
| Lowest Android version | set `minSdkVersion` to the lowest value the chosen Flutter and Firebase versions allow, so old phones can install it |

### 6.2 Do
- Use `const` widgets wherever possible and `ListView.builder` for every list; paginate lists (15 items).
- Compress and resize photos **on the phone before upload**, and upload two sizes (full + thumbnail). Lists show only the thumbnail.
- Use cached network images with a decode size limit (for example `memCacheWidth`) so big images are not decoded at full size.
- Keep state management simple and consistent (one approach across the app).
- Cache the last list and calendar locally for offline use (see Architecture).
- Profile with `flutter run --profile` on the real low-end phone, not only an emulator.

### 6.3 Don't
- No `BackdropFilter`/blur, no `ShaderMask`, no large `Opacity` layers, no stacked box shadows, and no large clipped (`ClipRRect`) images. Use a decorated container with rounded corners instead.
- No video, Lottie, Rive, or big animated GIFs.
- No heavy packages for small features. Before adding any package, check what it costs in APK size and startup.
- No nested scroll views, and no building long lists inside a `Column`.
- No dark mode in v1.0 (less to build, test, and carry).

---

## 7. Accessibility and low-literacy support
- Every action has an icon and a short Sinhala label.
- Status is never colour-only.
- Use short, plain Sinhala sentences. Avoid technical words.
- Numbers and dates in a consistent, local-friendly format. Show the day name together with the date.
- Errors say what to do next ("Check your connection and try again"), not error codes.
- Voice-over/audio help is a possible later phase, not in v1.0.

---

## 8. Admin web panel
- Uses the same colour and type tokens so it feels like the same product.
- Laptop/tablet layout: left menu, search bar, filter chips, simple tables with server-side pagination (25 rows).
- Keep it light too: no heavy charts. Dashboard is a handful of count cards.
- Destructive admin actions (suspend, delete, override a booking) always ask for a reason in a dialog.

---

## 9. Acceptance checklist (test on a real 2GB RAM Android phone)
- [ ] App installs and opens in about 3 seconds or less
- [ ] All lists scroll smoothly with 50+ items
- [ ] Sinhala text renders correctly, with no clipped marks, at normal and 1.3× font size
- [ ] Booking flow (search → slot → request) is completable by a first-time user with no help
- [ ] Add machine form shows the drive type dropdown only for four-wheel tractors
- [ ] Works with mobile data off: shows saved data and the offline banner
- [ ] All text/background pairs pass the contrast check
- [ ] APK per architecture is within the size target

---

## 10. Notes for Antigravity agents
- Create the theme first: `/lib/theme` with `colors.dart`, `text_styles.dart`, `spacing.dart`, and `app_theme.dart`. No hard-coded colours, sizes, or fonts inside screens.
- Build the reusable widgets next (primary button, machine card, status chip, slot chip, empty state), then build screens from them.
- Follow section 6 as hard rules. If a design idea conflicts with performance, choose performance.
- Show the agent's screenshots/recordings of the owner and farmer home screens for review before building the remaining screens.
