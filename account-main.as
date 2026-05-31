!   account-main.as
!   Service-log GUI for the account project (Phase 6: add / edit / delete).
!
!   Loaded by account.html via server.as. Renders the page from account.json,
!   then walks /data/<FY>/<MM>.json to populate the log. Clicking a row opens
!   the modal pre-filled for editing; the Add button opens it empty. Saving
!   POSTs the affected month back to /write/data/<FY>/<MM>.json and reloads.
!
!   Money is stored as integer pence (1998 = £19.98); mileage as integer
!   tenths-of-a-mile (444 = 44.4). Parsers / formatters in this script
!   convert at the input/render boundaries.

    script Account

!! Variable declarations grouped by purpose. AllSpeak requires all
!! declarations before use, including scratch counters inside loops.

    div Body
    variable Layout
    div LogBody
    div EmptyState
    button LoadSampleBtn

    div Overlay
    div ModalTitle
    button KindServiceBtn
    button KindExpenseBtn
    input DateInput
    div NameRow
    input NameInput
    div LocationRow
    input LocationInput
    div PostcodeRow
    input PostcodeInput
    div TimeRow
    input TimeInput
    div DistanceRow
    input DistanceInput
    div ContactRow
    input ContactInput
    div ClientRow
    input ClientInput
    div DescriptionRow
    input DescriptionInput
    div MileageRow
    input MileageInput
    input ExpenseInput
    input FeesInput
    input LinkInput
    button LinkSentBtn
    div LinkSentDate
    button InvoicedBtn
    div InvoicedDate
    button PaidBtn
    div PaidDate
    button AddButton
    button SaveBtn
    button CancelBtn
    button DeleteBtn
    div ModalStatus

    div DataRowDivs
    div RowWrappers
    a LinkAnchors
    div SubDiv
    div GrandDiv
    div CellDiv

    variable RowStyleData
    variable RowStyleSub
    variable RowStyleGrand
    variable RowWrapperStyle
    variable LinkAnchorStyle
    variable LinkAnchorIdle
    variable Grid
    variable CellRight
    variable CellCenter
    variable ToggleBtnSetStyle
    variable ToggleBtnClearStyle

    variable FyList
    variable NumFys
    variable FyIndex
    variable FyEntry
    variable FyType
    variable FyName

    variable MmList
    variable NumMms
    variable MmIndex
    variable MmEntry
    variable MmType
    variable MmFileName
    variable MmName

    variable Rows
    variable NumRows
    variable RowIndex
    variable Row
    variable Kind

    variable Date
    variable Name
    variable Location
    variable Postcode
    variable Time
    variable Distance
    variable Contact
    variable Client
    variable Description
    variable Mileage
    variable Expense
    variable Paid
    variable Fees
    variable LinkSent
    variable Invoiced

    variable DisplayDate
    variable Mi
    variable MoneyStr
    variable MoneyVal
    variable MileageVal

    variable Parts
    variable Yy
    variable Mo
    variable Dd
    variable Whole
    variable CentsStr
    variable MoneyLen
    variable MoneyPos
    variable MileStr
    variable MileLen
    variable MilePos

    variable LastFy
    variable LastMm
    variable IsFirstRow
    variable MonthLabel

    variable MonthMileage
    variable MonthExpense
    variable MonthFees

    variable GrandMileage
    variable GrandExpense
    variable GrandFees

    variable MonthNames

    variable NumDataRows
    variable NumBuckets
    variable DataIdx

    variable DataRowFys
    variable DataRowMms
    variable DataRowFileIdxs

    variable EditFy
    variable EditMm
    variable EditFileIdx

    variable KindValue
    variable KindSelectedStyle
    variable KindUnselectedStyle
    variable NewKind
    variable NewDate
    variable NewFy
    variable NewMm
    variable NewRow
    variable OrigRows
    variable BucketCount
    variable Bucket
    variable WriteUrl
    variable RowN
    variable PenceInput
    variable TenthsInput
    variable TempStr
    variable TempStr2
    variable BuildMode
    variable SortDates
    variable SortIndices
    variable SortN
    variable SortI
    variable SortJ
    variable SortK
    variable SrcIdx
    variable TempIdx
    variable TempDate

    variable Sample
    variable SampleNum
    variable SampleIdx
    variable SampleEntry
    variable SampleFy
    variable SampleMm
    variable SampleRows

    variable Link
    variable LinkVal

    variable TodayIso
    variable TodayYy
    variable TodayMo
    variable TodayDd

    variable ServiceSeq
    variable SeqStyle

    variable Config
    variable Manifest
    variable ReadOnly
    variable DataReadBase
    variable DataWriteBase
    variable ManifestUrl

    variable OrigDistance
!! @hash 24ee70a2
!!!

!! Boot the GUI: render the Webson layout, attach to the elements we will
!! manipulate, then kick off the initial load and render.

    create Body
    rest get Layout from `account.json`
    render Layout in Body

    attach LogBody to `log-body`
    attach Overlay to `overlay`
    attach ModalTitle to `modal-title`
    attach KindServiceBtn to `kind-service-btn`
    attach KindExpenseBtn to `kind-expense-btn`
    attach DateInput to `date-input`
    attach NameRow to `name-row`
    attach NameInput to `name-input`
    attach LocationRow to `location-row`
    attach LocationInput to `location-input`
    attach PostcodeRow to `postcode-row`
    attach PostcodeInput to `postcode-input`
    attach TimeRow to `time-row`
    attach TimeInput to `time-input`
    attach DistanceRow to `distance-row`
    attach DistanceInput to `distance-input`
    attach ContactRow to `contact-row`
    attach ContactInput to `contact-input`
    attach ClientRow to `client-row`
    attach ClientInput to `client-input`
    attach DescriptionRow to `description-row`
    attach DescriptionInput to `description-input`
    attach MileageRow to `mileage-row`
    attach MileageInput to `mileage-input`
    attach ExpenseInput to `expense-input`
    attach FeesInput to `fees-input`
    attach LinkInput to `link-input`
    attach LinkSentBtn to `linksent-btn`
    attach LinkSentDate to `linksent-date`
    attach InvoicedBtn to `invoiced-btn`
    attach InvoicedDate to `invoiced-date`
    attach PaidBtn to `paid-btn`
    attach PaidDate to `paid-date`
    attach AddButton to `add-button`
    attach SaveBtn to `save-btn`
    attach CancelBtn to `cancel-btn`
    attach DeleteBtn to `delete-btn`
    attach ModalStatus to `modal-status`
    attach EmptyState to `empty-state`
    attach LoadSampleBtn to `load-sample-btn`
