!   stream-main.as

!! Public viewer for one stream. The URL is `/<slug>` (e.g. `/260529-Jane-Doe`), rewritten by .htaccess to land at `stream.html`; we read the path, look up the matching record on disk, and either embed the live Dacast iframe or — when a recording has been uploaded — replace the player with a link to it. There is no list view here: this script handles exactly one stream at a time, identified entirely by the slug in the URL.
!!
!! Bootstrap order matters. Render the Webson layout first so every DOM slot exists, attach handles for the ones we write into, scale the body text down on portrait-orientation mobile (otherwise the body-text crawl wraps to single-word lines), then fire `gosub CheckAuth` to opportunistically reveal the back-to-editor link for a logged-in admin. The auth check is non-blocking — every failure path leaves the link hidden, which is the safe default for a public page.
    script Stream

    div Body
    div VideoBox
    div ErrorBox
    div BodyTextDiv
    div TitleSlot
    div RecordingPanel
    div RecordingTitle
    div RecordingPara
    div RecordingLink
    variable Mobile
    variable Deceased
    variable RecordingUrl
    variable RecordingText
    variable LinkHtml
    variable Title
    variable AuthJson
    variable AuthInfo
    variable Authed
    variable Layout
    variable Path
    variable Slug
    variable FirstChar
    variable YYStr
    variable YearStr
    variable MonthStr
    variable DayStr
    variable TempStr
    variable JsonPath
    variable RecordJson
    variable StreamRecord
    variable DacastId
    variable LivePos
    variable AccountId
    variable ContentStart
    variable ContentId
    variable FrameUrl
    variable IframeHtml
    variable CacheBuster

    create Body
    rest get Layout from `stream.json`
    render Layout in Body

    attach VideoBox to `video-box`
    attach ErrorBox to `error-box`
    attach BodyTextDiv to `body-text`
    attach TitleSlot to `title-slot`
    attach RecordingPanel to `recording-panel`
    attach RecordingTitle to `recording-title`
    attach RecordingPara to `recording-para`
    attach RecordingLink to `recording-link`

!   ---- Mobile-portrait font tweak ----
    if mobile and portrait set Mobile
    else clear Mobile
    if Mobile
    begin
        set style `font-size` of BodyTextDiv to `0.65em`
        set style `font-size` of RecordingPanel to `0.65em`
    end

!!!

!! Turn the URL path into a data filename. The slug shape is fixed: `YYMMDD-<name-bits>` — six digits then a hyphen — and the digits double as the date that maps to the directory shard `data/YYYY/MM/DD/<slug>.json`. The .htaccess rewrite only routes digit-prefixed paths here, so the `FirstChar` range guard exists for direct hits on `stream.html` with a hand-typed bad query rather than for normal traffic; on a bare host with no slug we bail out with a "No stream specified." message.
!!
!! Fetching the JSON needs a cache-buster. Apache serves the file as a static asset and caches aggressively, so without the random query a viewer load immediately after an admin save would render the pre-edit record. The page-title section only overrides the layout's default title when the record carries a non-empty one, which keeps legacy records (saved before `title` existed) from blanking out the slot.

!   ---- Resolve slug from path ----
    put the path into Path
    !   Strip the leading `/`. Path is "/<slug>" (or "/" on the bare host).
    put from 1 of Path into Slug
    if Slug is empty begin
        gosub ShowError
        set the content of ErrorBox to `No stream specified.`
        stop
    end
    !   Defensive: viewer URLs always start with a digit. Anything else
    !   shouldn't reach this script (the .htaccess rewrite filters), but
    !   guard against direct hits on stream.html with a bad query.
    put left 1 of Slug into FirstChar
    if FirstChar is less than `0` or FirstChar is greater than `9` begin
        gosub ShowError
        set the content of ErrorBox to `Sorry, this stream is not available.`
        stop
    end

!   ---- Derive data path: data/YYYY/MM/DD/<slug>.json ----
!   Slug shape is YYMMDD-<name-bits>, fixed 6-digit prefix.
    put left 2 of Slug into YYStr
    put `20` cat YYStr into YearStr
    put from 2 of Slug into TempStr
    put left 2 of TempStr into MonthStr
    put from 4 of Slug into TempStr
    put left 2 of TempStr into DayStr
    put `data/` cat YearStr into JsonPath
    put JsonPath cat `/` cat MonthStr into JsonPath
    put JsonPath cat `/` cat DayStr into JsonPath
    put JsonPath cat `/` cat Slug into JsonPath
    put JsonPath cat `.json` into JsonPath

