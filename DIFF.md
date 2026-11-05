# What changed

Deploy (`./deploy.sh`) and reload the page — `admin-main.allspeak` only.

- On a phone in portrait the white panel now fills the screen and the list
  scrolls inside it. It used to stop at `100vh - 200px`, which on a tall phone
  left a band of empty background under the panel — most of the gap in your
  screenshot.
- The column header stays pinned while the list scrolls, and the last month is
  reachable without the page itself scrolling.
- Height comes from `100dvh`, so it follows the browser's toolbar as it slides
  away rather than leaving the list short by the toolbar's height.
- Desktop is untouched: same page margin, same fixed-height table, twelve
  columns.
- The page only takes the viewport's height when the mobile-portrait branch runs
  at startup, so rotating still needs a reload, as before.

To check: open the site on the phone in portrait — the panel should reach the
bottom of the screen and the list should scroll under the fixed header; open it
on the desktop — unchanged.