!! @hash bd72668d
!!!

!! Cache the shared row-level inline styles.

    put `50px 100px 1fr 60px 1fr 90px 80px 100px 120px 70px 110px 90px 90px 35px 70px` into Grid
    put `display: grid; grid-template-columns: ` cat Grid into RowStyleData
    put RowStyleData cat `; padding: 0.4em 0.4em; border-bottom: 1px solid #eee; cursor: pointer; flex: 1` into RowStyleData
    put `display: grid; grid-template-columns: ` cat Grid into RowStyleSub
    put RowStyleSub cat `; padding: 0.4em calc(30px + 0.4em) 0.4em 0.4em; border-top: 1px solid #aaa; border-bottom: 1px solid #aaa; background: #fafafa; font-weight: bold` into RowStyleSub
    put `display: grid; grid-template-columns: ` cat Grid into RowStyleGrand
    put RowStyleGrand cat `; padding: 0.6em calc(30px + 0.4em) 0.6em 0.4em; border-top: 2px solid #333; background: #eef; font-weight: bold` into RowStyleGrand
    put `display: flex; align-items: stretch` into RowWrapperStyle
    put `width: 30px; display: flex; align-items: center; justify-content: center; text-decoration: none; color: #28a; font-size: 1.1em; border-bottom: 1px solid #eee` into LinkAnchorStyle
    put `width: 30px; display: block; border-bottom: 1px solid #eee` into LinkAnchorIdle
    put `text-align: right; padding-right: 0.4em; color: #666` into SeqStyle
    put `text-align: right` into CellRight
    put `text-align: center; color: #28a; font-weight: bold` into CellCenter
    put `padding: 0.3em 0.9em; cursor: pointer; border: 0; border-radius: 4px; background: #28a; color: white` into KindSelectedStyle
    put `padding: 0.3em 0.9em; cursor: pointer; border: 0; border-radius: 4px; background: #eee; color: #333` into KindUnselectedStyle
    put `padding: 0.3em 0.9em; cursor: pointer; border: 0; border-radius: 4px; background: #eee; color: #333` into ToggleBtnSetStyle
    put `padding: 0.3em 0.9em; cursor: pointer; border: 0; border-radius: 4px; background: #28a; color: white` into ToggleBtnClearStyle
    put `January,February,March,April,May,June,July,August,September,October,November,December` into MonthNames
    split MonthNames on `,`
!! @hash e8444709
!!!

!! Wire up the click and change handlers, then do the initial load.
!!
!! The row-array handler is registered once; AllSpeak fires it with the
!! cursor set to the clicked element's index, which we use to look up the
!! row's (FY, MM, FileIdx) identity from the parallel arrays.

    on click AddButton gosub OnAdd
    on click SaveBtn gosub OnSave
    on click CancelBtn gosub OnCancel
    on click DeleteBtn gosub OnDelete
    on click KindServiceBtn gosub SelectKindService
    on click KindExpenseBtn gosub SelectKindExpense
    on click LoadSampleBtn gosub OnLoadSample
    on click LinkSentBtn gosub OnToggleLinkSent
    on click InvoicedBtn gosub OnToggleInvoiced
    on click PaidBtn gosub OnTogglePaid

    gosub LoadConfig
    gosub Refresh

    stop
!! @hash a06fae12
!!!


!! Refresh: clear the log body and re-render from the on-disk JSON store.
!!
!! Does two passes because AllSpeak's cursor-array model wants pre-sized
!! arrays. Pass 1 counts data rows and distinct buckets so we can size
!! DataRowDivs and its parallel identity arrays; Pass 2 fetches each
!! bucket again and emits rows, monthly subtotals and a grand total.

Refresh:
    set the content of LogBody to ``
    put 0 into NumDataRows
    put 0 into NumBuckets
    put 0 into NumFys

    if ManifestUrl is not empty
    begin
        rest get Manifest from ManifestUrl on failure
        begin
            go to AfterPass1
        end
        put property `fys` of Manifest into FyList
    end
    else
    begin
        rest get FyList from `/list/data` or go to AfterPass1
    end
    put the json count of FyList into NumFys
    put 0 into FyIndex
    while FyIndex is less than NumFys
    begin
        put element FyIndex of FyList into FyEntry
        put property `type` of FyEntry into FyType
        put property `name` of FyEntry into FyName
        if FyType is `dir`
        begin
            if ManifestUrl is not empty
                put property `months` of FyEntry into MmList
            else
                rest get MmList from `/list/data/` cat FyName
            put the json count of MmList into NumMms
            put 0 into MmIndex
            while MmIndex is less than NumMms
            begin
                put element MmIndex of MmList into MmEntry
                put property `type` of MmEntry into MmType
                put property `name` of MmEntry into MmFileName
                if MmType is `file` and MmFileName ends with `.json`
                begin
                    rest get Rows from DataReadBase cat `/` cat FyName cat `/` cat MmFileName
                    put the json count of Rows into NumRows
                    add NumRows to NumDataRows
                    if NumRows is greater than 0
                        add 1 to NumBuckets
                end
                add 1 to MmIndex
            end
        end
        add 1 to FyIndex
    end

