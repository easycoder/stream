# Account

A service-log application for a one-person funeral live-streaming business,
built in [AllSpeak](https://allspeak.ai/). Replaces a long-running
spreadsheet with a browser-based GUI that records each booking and any
related expense, tallies running totals by month and grand-total, and
stores the data as monthly JSON files inside a UK financial-year folder
structure.

The repo doubles as a worked example of building a real-world AllSpeak app
with AI assistance — the `conversation-NN.md` files are the full transcripts
of the build, including detours, dead ends and refactors.

## Requirements

- [AllSpeak](https://allspeak.ai/) (Python runtime) installed and on PATH.
- A modern desktop browser.

## Running

From the project directory:

```
allspeak server.as -t account
```

`server.as` starts a local HTTP server (default port 8080) and opens the
default browser to `http://localhost:8080/account.html`. Closing the
terminal (Ctrl+C) closes the app.

To open the AllSpeak editor in a second tab alongside the app — useful
when working on the code:

```
allspeak server.as -t edit,account
```

A different port can be set as the last argument:

```
allspeak server.as -t account 9000
```

## First run — sample data

On a fresh clone there's no `data/` folder, so the app shows an empty-state
panel with a **Load sample data** button. Clicking it writes a small fixture
(`sample.json` — seven fictional bookings across April-June 2026) into
`data/2026-27/04.json`, `05.json` and `06.json`, then re-renders the table.

After that, use **Add booking** to enter your own data and the sample rows
serve as examples to delete or overwrite.

## Project layout

| File / folder        | Purpose                                                                |
| -------------------- | ---------------------------------------------------------------------- |
| `account.html`       | Minimal launcher — loads the AllSpeak runtime and bootstraps the app.  |
| `account-main.as`    | Main app script — rendering, table, modal, save/load logic.            |
| `account.json`       | Webson layout describing the page structure and styles.                |
| `sample.json`        | The fictional dataset offered by the **Load sample data** button.      |
| `server.as`          | Generic AllSpeak dev server — serves files, exposes `/list`/`/read`/`/write`. |
| `seed.as`            | Reference example of a CSV-to-JSON importer; adapt to your own spreadsheet. |
| `asedit.as`, `asedit.json`, `edit.html` | Browser-based AllSpeak code editor (developer convenience). |
| `asdoc-check.py`     | Tool that refreshes `@hash` lines in doc blocks after edits.           |
| `CLAUDE.md`          | Bootstrap instructions for AI-assisted development.                    |
| `.allspeak-init`     | Marks the project as initialised so the AI bootstrap skips the setup wizard. |
| `conversation-*.md`  | Build-log transcripts of the AI-assisted construction of this project. |
| `data/`              | Local data files — gitignored. Created on demand by the app.           |

## Data shape

Each monthly file (`data/<FY>/<MM>.json`) is an array of row objects.

Service row:

```json
{
    "kind": "service",
    "date": "2026-04-12",
    "name": "Margaret Holloway",
    "location": "Crematorium Chapel, Eastfield",
    "time": "11:30",
    "distance": "22",
    "contact": "Sarah Bell",
    "client": "Mason & Sons",
    "mileage": 220,
    "expense": 0,
    "paid": 0,
    "fees": 30000
}
```

Expense row:

```json
{
    "kind": "expense",
    "date": "2026-05-15",
    "description": "Camera tripod replacement",
    "expense": 8500,
    "paid": 8500,
    "fees": 0
}
```

Money values are integer pence (8500 = £85.00); `mileage` is integer
tenths-of-a-mile (220 = 22.0). Parsers and formatters convert at the
input/render boundaries.

## License

Apache 2.0 — see [LICENSE](LICENSE).