!   ---- Fetch the record ----
!   Cache-buster: Apache caches static .json files, so a viewer load
!   right after an edit would otherwise show the pre-edit record.
    put random 999999999 into CacheBuster
    rest get RecordJson from `/` cat JsonPath cat `?` cat CacheBuster or begin
        gosub ShowError
        set the content of ErrorBox to `Sorry, this stream is not available.`
        stop
    end
    put json RecordJson into StreamRecord

!   ---- Page title (shown in both player and recording modes) ----
    put property `title` of StreamRecord into Title
    if Title is not empty
    begin
        set the content of TitleSlot to Title
    end
!!!

!! Two display modes share the same record. When `recording_url` is set — the live event is over and an edited or unedited recording has been uploaded (typically to Google Drive) — we hide the player and the body-text crawl and reveal a recording panel with the deceased's name, an explanatory paragraph, and a styled link. Recording mode always wins over live mode whenever the field is non-empty, so the page transitions from "watch live" to "watch the recording" the moment the admin saves the URL.
!!
!! Otherwise we play live. The stored `dacast_id` has the form `<account>-live-<content>` (the literal separator `-live-` is six characters), and Dacast's iframe URL needs the two halves as separate path segments — so we locate `-live-` via `the position of`, treating a negative result as "not in this string" and therefore a malformed record, and split around it. The injected iframe styles deliberately keep the player full-bleed inside its box.

!   ---- Recording mode ----
    put property `recording_url` of StreamRecord into RecordingUrl
    if RecordingUrl is not empty
    begin
        put property `deceased` of StreamRecord into Deceased
        put property `recording_text` of StreamRecord into RecordingText
        set style `display` of VideoBox to `none`
        set style `display` of BodyTextDiv to `none`
        set the content of RecordingTitle to Deceased
        if RecordingText is not empty
        begin
            set the content of RecordingPara to RecordingText
        end
        put `<a href="` cat RecordingUrl into LinkHtml
        put LinkHtml cat `" target="_blank" style="display:inline-block;padding:1em 1.5em;background:rgba(255,255,255,0.85);border:1px solid #aaa;border-radius:6px;color:#06c;text-decoration:none;font-weight:500">Click here to view the unedited recording of the stream</a>` into LinkHtml
        set the content of RecordingLink to LinkHtml
        set style `display` of RecordingPanel to `block`
        stop
    end

    put property `dacast_id` of StreamRecord into DacastId

!   ---- Split dacast_id at "-live-" into account / content halves ----
!   Stored form: <account>-live-<content>
!   Iframe form: https://iframe.dacast.com/live/<account>/<content>
    put the position of `-live-` in DacastId into LivePos
    if LivePos is less than 0 begin
        gosub ShowError
        set the content of ErrorBox to `Stream record is malformed (Dacast ID).`
        stop
    end
    put left LivePos of DacastId into AccountId
    put LivePos into ContentStart
    add 6 to ContentStart
    put from ContentStart of DacastId into ContentId

!   ---- Build and inject the iframe ----
    put `https://iframe.dacast.com/live/` cat AccountId into FrameUrl
    put FrameUrl cat `/` cat ContentId into FrameUrl
    put `<iframe src="` cat FrameUrl into IframeHtml
    put IframeHtml cat `" frameborder="0" scrolling="no" allow="autoplay;encrypted-media" allowfullscreen style="width:100%;height:100%;border:0;display:block"></iframe>` into IframeHtml
    set the content of VideoBox to IframeHtml

    stop
!!!

!! Switch the page into error mode by hiding the video frame and revealing the (initially empty) error box. Each caller writes its own specific message into `ErrorBox` immediately after returning, so this routine intentionally doesn't set the text — the split lets every error site reuse the display toggle without coupling to a single fixed message. Callers always pair this with `stop`, which is why the empty-box moment is never visible to the user.
ShowError:
    set style `display` of VideoBox to `none`
    set style `display` of ErrorBox to `block`
    return
!!!