AfterPass1:
    if NumDataRows is 0
    begin
        set the style of EmptyState to `display: block; padding: 3em 1em; text-align: center; color: #666`
        return
    end
    set the style of EmptyState to `display: none`

    set the elements of DataRowDivs to NumDataRows
    set the elements of RowWrappers to NumDataRows
    set the elements of LinkAnchors to NumDataRows
    set the elements of DataRowFys to NumDataRows
    set the elements of DataRowMms to NumDataRows
    set the elements of DataRowFileIdxs to NumDataRows

    put 0 into ServiceSeq
    put 0 into GrandMileage
    put 0 into GrandExpense
    put 0 into GrandFees
    put 0 into MonthMileage
    put 0 into MonthExpense
    put 0 into MonthFees
    put empty into LastFy
    put empty into LastMm
    set IsFirstRow
    put 0 into DataIdx

    put 0 into FyIndex
    while FyIndex is less than NumFys
    begin
        put element FyIndex of FyList into FyEntry
        put property `type` of FyEntry into FyType
        put property `name` of FyEntry into FyName
        if FyType is `dir`
        begin
            if ManifestUrl is not empty
                put property `months` of FyEntry into MmList
            else
                rest get MmList from `/list/data/` cat FyName
            put the json count of MmList into NumMms
            put 0 into MmIndex
            while MmIndex is less than NumMms
            begin
                put element MmIndex of MmList into MmEntry
                put property `type` of MmEntry into MmType
                put property `name` of MmEntry into MmFileName
                if MmType is `file` and MmFileName ends with `.json`
                begin
                    put MmFileName into MmName
                    replace `.json` with `` in MmName
                    rest get Rows from DataReadBase cat `/` cat FyName cat `/` cat MmFileName
                    put the json count of Rows into NumRows
                    put 0 into RowIndex
                    while RowIndex is less than NumRows
                    begin
                        put element RowIndex of Rows into Row
                        if FyName is not LastFy or MmName is not LastMm
                        begin
                            if IsFirstRow is false gosub EmitSubtotal
                            put 0 into MonthMileage
                            put 0 into MonthExpense
                            put 0 into MonthFees
                            put FyName into LastFy
                            put MmName into LastMm
                        end

                        index DataRowFys to DataIdx
                        put FyName into DataRowFys
                        index DataRowMms to DataIdx
                        put MmName into DataRowMms
                        index DataRowFileIdxs to DataIdx
                        put RowIndex into DataRowFileIdxs

                        index DataRowDivs to DataIdx
                        gosub EmitDataRow
                        add 1 to DataIdx
                        clear IsFirstRow
                        add 1 to RowIndex
                    end
                end
                add 1 to MmIndex
            end
        end
        add 1 to FyIndex
    end

    if IsFirstRow is false
    begin
        gosub EmitSubtotal
        gosub EmitGrandTotal
    end

    on click DataRowDivs gosub OnRowClick
    return
!! @hash 3eab978d
!!!


!! Render one data row: unpack the dict, accumulate totals, then build a
!! per-row flex wrapper containing [link anchor, body grid]. The link
!! anchor is a sibling of the body — not a child — so a click on it opens
!! the linked document natively without also firing the body's row-click
!! handler (AllSpeak has no `stopPropagation` primitive). Rows with no
!! link still allocate a 30px slot for visual alignment.

EmitDataRow:
    put property `kind` of Row into Kind
    put property `date` of Row into Date
    put property `expense` of Row into Expense
    put property `paid` of Row into Paid
    put property `fees` of Row into Fees
    put property `link` of Row into Link
    put property `linkSent` of Row into LinkSent
    put property `invoiced` of Row into Invoiced
    if Kind is `service`
    begin
        put property `name` of Row into Name
        put property `location` of Row into Location
        put property `postcode` of Row into Postcode
        put property `time` of Row into Time
        put property `distance` of Row into Distance
        put property `contact` of Row into Contact
        put property `client` of Row into Client
        put property `mileage` of Row into Mileage
        put empty into Description
    end
    else
    begin
        put empty into Name
        put empty into Location
        put empty into Postcode
        put empty into Time
        put empty into Distance
        put empty into Contact
        put empty into Client
        put 0 into Mileage
        put property `description` of Row into Description
    end
    add Mileage to MonthMileage
    add Expense to MonthExpense
    add Fees to MonthFees
    add Mileage to GrandMileage
    add Expense to GrandExpense
    add Fees to GrandFees

    create RowWrappers in LogBody
    set the style of RowWrappers to RowWrapperStyle

    create DataRowDivs in RowWrappers
    set the style of DataRowDivs to RowStyleData

    create CellDiv in DataRowDivs
    set the style of CellDiv to SeqStyle
    if Kind is `service`
    begin
        add 1 to ServiceSeq
        put ServiceSeq cat `` into TempStr
        set the content of CellDiv to TempStr
    end
    else
        set the content of CellDiv to ``

    put Date into Parts
    split Parts on `-`
    index Parts to 0
    put Parts into Yy
    index Parts to 1
    put Parts into Mo
    index Parts to 2
    put Parts into Dd
    put Dd cat `/` cat Mo cat `/` cat Yy into DisplayDate
    create CellDiv in DataRowDivs
    set the content of CellDiv to DisplayDate

    create CellDiv in DataRowDivs
    set the content of CellDiv to Name

    create CellDiv in DataRowDivs
    set the content of CellDiv to Time

    create CellDiv in DataRowDivs
    set the content of CellDiv to Location

    create CellDiv in DataRowDivs
    set the content of CellDiv to Postcode

    create CellDiv in DataRowDivs
    put Distance cat `` into Distance
    set the content of CellDiv to Distance

    create CellDiv in DataRowDivs
    set the content of CellDiv to Contact

    create CellDiv in DataRowDivs
    set the content of CellDiv to Client

    create CellDiv in DataRowDivs
    set the style of CellDiv to CellCenter
    if LinkSent
        set the content of CellDiv to `✓`

    create CellDiv in DataRowDivs
    if Kind is `service`
    begin
        put Mileage into MileageVal
        gosub FormatMileage
        set the content of CellDiv to Mi
    end
    else
        set the content of CellDiv to Description

    create CellDiv in DataRowDivs
    set the style of CellDiv to CellRight
    put Expense into MoneyVal
    gosub FormatMoney
    set the content of CellDiv to MoneyStr

    create CellDiv in DataRowDivs
    set the style of CellDiv to CellRight
    put Fees into MoneyVal
    gosub FormatMoney
    set the content of CellDiv to MoneyStr

    create CellDiv in DataRowDivs
    set the style of CellDiv to CellCenter
    if Invoiced
        set the content of CellDiv to `✓`

    create CellDiv in DataRowDivs
    set the style of CellDiv to CellCenter
    if Paid
        set the content of CellDiv to `✓`

    create LinkAnchors in RowWrappers
    if Link is not empty
    begin
        set the style of LinkAnchors to LinkAnchorStyle
        set attribute `href` of LinkAnchors to Link
        set attribute `title` of LinkAnchors to Link
        set the content of LinkAnchors to `🔗`
        set attribute `target` of LinkAnchors to `_blank`
    end
    else
        set the style of LinkAnchors to LinkAnchorIdle
    return
!! @hash 369abb0a
!!!


!! Emit a monthly subtotal row covering the accumulators that have been
!! summed since the last boundary. Subtotal rows don't have click handlers
!! and use a separate single-element SubDiv to avoid polluting DataRowDivs.

