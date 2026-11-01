# BAGI Lottie handoff

## Character references

- `bagi_wave_reference.png`: current Bag2School mascot reference. Preserve the orange backpack silhouette, cream pocket, brown straps/handle, face, blush, and warm rounded 3D illustration style.
- `bagi_mood_reference_sheet.png`: pose and expression reference for idle, success, and gentle concern. Use it as visual guidance; redraw/rebuild the character as separate vector layers for animation rather than animating the flattened sheet.

## Requested motion

Create a seamless, light idle loop with small body breathing/bobbing, occasional blink, and a gentle hand wave. Keep the character centered, friendly, and readable at small UI sizes. Avoid fast movement, strong squash/stretch, camera movement, or large effects.

Suggested animation states:

1. `idle`: 3–4 second loop; subtle body bob (about 2–3% height), tiny backpack/strap settling, occasional natural blink.
2. `wave`: 2–2.5 second loop; raise the existing arm slightly and rotate the hand/forearm through a small arc for 2–3 waves, then return to idle pose. Keep the shoulder attached and avoid bending the backpack body.
3. `success`: 1–1.5 second gentle bounce with a warm smile and a few small sparkles; settle back into idle.
4. `concern`: calm sympathetic face with a very small head/body tilt; no dramatic sadness.
5. `talk` (optional): subtle mouth open/close while keeping the rest of the body nearly still.

## Layering requested from the animator

Separate the backpack body, front pocket, straps, handle, face panel, left/right eyes, brows, mouth, blush, left/right arms/hands, and feet. Keep the waving arm as its own pivoted layer. Build animation using vector shapes where possible so the Lottie remains crisp at different sizes.

## Delivery requested

- Lottie JSON (`.json`) with transparent background and no embedded scene background.
- Named animation segments or markers: `idle`, `wave`, `success`, `concern`, and optionally `talk`.
- A preview GIF/MP4 and the editable source project for future revisions.
- Verify that the loop is smooth and the character remains within the canvas bounds at 64 px, 128 px, and 256 px display sizes.
