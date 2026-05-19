!   build.as
!   Build the static read-only deploy bundle into ./deploy.
!
!   Usage:  allspeak build.as
!
!   Produces a self-contained folder suitable for hosting on Cloudflare Pages,
!   Netlify, or any static host: the app files, a snapshot of `data/`, the
!   `docs/` folder if present, a `data/index.json` manifest replacing the
!   server's /list endpoints, and a `config.json` that flips the app into
!   readonly / manifest mode.
!
!   Re-run after data changes; commit the deploy folder (or a separate repo)
!   to publish.

    script Build

    variable BaseDir
    variable DeployDir
    variable FyEntriesStr
    variable MmEntriesStr
    list FyEntries
    list MmEntries
    dictionary FyEntry
    dictionary MmEntry
    variable FyIdx
    variable FyName
    variable FyType
    variable MmIdx
    variable MmName
    variable MmType
    variable ManifestStr

    put cwd into BaseDir
    put BaseDir cat `/deploy` into DeployDir

!! Wipe and recreate the deploy folder, then copy the app, data, and any
!! linked docs.
!!
!! `cp -r data` copies every monthly JSON wholesale — small and quick for
!! this project's scale. The optional `docs/` folder holds any local files
!! that rows link to (invoices, cheques); only copied if you've got one.

    system `mkdir -p ` cat DeployDir
    system `find ` cat DeployDir cat ` -mindepth 1 -not -path '` cat DeployDir cat `/.git*' -delete`
    system `cp ` cat BaseDir cat `/account.html ` cat DeployDir cat `/`
    system `cp ` cat BaseDir cat `/account.html ` cat DeployDir cat `/index.html`
    system `cp ` cat BaseDir cat `/account.json ` cat DeployDir cat `/`
    system `cp ` cat BaseDir cat `/account-main.as ` cat DeployDir cat `/`
    system `cp -r ` cat BaseDir cat `/data ` cat DeployDir cat `/`
    if file BaseDir cat `/docs` exists
        system `cp -r ` cat BaseDir cat `/docs ` cat DeployDir cat `/`
!! @hash 39fc7149
!!!

!! Walk data/ and build a manifest that replaces the server's /list endpoints
!! in static mode.
!!
!! `entries in <path>` returns JSON text (a string), not a live collection,
!! so we parse it with `json of` into a typed `list` before iterating, and
!! copy each element into a typed `dictionary` so its `name` / `type` fields
!! can be read with `entry`. The manifest mirrors what /list/data plus
!! /list/data/<FY> would produce combined: a top-level `fys` array of
!! `{name, type}` objects, each FY enriched with an inner `months` array of
!! the same shape. Built as a JSON text string so the whole thing saves with
!! one call. Folder and file names in this project never contain quotes or
!! backslashes, so no JSON escaping is needed.

    put `{"fys":[` into ManifestStr

    set FyEntriesStr to entries in BaseDir cat `/data` type `json`
    put json of FyEntriesStr into FyEntries
    put 0 into FyIdx
    while FyIdx is less than the count of FyEntries
    begin
        put item FyIdx of FyEntries into FyEntry
        put entry `name` of FyEntry into FyName
        put entry `type` of FyEntry into FyType
        if FyIdx is greater than 0
            put ManifestStr cat `,` into ManifestStr
        put ManifestStr cat `{"name":"` cat FyName cat `","type":"` cat FyType cat `"` into ManifestStr
        if FyType is `dir`
        begin
            set MmEntriesStr to entries in BaseDir cat `/data/` cat FyName type `json`
            put json of MmEntriesStr into MmEntries
            put ManifestStr cat `,"months":[` into ManifestStr
            put 0 into MmIdx
            while MmIdx is less than the count of MmEntries
            begin
                put item MmIdx of MmEntries into MmEntry
                put entry `name` of MmEntry into MmName
                put entry `type` of MmEntry into MmType
                if MmIdx is greater than 0
                    put ManifestStr cat `,` into ManifestStr
                put ManifestStr cat `{"name":"` cat MmName cat `","type":"` cat MmType cat `"}` into ManifestStr
                add 1 to MmIdx
            end
            put ManifestStr cat `]` into ManifestStr
        end
        put ManifestStr cat `}` into ManifestStr
        add 1 to FyIdx
    end

    put ManifestStr cat `]}` into ManifestStr
    save ManifestStr to DeployDir cat `/data/index.json`
!! @hash 2f2a98ca
!!!

!! Write the deploy-mode config.json: readonly UI, manifest replaces /list,
!! relative dataReadBase so fetches resolve same-origin, dataWriteBase empty
!! (no writes in static mode).

    save `{
    "readonly": true,
    "manifestUrl": "data/index.json",
    "dataReadBase": "data",
    "dataWriteBase": ""
}
` to DeployDir cat `/config.json`

    print `Built deploy bundle at ` cat DeployDir
    exit
!! @hash 4ec4bb53
!!!