EmitSubtotal:
    put LastMm into Mo
    if left 1 of Mo is `0`
        put from 1 of Mo into Mo
    subtract 1 from Mo
    index MonthNames to Mo
    put MonthNames into MonthLabel
    put MonthLabel cat ` ` into MonthLabel
    put LastFy into Parts
    split Parts on `-`
    index Parts to 0
    put Parts into Yy
    put MonthLabel cat Yy cat ` total` into MonthLabel

    create SubDiv in LogBody
    set the style of SubDiv to RowStyleSub

    create CellDiv in SubDiv

    create CellDiv in SubDiv
    set the content of CellDiv to MonthLabel

    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv

    create CellDiv in SubDiv
    put MonthMileage into MileageVal
    gosub FormatMileage
    set the style of CellDiv to CellRight
    set the content of CellDiv to Mi

    create CellDiv in SubDiv
    set the style of CellDiv to CellRight
    put MonthExpense into MoneyVal
    gosub FormatMoney
    set the content of CellDiv to MoneyStr

    create CellDiv in SubDiv
    set the style of CellDiv to CellRight
    put MonthFees into MoneyVal
    gosub FormatMoney
    set the content of CellDiv to MoneyStr

    create CellDiv in SubDiv

    create CellDiv in SubDiv
    return
!! @hash ffe70c49
!!!


!! Emit the grand total row at the foot of the table.

EmitGrandTotal:
    create GrandDiv in LogBody
    set the style of GrandDiv to RowStyleGrand

    create CellDiv in GrandDiv

    create CellDiv in GrandDiv
    set the content of CellDiv to `Grand total`

    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv

    create CellDiv in GrandDiv
    set the style of CellDiv to CellRight
    put GrandMileage into MileageVal
    gosub FormatMileage
    set the content of CellDiv to Mi

    create CellDiv in GrandDiv
    set the style of CellDiv to CellRight
    put GrandExpense into MoneyVal
    gosub FormatMoney
    set the content of CellDiv to MoneyStr

    create CellDiv in GrandDiv
    set the style of CellDiv to CellRight
    put GrandFees into MoneyVal
    gosub FormatMoney
    set the content of CellDiv to MoneyStr

    create CellDiv in GrandDiv

    create CellDiv in GrandDiv
    return
!! @hash 80f5e436
!!!


!! OnAdd: open the modal in Add mode — empty form, no Delete button.
!!
!! EditFy is the sentinel: empty means "adding a new row"; non-empty means
!! "editing a row at (EditFy, EditMm, EditFileIdx)".

OnAdd:
    put empty into EditFy
    put empty into EditMm
    put 0 into EditFileIdx
    set the content of ModalTitle to `Add booking`
    set the content of DateInput to ``
    set the content of NameInput to ``
    set the content of LocationInput to ``
    set the content of PostcodeInput to ``
    set the content of TimeInput to ``
    set the content of DistanceInput to ``
    set the content of ContactInput to ``
    set the content of ClientInput to ``
    set the content of DescriptionInput to ``
    set the content of MileageInput to ``
    set the content of ExpenseInput to ``
    set the content of FeesInput to ``
    set the content of LinkInput to ``
    put empty into LinkSent
    gosub RefreshLinkSentDisplay
    put empty into Invoiced
    gosub RefreshInvoicedDisplay
    clear Paid
    gosub RefreshPaidDisplay
    set the content of ModalStatus to ``
    put empty into OrigDistance
    set the style of DeleteBtn to `display: none`
    gosub SelectKindService
    set the style of Overlay to `display: flex; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 100; justify-content: center; align-items: center`
    return
!! @hash 7af064b4
!!!


!! OnRowClick: open the modal in Edit mode for the clicked row.
!!
!! `the index of DataRowDivs` returns the slot of the clicked element. We
!! refetch the bucket file (rather than caching across Refresh boundaries)
!! and read the row at FileIdx for the prefill.

OnRowClick:
    put the index of DataRowDivs into RowN
    index DataRowFys to RowN
    put DataRowFys into EditFy
    index DataRowMms to RowN
    put DataRowMms into EditMm
    index DataRowFileIdxs to RowN
    put DataRowFileIdxs into EditFileIdx
    rest get Rows from DataReadBase cat `/` cat EditFy cat `/` cat EditMm cat `.json`
    put element EditFileIdx of Rows into Row
    set the content of ModalTitle to `Edit booking`
    put property `kind` of Row into Kind
    if Kind is `service`
        gosub SelectKindService
    else
        gosub SelectKindExpense
    put property `date` of Row into Date
    set the content of DateInput to Date
    if Kind is `service`
    begin
        put property `name` of Row into Name
        put property `location` of Row into Location
        put property `postcode` of Row into Postcode
        put property `time` of Row into Time
        put property `distance` of Row into Distance
        put property `contact` of Row into Contact
        put property `client` of Row into Client
        put property `mileage` of Row into MileageVal
        set the content of NameInput to Name
        set the content of LocationInput to Location
        set the content of PostcodeInput to Postcode
        set the content of TimeInput to Time
        put Distance cat `` into Distance
        set the content of DistanceInput to Distance
        put Distance into OrigDistance
        set the content of ContactInput to Contact
        set the content of ClientInput to Client
        gosub FormatMileage
        set the content of MileageInput to Mi
        set the content of DescriptionInput to ``
    end
    else
    begin
        put property `description` of Row into Description
        set the content of DescriptionInput to Description
        set the content of NameInput to ``
        set the content of LocationInput to ``
        set the content of PostcodeInput to ``
        set the content of TimeInput to ``
        set the content of DistanceInput to ``
        put empty into OrigDistance
        set the content of ContactInput to ``
        set the content of ClientInput to ``
        set the content of MileageInput to ``
    end
    put property `expense` of Row into MoneyVal
    gosub FormatMoneyPlain
    set the content of ExpenseInput to MoneyStr
    put property `fees` of Row into MoneyVal
    gosub FormatMoneyPlain
    set the content of FeesInput to MoneyStr
    put property `link` of Row into Link
    set the content of LinkInput to Link
    put property `linkSent` of Row into LinkSent
    gosub RefreshLinkSentDisplay
    put property `invoiced` of Row into Invoiced
    gosub RefreshInvoicedDisplay
    put property `paid` of Row into Paid
    gosub RefreshPaidDisplay
    set the content of ModalStatus to ``
    if ReadOnly
        set the style of DeleteBtn to `display: none`
    else
        set the style of DeleteBtn to `display: inline-block; padding: 0.4em 1em; background: #d33; color: white; border: 0; border-radius: 4px; cursor: pointer`
    set the style of Overlay to `display: flex; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 100; justify-content: center; align-items: center`
    return
!! @hash 395ef511
!!!


!! SelectKindService / SelectKindExpense: handle clicks on the segmented-
!! control kind buttons. Each updates KindValue, restyles the pair (the
!! active button gets `KindSelectedStyle`, the other gets the unselected
!! style), then toggles the service-only vs expense-only field rows.

SelectKindService:
    put `service` into KindValue
    set the style of KindServiceBtn to KindSelectedStyle
    set the style of KindExpenseBtn to KindUnselectedStyle
    gosub ApplyKindVisibility
    return
!! @hash 5fb44e98
!!!


!! SelectKindExpense: mirror of SelectKindService for the Expense button.

SelectKindExpense:
    put `expense` into KindValue
    set the style of KindServiceBtn to KindUnselectedStyle
    set the style of KindExpenseBtn to KindSelectedStyle
    gosub ApplyKindVisibility
    return
!! @hash 5644738b
!!!


!! ApplyKindVisibility: show/hide form rows based on KindValue.

ApplyKindVisibility:
    if KindValue is `service`
    begin
        set the style of NameRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
        set the style of LocationRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
        set the style of PostcodeRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
        set the style of TimeRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
        set the style of DistanceRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
        set the style of ContactRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
        set the style of ClientRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
        set the style of MileageRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
        set the style of DescriptionRow to `display: none`
    end
    else
    begin
        set the style of NameRow to `display: none`
        set the style of LocationRow to `display: none`
        set the style of PostcodeRow to `display: none`
        set the style of TimeRow to `display: none`
        set the style of DistanceRow to `display: none`
        set the style of ContactRow to `display: none`
        set the style of ClientRow to `display: none`
        set the style of MileageRow to `display: none`
        set the style of DescriptionRow to `display: flex; align-items: baseline; gap: 0.5em; margin-bottom: 0.4em`
    end
    return
!! @hash f4fdedb9
!!!


!! OnCancel: close the modal without saving.

OnCancel:
    set the content of ModalStatus to ``
    set the style of Overlay to `display: none`
    return
!! @hash 440c3b13
!!!


!! OnSave: read the form, build a row dict, POST it to the right month
!! file, then refresh the table.
!!
!! Add mode (EditFy empty): fetch the target month's array (or empty if
!! the file is missing), append the new row, POST.
!! Edit mode same month: fetch, replace at EditFileIdx, POST.
!! Edit mode different month: fetch old, splice out, POST old; fetch new,
!! append, POST new. Two writes but the cross-month case is rare.

OnSave:
    put KindValue into NewKind
    put the content of DateInput into NewDate
    put the content of DescriptionInput into Description
    put empty into TempStr
    if NewDate is empty
        put TempStr cat `Date is required. ` into TempStr
    if NewKind is `expense` and Description is empty
        put TempStr cat `Description is required for expense rows. ` into TempStr
    if TempStr is not empty
    begin
        set the content of ModalStatus to TempStr
        return
    end
    set the content of ModalStatus to ``
    gosub ComputeFyMm

    set NewRow to object
    set property `kind` of NewRow to NewKind
    set property `date` of NewRow to NewDate
    if NewKind is `service`
    begin
        put the content of NameInput into Name
        put the content of LocationInput into Location
        put the content of PostcodeInput into Postcode
        put the content of TimeInput into Time
        put the content of DistanceInput into Distance
        put the content of ContactInput into Contact
        put the content of ClientInput into Client
        put the content of MileageInput into TempStr
        set property `name` of NewRow to Name
        set property `location` of NewRow to Location
        set property `postcode` of NewRow to Postcode
        set property `time` of NewRow to Time
        set property `distance` of NewRow to Distance
        set property `contact` of NewRow to Contact
        set property `client` of NewRow to Client
        gosub ParseMileageInput
        set property `mileage` of NewRow to TenthsInput
    end
    else
    begin
        set property `description` of NewRow to Description
    end
    put the content of ExpenseInput into TempStr
    gosub ParseMoneyInput
    set property `expense` of NewRow to PenceInput
    put the content of FeesInput into TempStr
    gosub ParseMoneyInput
    set property `fees` of NewRow to PenceInput
    put the content of LinkInput into LinkVal
    if LinkVal is not empty
        set property `link` of NewRow to LinkVal
    if LinkSent is not empty
        set property `linkSent` of NewRow to LinkSent
    else
        set property `linkSent` of NewRow to false
    if Invoiced is not empty
        set property `invoiced` of NewRow to Invoiced
    else
        set property `invoiced` of NewRow to false
    if Paid
        set property `paid` of NewRow to Paid
    else
        set property `paid` of NewRow to false

    if NewKind is `service`
    begin
        if Distance is not empty and Distance is not OrigDistance
        begin
            put Distance into TempStr
            gosub ParseMileageInput
            put TenthsInput into MileageVal
            multiply MileageVal by 2
            set property `mileage` of NewRow to MileageVal
            put TenthsInput into PenceInput
            multiply PenceInput by 9
            set property `expense` of NewRow to PenceInput
        end
    end

    if EditFy is empty
        gosub PostAdd
    else if EditFy is NewFy and EditMm is NewMm
        gosub PostReplace
    else
        gosub PostMove

    set the style of Overlay to `display: none`
    gosub Refresh
    return
!! @hash 14374b1a
!!!


!! PostAdd: fetch the target bucket, hand off to BuildSortedBucket in
!! `add` mode, POST the resulting array.

PostAdd:
    rest get OrigRows from DataReadBase cat `/` cat NewFy cat `/` cat NewMm cat `.json` on failure
    begin
        set OrigRows to array
    end
    put the json count of OrigRows into BucketCount
    put `add` into BuildMode
    gosub BuildSortedBucket
    put DataWriteBase cat `/` cat NewFy cat `/` cat NewMm cat `.json` into WriteUrl
    rest post Bucket to WriteUrl
    return
!! @hash 6ccc9ac0
!!!


!! PostReplace: same-bucket edit — BuildSortedBucket in `replace` mode
!! swaps NewRow in at EditFileIdx.

PostReplace:
    rest get OrigRows from DataReadBase cat `/` cat EditFy cat `/` cat EditMm cat `.json`
    put the json count of OrigRows into BucketCount
    put `replace` into BuildMode
    gosub BuildSortedBucket
    put DataWriteBase cat `/` cat EditFy cat `/` cat EditMm cat `.json` into WriteUrl
    rest post Bucket to WriteUrl
    return
!! @hash 9888c1ca
!!!


!! PostMove: cross-bucket edit — remove from the old bucket (POSTs it),
!! then BuildSortedBucket in `add` mode on the new bucket and POST that.

PostMove:
    gosub RemoveFromOldBucket
    rest get OrigRows from DataReadBase cat `/` cat NewFy cat `/` cat NewMm cat `.json` on failure
    begin
        set OrigRows to array
    end
    put the json count of OrigRows into BucketCount
    put `add` into BuildMode
    gosub BuildSortedBucket
    put DataWriteBase cat `/` cat NewFy cat `/` cat NewMm cat `.json` into WriteUrl
    rest post Bucket to WriteUrl
    return
!! @hash 8f311aa9
!!!


!! RemoveFromOldBucket: BuildSortedBucket in `remove` mode skips
!! EditFileIdx; POST the shorter array.

RemoveFromOldBucket:
    rest get OrigRows from DataReadBase cat `/` cat EditFy cat `/` cat EditMm cat `.json`
    put the json count of OrigRows into BucketCount
    put `remove` into BuildMode
    gosub BuildSortedBucket
    put DataWriteBase cat `/` cat EditFy cat `/` cat EditMm cat `.json` into WriteUrl
    rest post Bucket to WriteUrl
    return
!! @hash 75fb1e4f
!!!


!! OnDelete: confirm with the user, then remove the edited row from its bucket and POST.
!!
!! Uses AllSpeak's `confirm` primitive (an OK/Cancel browser dialog). On OK the `DoDelete` subroutine runs; on Cancel the script just returns to the modal in its current state — the user can adjust and Save, or Cancel out manually.

OnDelete:
    if EditFy is empty
        return
    confirm `Delete this booking?` gosub DoDelete
    return
!! @hash 18022b74
!!!


!! DoDelete: the actual removal — strip the edited row from its bucket, POST, hide the overlay, refresh the table.

DoDelete:
    gosub RemoveFromOldBucket
    set the style of Overlay to `display: none`
    gosub Refresh
    return
!! @hash bf26399f
!!!


!! OnLoadSample: fetch sample.json and write each bucket to /write/data/<FY>/<MM>.json.
!!
!! Shown only when the data folder is empty — gives a fresh checkout something to look at without forcing the user to invent bookings from scratch. The /write/ endpoint auto-creates parent directories, so we don't need to mkdir the FY folders ourselves. After all buckets are posted we just Refresh, which re-walks /list/data and renders the new table.

OnLoadSample:
    rest get Sample from `/read/sample.json`
    put the json count of Sample into SampleNum
    put 0 into SampleIdx
    while SampleIdx is less than SampleNum
    begin
        put element SampleIdx of Sample into SampleEntry
        put property `fy` of SampleEntry into SampleFy
        put property `mm` of SampleEntry into SampleMm
        put property `rows` of SampleEntry into SampleRows
        put `/write/data/` cat SampleFy cat `/` cat SampleMm cat `.json` into WriteUrl
        rest post SampleRows to WriteUrl
        add 1 to SampleIdx
    end
    gosub Refresh
    return
!! @hash 0eac7a55
!!!


!! ComputeTodayIso: produce today's local date as a YYYY-MM-DD string in TodayIso.
!!
!! Uses the bare `the year` / `the month` / `the day number` accessors, which return the corresponding components of "now" when no `of <timestamp>` operand is supplied. `the month` is 0-indexed (Jan = 0), so we add 1 before formatting. Month and day are zero-padded so the resulting string sorts the same way the on-disk date strings do.

ComputeTodayIso:
    put the year into TodayYy
    put the month into TodayMo
    add 1 to TodayMo
    put the day number into TodayDd
    put TodayMo cat `` into TempStr
    if the length of TempStr is 1
        put `0` cat TempStr into TempStr
    put TempStr into TodayMo
    put TodayDd cat `` into TempStr
    if the length of TempStr is 1
        put `0` cat TempStr into TempStr
    put TempStr into TodayDd
    put TodayYy cat `-` cat TodayMo cat `-` cat TodayDd into TodayIso
    return
!! @hash 44738a6e
!!!


!! RefreshLinkSentDisplay / RefreshPaidDisplay: paint the toggle button and date pill from the current state.
!!
!! Each toggle stores either a date string ("set") or a falsy value (empty / false from a migrated record). Truthy state shows "Clear" + the date; falsy state shows "Set" with no date. The display refresh is the single place that reads state and updates DOM, so handlers just mutate the variable and call this.

RefreshLinkSentDisplay:
    if LinkSent
    begin
        set the content of LinkSentBtn to `Clear`
        set the style of LinkSentBtn to ToggleBtnClearStyle
        set the content of LinkSentDate to LinkSent
    end
    else
    begin
        set the content of LinkSentBtn to `Set`
        set the style of LinkSentBtn to ToggleBtnSetStyle
        set the content of LinkSentDate to ``
    end
    return
!! @hash 0a4c0236
!!!


!! RefreshPaidDisplay: mirror of RefreshLinkSentDisplay for the Paid toggle.

RefreshPaidDisplay:
    if Paid
    begin
        set the content of PaidBtn to `Clear`
        set the style of PaidBtn to ToggleBtnClearStyle
        set the content of PaidDate to Paid
    end
    else
    begin
        set the content of PaidBtn to `Set`
        set the style of PaidBtn to ToggleBtnSetStyle
        set the content of PaidDate to ``
    end
    return
!! @hash 4ba0c699
!!!


!! OnToggleLinkSent / OnTogglePaid: flip the toggle and refresh its display.
!!
!! Setting captures today's date; clearing drops to empty so the truthiness check above lights up the "Set" face of the button.

OnToggleLinkSent:
    if LinkSent
        put empty into LinkSent
    else
    begin
        gosub ComputeTodayIso
        put TodayIso into LinkSent
    end
    gosub RefreshLinkSentDisplay
    return
!! @hash 6cec39eb
!!!


!! OnTogglePaid: mirror of OnToggleLinkSent for the Paid toggle.

OnTogglePaid:
    if Paid
        put empty into Paid
    else
    begin
        gosub ComputeTodayIso
        put TodayIso into Paid
    end
    gosub RefreshPaidDisplay
    return
!! @hash 1ce1fcba
!!!


!! RefreshInvoicedDisplay: paint the Invoiced toggle button and date pill from the current state.

RefreshInvoicedDisplay:
    if Invoiced
    begin
        set the content of InvoicedBtn to `Clear`
        set the style of InvoicedBtn to ToggleBtnClearStyle
        set the content of InvoicedDate to Invoiced
    end
    else
    begin
        set the content of InvoicedBtn to `Set`
        set the style of InvoicedBtn to ToggleBtnSetStyle
        set the content of InvoicedDate to ``
    end
    return
!! @hash 0405915e
!!!


!! OnToggleInvoiced: mirror of OnTogglePaid for the Invoiced toggle.

OnToggleInvoiced:
    if Invoiced
        put empty into Invoiced
    else
    begin
        gosub ComputeTodayIso
        put TodayIso into Invoiced
    end
    gosub RefreshInvoicedDisplay
    return
!! @hash ac62f392
!!!


!! LoadConfig: load config.json and apply mode-driven settings.
!!
!! Three modes the app supports, switched entirely by config:
!!   1. Live local server (default if no config.json is present): reads from
!!      /list/data and /read/data/..., writes to /write/data/... — same as
!!      the original behaviour, served by server.as.
!!   2. Static read-only deploy: reads from a flat manifest (data/index.json)
!!      and a relative dataReadBase like `data`. No writes; the Add button
!!      and the modal's Save/Delete buttons are hidden. Suited to hosting
!!      on Cloudflare Pages / Netlify / similar for an accountant view.
!!   3. (Future) any other backend that can satisfy the same shape — only
!!      the URL bases / readonly flag need to change.
!!
!! Defaults are set first so the live app works even with no config.json
!! committed; the deploy bundle ships a config.json that overrides.

LoadConfig:
    put `/read/data` into DataReadBase
    put `/write/data` into DataWriteBase
    put empty into ManifestUrl
    put 0 into ReadOnly
    rest get Config from `config.json` on failure
    begin
        return
    end
    put property `dataReadBase` of Config into DataReadBase
    put property `dataWriteBase` of Config into DataWriteBase
    put property `manifestUrl` of Config into ManifestUrl
    put property `readonly` of Config into ReadOnly
    if ReadOnly
    begin
        set the style of AddButton to `display: none`
        set the style of SaveBtn to `display: none`
        set the content of CancelBtn to `Close`
    end
    return
!! @hash e45b08c5
!!!


!! ComputeFyMm: parse NewDate (ISO YYYY-MM-DD), set NewFy and NewMm.
!!
!! UK financial year runs 6 April → 5 April. A date on or after 6 April of
!! year Y is in FY "Y-(Y+1)"; earlier is in "(Y-1)-Y".

ComputeFyMm:
    put NewDate into Parts
    split Parts on `-`
    index Parts to 0
    put Parts into Yy
    index Parts to 1
    put Parts into Mo
    index Parts to 2
    put Parts into Dd
    put Mo into NewMm

    put Yy into RowN
    if Mo is `01` or Mo is `02` or Mo is `03`
        subtract 1 from RowN
    else if Mo is `04`
    begin
        if Dd is `01` or Dd is `02` or Dd is `03` or Dd is `04` or Dd is `05`
            subtract 1 from RowN
    end
    put RowN into BucketCount
    add 1 to BucketCount
    put BucketCount cat `` into TempStr
    put the length of TempStr into MoneyLen
    put MoneyLen into MoneyPos
    subtract 2 from MoneyPos
    put from MoneyPos of TempStr into CentsStr
    put RowN cat `-` cat CentsStr into NewFy
    return
!! @hash dcf5fe56
!!!


!! ParseMoneyInput: read TempStr ("£X.XX" / "X.XX" / "£X" / "1,234.56" /
!! ""), normalise to integer pence in PenceInput. Empty → 0.

ParseMoneyInput:
    replace `£` with `` in TempStr
    replace `,` with `` in TempStr
    put trim TempStr into TempStr
    if TempStr is empty
    begin
        put 0 into PenceInput
        return
    end
    if TempStr includes `.`
    begin
        put TempStr into Parts
        split Parts on `.`
        index Parts to 0
        put Parts into Whole
        index Parts to 1
        put Parts into CentsStr
        if Whole is empty put `0` into Whole
        if the length of CentsStr is 1 put CentsStr cat `0` into CentsStr
        if the length of CentsStr is greater than 2
            put from 0 to 2 of CentsStr into CentsStr
        if Whole is numeric and CentsStr is numeric
        begin
            put Whole into PenceInput
            multiply PenceInput by 100
            add CentsStr to PenceInput
        end
        else
            put 0 into PenceInput
    end
    else
    begin
        if TempStr is numeric
        begin
            put TempStr into PenceInput
            multiply PenceInput by 100
        end
        else
            put 0 into PenceInput
    end
    return
!! @hash 6063a4d3
!!!


!! ParseMileageInput: read TempStr ("44.4" / "44" / ""), normalise to
!! integer tenths in TenthsInput. Empty → 0.

ParseMileageInput:
    put trim TempStr into TempStr
    if TempStr is empty
    begin
        put 0 into TenthsInput
        return
    end
    if TempStr includes `.`
    begin
        put TempStr into Parts
        split Parts on `.`
        index Parts to 0
        put Parts into Whole
        index Parts to 1
        put Parts into CentsStr
        if Whole is empty put `0` into Whole
        if the length of CentsStr is 0 put `0` into CentsStr
        put from 0 to 1 of CentsStr into CentsStr
        if Whole is numeric and CentsStr is numeric
        begin
            put Whole into TenthsInput
            multiply TenthsInput by 10
            add CentsStr to TenthsInput
        end
        else
            put 0 into TenthsInput
    end
    else
    begin
        if TempStr is numeric
        begin
            put TempStr into TenthsInput
            multiply TenthsInput by 10
        end
        else
            put 0 into TenthsInput
    end
    return
!! @hash b48ef964
!!!


!! FormatMoney: integer pence → "£X.XX" in MoneyStr. Zero becomes empty.

FormatMoney:
    if MoneyVal is 0
    begin
        put empty into MoneyStr
        return
    end
    put MoneyVal cat `` into MoneyStr
    put the length of MoneyStr into MoneyLen
    if MoneyLen is 1
    begin
        put `£0.0` cat MoneyStr into MoneyStr
        return
    end
    if MoneyLen is 2
    begin
        put `£0.` cat MoneyStr into MoneyStr
        return
    end
    put MoneyLen into MoneyPos
    subtract 2 from MoneyPos
    put from 0 to MoneyPos of MoneyStr into Whole
    put from MoneyPos of MoneyStr into CentsStr
    put `£` cat Whole cat `.` cat CentsStr into MoneyStr
    return
!! @hash f3ee663d
!!!


!! FormatMoneyPlain: same as FormatMoney but without the leading £, for
!! prefilling the form's text inputs (so the user sees "19.98" not "£19.98").

FormatMoneyPlain:
    if MoneyVal is 0
    begin
        put empty into MoneyStr
        return
    end
    put MoneyVal cat `` into MoneyStr
    put the length of MoneyStr into MoneyLen
    if MoneyLen is 1
    begin
        put `0.0` cat MoneyStr into MoneyStr
        return
    end
    if MoneyLen is 2
    begin
        put `0.` cat MoneyStr into MoneyStr
        return
    end
    put MoneyLen into MoneyPos
    subtract 2 from MoneyPos
    put from 0 to MoneyPos of MoneyStr into Whole
    put from MoneyPos of MoneyStr into CentsStr
    put Whole cat `.` cat CentsStr into MoneyStr
    return
!! @hash 5fd4b20a
!!!


!! FormatMileage: integer tenths → "XX.X" in Mi. Zero becomes empty.

FormatMileage:
    if MileageVal is 0
    begin
        put empty into Mi
        return
    end
    put MileageVal cat `` into MileStr
    put the length of MileStr into MileLen
    if MileLen is 1
    begin
        put `0.` cat MileStr into Mi
        return
    end
    put MileLen into MilePos
    subtract 1 from MilePos
    put from 0 to MilePos of MileStr into Whole
    put from MilePos of MileStr into CentsStr
    put Whole cat `.` cat CentsStr into Mi
    return
!! @hash 0470c9b4
!!!


!! BuildSortedBucket: produce Bucket as a JSON array of row dicts drawn
!! from OrigRows (and optionally NewRow), ordered by date ascending.
!!
!! Inputs (globals):
!!   BuildMode    — `add` | `replace` | `remove`
!!   OrigRows     — array of existing row dicts (may be empty for add)
!!   BucketCount  — `the json count of OrigRows`
!!   NewRow       — the new/edited row (for add and replace)
!!   EditFileIdx  — the slot of the existing row being replaced or removed
!!
!! Output:
!!   Bucket       — JSON array ready to POST via `rest post Bucket to URL`
!!
!! Building proceeds in three phases: pick the source for each logical
!! position, sort those positions by date, then `json add` the rows into
!! Bucket in sorted order. `json add` is the array-aware writer documented
!! in Reference 4 / 18 — using `put V into Bucket` would replace the slot
!! and lose the array wrapper. ISO date strings sort lexicographically
!! into chronological order, so a plain string sort on `date` does it.

BuildSortedBucket:
    if BuildMode is `add`
    begin
        put BucketCount into SortN
        add 1 to SortN
    end
    else if BuildMode is `remove`
    begin
        put BucketCount into SortN
        subtract 1 from SortN
    end
    else
        put BucketCount into SortN

    set Bucket to array
    if SortN is 0
        return

    set the elements of SortDates to SortN
    set the elements of SortIndices to SortN

    put 0 into SortI
    while SortI is less than SortN
    begin
        gosub ComputeSourceIdx
        gosub RowFromSrc
        put property `date` of Row into TempDate
        index SortDates to SortI
        put TempDate into SortDates
        index SortIndices to SortI
        put SrcIdx into SortIndices
        add 1 to SortI
    end

    gosub BubbleSortByDate

    put 0 into SortI
    while SortI is less than SortN
    begin
        index SortIndices to SortI
        put SortIndices into SrcIdx
        gosub RowFromSrc
        json add Row to Bucket
        add 1 to SortI
    end
    return
!! @hash e307d5c6
!!!


!! ComputeSourceIdx: given BuildMode and the logical position SortI,
!! set SrcIdx to the row's "source code":
!!   BucketCount  — use NewRow
!!   0..BucketCount-1 — index into OrigRows
!!
!! For `add`, NewRow sits at logical position BucketCount.
!! For `replace`, NewRow takes the EditFileIdx slot; everything else maps
!! straight through.
!! For `remove`, the EditFileIdx row is skipped — logical positions at or
!! above EditFileIdx shift up by one.

ComputeSourceIdx:
    if BuildMode is `replace`
    begin
        if SortI is EditFileIdx
            put BucketCount into SrcIdx
        else
            put SortI into SrcIdx
    end
    else if BuildMode is `add`
    begin
        if SortI is BucketCount
            put BucketCount into SrcIdx
        else
            put SortI into SrcIdx
    end
    else
    begin
        put SortI into SrcIdx
        if SortI is greater than EditFileIdx
            add 1 to SrcIdx
        else if SortI is EditFileIdx
            add 1 to SrcIdx
    end
    return
!! @hash e0841a4c
!!!


!! RowFromSrc: read Row from OrigRows[SrcIdx], or from NewRow if SrcIdx
!! equals BucketCount (the sentinel value set by ComputeSourceIdx).

RowFromSrc:
    if SrcIdx is BucketCount
        put NewRow into Row
    else
        put element SrcIdx of OrigRows into Row
    return
!! @hash fe8ff233
!!!


!! BubbleSortByDate: in-place bubble sort of SortDates with SortIndices
!! shifted in lockstep. O(N²) is fine for our row counts (small).

BubbleSortByDate:
    put SortN into SortI
    subtract 1 from SortI
    while SortI is greater than 0
    begin
        put 0 into SortJ
        while SortJ is less than SortI
        begin
            put SortJ into SortK
            add 1 to SortK
            index SortDates to SortJ
            put SortDates into TempStr
            index SortDates to SortK
            put SortDates into TempStr2
            if TempStr is greater than TempStr2
            begin
                index SortDates to SortJ
                put TempStr2 into SortDates
                index SortDates to SortK
                put TempStr into SortDates
                index SortIndices to SortJ
                put SortIndices into TempIdx
                index SortIndices to SortK
                put SortIndices into SrcIdx
                index SortIndices to SortJ
                put SrcIdx into SortIndices
                index SortIndices to SortK
                put TempIdx into SortIndices
            end
            add 1 to SortJ
        end
        subtract 1 from SortI
    end
    return
!! @hash 94428012
!!!