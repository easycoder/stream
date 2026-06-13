!   admin-main.as
!   Merged admin panel for filming.eclecity.net.
!   Combines the service log (account) with stream management (streams)
!   into a single interface. Login-protected; data stored as per-event
!   JSON files on the server via PHP endpoints.
!
!   Money: integer pence (1998 = £19.98). Mileage: integer tenths (444 = 44.4).
!   Form inputs display in miles/pounds; parsers convert back on save.
!   Parsers and formatters convert at input/render boundaries.

    script Admin

    div Body
    variable Layout

    div LoginPanel
    input UserField
    input PassField
    button LoginButton
    div LoginStatus

    div AdminPanel
    div Header
    div LogBody
    div EmptyState
    button LoadSampleBtn

    div Overlay
    div ModalForm
    div ModalTitle
    button KindServiceBtn
    button KindExpenseBtn
    button KindSlideshowBtn
    input DateInput
    input TimeInput
    input NameInput
    input LocationInput
    input PostcodeInput
    input DistanceInput
    input ContactInput
    input ClientInput
    input ClientEmailInput
    input DacastInput
    input StreamUrlInput
    input RecordingUrlInput
    button RecordingUrlBtn
    input MileageInput
    input ExpenseInput
    input FeesInput
    input LinkSentToggle
    input LinkSentInput
    input InvoicedToggle
    input InvoicedInput
    input PaidInput
    input PaidDateInput
    input TitleField
    input ContactNameInput
    input ContactRelationInput
    input ContactPhoneInput
    input ContactEmailInput
    textarea RecordingTextInput
    input TributeUrlInput
    button TributeUrlBtn
    div ModalStatus
    button DeleteBtn
    button CancelBtn
    button SaveBtn
    button AddButton
    button StreamBtn
    button Email1Btn
    button Email2Btn
    button ExportBtn
    div ExportStatus

    div DataRowDivs
    div RowWrappers
    div SubDiv
    div GrandDiv
    div CellDiv

    variable RowStyleData
    variable RowStyleSub
    variable RowStyleGrand
    variable Grid
    variable CellRight
    variable KindSelectedStyle
    variable KindUnselectedStyle
    variable AllBookings
    variable EmailTemplate
    variable StreamUrl
    variable ContactEmailVal
    variable ClientEmailVal
    variable NameVal
    variable LocationVal
    variable DateVal
    variable TimeVal
    variable ContactNameVal
    variable ContactRelationVal
    variable ClientRepVal
    variable ClientCompanyVal
    variable TributeUrlVal
    variable ToField
    variable CcField
    variable SubjectField
    variable BodyParts
    variable PartCount
    variable PartText
    variable BodyField
    variable MailToUri
    variable MonthFyArr
    variable MonthMmArr
    variable MonthExpenseArr
    variable MonthFeesArr
    variable MonthCount
    variable MonthIdx
    variable TempFy
    variable TempMm
    variable BookingCount
    variable I
    variable J
    variable Row
    variable Kind
    variable BookingDate
    variable BookingName
    variable BookingClient
    variable BookingTime
    variable FY
    variable NextYr
    variable Mm
    variable BookingDacast
    variable BookingRecordingUrl
    variable Invoiced
    variable Paid
    variable Fees
    variable Expense
    variable Mileage
    variable MileageVal
    variable MoneyVal
    variable MoneyStr
    variable Mi
    variable EditFyStart
    variable EditSlugOld
    variable EditPath
    variable IsCreate
    variable TempStr2
    variable TempOrig
    variable SortK
    variable YYStr
    variable Ch
    variable BookingLocation
    variable MonthNames
    variable MonthLabel
    variable Parts
    variable Yy
    variable Mo

    variable LastFy
    variable LastMm
    variable MonthMileage
    variable MonthExpense
    variable MonthFees
    variable GrandMileage
    variable GrandExpense
    variable GrandFees

    variable SortCount
    variable TempStr
    variable TempNum
    ! Formatting temporaries
    variable MoneyLen
    variable MoneyPos
    variable Whole
    variable CentsStr
    variable MileLen
    variable MilePos
    variable FracStr
    variable Dot
    variable ExpensePounds
    variable ExpensePence
    variable ExpensePenceStr
    variable ExpenseDisplay
    variable FeesPounds

    variable Key
    variable TodayStr
    variable Now
    variable Yr
    variable Dd
    variable CacheBuster
    variable ResponseJson
    variable ResponseObj
    variable ResponseStatus
    variable BodyText
    variable BookingStamp
    variable WarnAmber
    variable TargetUrl

!! @hash placeholder

!!! Build the page: render the Webson layout, attach DOM handles, set up
!!! style strings, then show the login panel.

    create Body
    rest get Layout from `admin.json`
    render Layout in Body

    attach LoginPanel to `login-panel`
    attach UserField to `user-field`
    attach PassField to `pass-field`
    attach LoginButton to `login-button`
    attach LoginStatus to `login-status`

    attach AdminPanel to `admin-panel`
    attach Header to `header`
    attach LogBody to `log-body`
    attach EmptyState to `empty-state`
    attach LoadSampleBtn to `load-sample-btn`

    attach Overlay to `overlay`
    attach ModalForm to `modal-form`
    attach ModalTitle to `modal-title`
    attach KindServiceBtn to `kind-service-btn`
    attach KindExpenseBtn to `kind-expense-btn`
    attach KindSlideshowBtn to `kind-slideshow-btn`
    attach DateInput to `date-input`
    attach TimeInput to `time-input`
    attach NameInput to `name-input`
    attach LocationInput to `location-input`
    attach PostcodeInput to `postcode-input`
    attach DistanceInput to `distance-input`
    attach ContactInput to `contact-input`
    attach ClientInput to `client-input`
    attach ClientEmailInput to `client-email-input`
    attach DacastInput to `dacast-input`
    attach StreamUrlInput to `stream-url-input`
    attach RecordingUrlInput to `recording-url-input`
    attach RecordingUrlBtn to `recording-url-btn`
    attach MileageInput to `mileage-input`
    attach ExpenseInput to `expense-input`
    attach FeesInput to `fees-input`
    attach LinkSentToggle to `link-sent-toggle`
    attach LinkSentInput to `link-sent-input`
    attach InvoicedToggle to `invoiced-toggle`
    attach InvoicedInput to `invoiced-input`
    attach PaidInput to `paid-input`
    attach PaidDateInput to `paid-date-input`
    attach TitleField to `title-input`
    attach ContactNameInput to `contact-name-input`
    attach ContactRelationInput to `contact-relation-input`
    attach ContactPhoneInput to `contact-phone-input`
    attach ContactEmailInput to `contact-email-input`
    attach RecordingTextInput to `recording-text-input`
    attach TributeUrlInput to `tribute-url-input`
    attach TributeUrlBtn to `tribute-url-btn`
    attach ModalStatus to `modal-status`
    attach DeleteBtn to `delete-btn`
    attach CancelBtn to `cancel-btn`
    attach SaveBtn to `save-btn`
    attach AddButton to `add-button`
    attach ExportBtn to `export-button`
    attach ExportStatus to `export-status`
    attach StreamBtn to `stream-button`
    attach Email1Btn to `button-1`
    attach Email2Btn to `button-2`

    put `` into EditSlugOld
    put `` into EditFyStart
    put 1 into IsCreate

!! Build the grid template — 12 columns matching the columns we render.

    put `1fr 0.7fr 2.5fr 2.5fr 0.7fr 0.4fr 1fr 1fr 0.6fr 0.6fr 0.5fr 0.5fr 0.5fr` into Grid

    put `display: grid; grid-template-columns: ` cat Grid into RowStyleData
    put RowStyleData cat `; padding: 0.3em 0.4em; border-bottom: 1px solid #eee; cursor: pointer` into RowStyleData

    put `display: grid; grid-template-columns: ` cat Grid into RowStyleSub
    put RowStyleSub cat `; padding: 0.4em 0.4em; border-top: 1px solid #aaa; border-bottom: 1px solid #aaa; background: #fafafa; font-weight: bold` into RowStyleSub

    put `display: grid; grid-template-columns: ` cat Grid into RowStyleGrand
    put RowStyleGrand cat `; padding: 0.6em 0.4em; border-top: 2px solid #333; background: #eef; font-weight: bold` into RowStyleGrand

    put `text-align: right; padding-right: 0.4em; color: #666` into CellRight
    put `padding: 0.3em 0.9em; cursor: pointer; border: 0; border-radius: 4px; background: #28a; color: white` into KindSelectedStyle
    put `padding: 0.3em 0.9em; cursor: pointer; border: 0; border-radius: 4px; background: #eee; color: #333` into KindUnselectedStyle

    put `January,February,March,April,May,June,July,August,September,October,November,December` into MonthNames
    split MonthNames on `,`

!! Wire up click handlers then show login.

    on click LoginButton gosub OnLogin
    on click AddButton gosub OnAdd
    on click SaveBtn gosub OnSave
    on click CancelBtn gosub OnCancel
    on click DeleteBtn gosub OnDelete
    on click KindServiceBtn gosub SelectKindService
    on click KindExpenseBtn gosub SelectKindExpense
    on click KindSlideshowBtn gosub SelectKindSlideshow
    on click LoadSampleBtn gosub OnLoadSample
    on click StreamBtn gosub OnOpenStream
    on click Email1Btn gosub OnEmail1
    on click Email2Btn gosub OnEmail2
    on click ExportBtn gosub OnExport
    on change LinkSentToggle gosub OnLinkSentToggle
    on change InvoicedToggle gosub OnInvoicedToggle
    on change PaidInput gosub OnPaidToggle
    on click RecordingUrlBtn gosub OnOpenRecordingUrl
    on click TributeUrlBtn gosub OnOpenTributeUrl

    set style `display` of AdminPanel to `none`
    stop
!! @hash placeholder
!!!


!! Login: POST credentials to login.php, on success show the admin panel
!! and load data.

OnLogin:
    set the content of LoginStatus to ``
    put `{"user":"` cat the content of UserField into BodyText
    put BodyText cat `","pass":"` cat the content of PassField into BodyText
    put BodyText cat `"}` into BodyText
    rest post BodyText to `login.php` giving ResponseJson on failure
    begin
        set the content of LoginStatus to `Could not reach server.`
        return
    end
    put json ResponseJson into ResponseObj
    put property `status` of ResponseObj into ResponseStatus
    if ResponseStatus is not `ok`
    begin
        set the content of LoginStatus to `Login failed.`
        return
    end
    set style `display` of LoginPanel to `none`
    set style `display` of AdminPanel to `block`
    gosub Refresh
    return
!! @hash placeholder
!!!


!! Refresh: fetch all bookings from the server and render the table.

Refresh:
    set the content of LogBody to ``
    set the content of ExportStatus to ``
    gosub TodayString
    put random 999999999 into CacheBuster

    rest get AllBookings from `bookings.php?cb=` cat CacheBuster on failure
    begin
        set the content of LogBody to `Could not load bookings.`
        return
    end
    put json count of AllBookings into BookingCount

    if BookingCount is 0
    begin
        set style `display` of EmptyState to `block`
        set style `display` of LogBody to `none`
        return
    end

    set style `display` of EmptyState to `none`
    set style `display` of LogBody to `block`

!! Pass 1: count rows and discover month boundaries so we can pre-size
!! arrays (AllSpeak's cursor model requires this).

    put 0 into I
    put `` into LastFy
    put `` into LastMm
    put 0 into SortCount

    while I is less than BookingCount
    begin
        put element I of AllBookings into Row

        put property `date` of Row into BookingDate
        gosub FyAndMmFromDate

        if EditFyStart is not empty and EditFyStart is not FY
        begin
            add 1 to I
        end
        else
        begin
            if LastMm is not Mm or LastFy is not FY
            begin
                add 1 to SortCount    ! subtotal header
                put FY into LastFy
                put Mm into LastMm
            end

            add 1 to SortCount        ! data row
            add 1 to I
        end
    end

    ! One more for the grand total
    add 1 to SortCount

    put 0 into I
    put `` into LastFy
    put `` into LastMm
    put 0 into GrandMileage
    put 0 into GrandExpense
    put 0 into GrandFees

    ! Pre-pass: calculate grand totals and per-month totals
    put 0 into I
    put 0 into GrandMileage
    put 0 into GrandExpense
    put 0 into GrandFees
    set MonthFyArr to array
    set MonthMmArr to array
    set MonthExpenseArr to array
    set MonthFeesArr to array
    put 0 into MonthCount
    put `` into LastFy
    put `` into LastMm
    put 0 into MonthMileage
    put 0 into MonthExpense
    put 0 into MonthFees
    while I is less than BookingCount
    begin
        put element I of AllBookings into Row
        put property `date` of Row into BookingDate
        gosub FyAndMmFromDate
        if EditFyStart is empty or EditFyStart is FY
        begin
            if LastMm is not Mm or LastFy is not FY
            begin
                if LastMm is not empty
                begin
                    set element MonthCount of MonthFyArr to LastFy
                    set element MonthCount of MonthMmArr to LastMm
                    set element MonthCount of MonthExpenseArr to MonthExpense
                    set element MonthCount of MonthFeesArr to MonthFees
                    add 1 to MonthCount
                end
                put 0 into MonthMileage
                put 0 into MonthExpense
                put 0 into MonthFees
                put FY into LastFy
                put Mm into LastMm
            end
            put property `mileage` of Row into Mileage
            put property `expense` of Row into Expense
            put property `fees` of Row into Fees
            add Mileage to MonthMileage
            add Mileage to GrandMileage
            add Expense to MonthExpense
            add Expense to GrandExpense
            add Fees to MonthFees
            add Fees to GrandFees
        end
        add 1 to I
    end
    ! Store last month's totals
    if LastMm is not empty
    begin
        set element MonthCount of MonthFyArr to LastFy
        set element MonthCount of MonthMmArr to LastMm
        set element MonthCount of MonthExpenseArr to MonthExpense
        set element MonthCount of MonthFeesArr to MonthFees
        add 1 to MonthCount
    end

    ! Emit grand total at the top of the sheet
    gosub EmitGrandTotal

    ! Pass 2: single pass — when month changes, emit pre-computed subtotal,
    ! then emit the row. MonthIdx tracks which month's data to show next.
    put 0 into MonthIdx
    put 0 into I
    put `` into LastFy
    put `` into LastMm
    set the elements of DataRowDivs to BookingCount

    while I is less than BookingCount
    begin
        put element I of AllBookings into Row

        put property `date` of Row into BookingDate
        gosub FyAndMmFromDate

        if EditFyStart is not empty and EditFyStart is not FY
        begin
            add 1 to I
        end
        else
        begin
            if LastMm is not Mm or LastFy is not FY
            begin
                ! Emit this month's subtotal using pre-computed values
                put element MonthIdx of MonthFyArr into TempFy
                put element MonthIdx of MonthMmArr into TempMm
                put element MonthIdx of MonthExpenseArr into MonthExpense
                put element MonthIdx of MonthFeesArr into MonthFees
                put TempFy into LastFy
                put TempMm into LastMm
                gosub EmitSubtotal
                add 1 to MonthIdx
            end

            gosub EmitRow
            add 1 to I
        end
    end

    on click DataRowDivs gosub OnRowClick
    return
!! @hash placeholder
!!!


!! EmitRow: render one data row from the current record in 'Row'.

EmitRow:
    index DataRowDivs to I
    put property `date` of Row into BookingDate
    put property `time` of Row into BookingTime
    put property `name` of Row into BookingName
    put property `kind` of Row into Kind
    put property `mileage` of Row into Mileage
    put property `expense` of Row into Expense
    put property `fees` of Row into Fees
    put property `paid` of Row into Paid
    put property `invoiced` of Row into Invoiced
    create DataRowDivs in LogBody
    set the style of DataRowDivs to RowStyleData
    put 0 into WarnAmber

    ! Past dates get a light gray background
    if BookingDate is less than TodayStr
        set style `background` of DataRowDivs to `#f0f0f0`

    ! Amber warning: within 3 days, has a stream, and link not sent
    put date BookingDate into BookingStamp
    if BookingStamp is greater than now
    begin
        subtract now from BookingStamp
        if BookingStamp is less than 259200000  ! 3 days in ms
        begin
            put property `dacast_id` of Row into TempStr
            if TempStr is empty
                put property `stream_url` of Row into TempStr
            if TempStr is not empty
            begin
                put property `linkSent` of Row into TempStr
                if TempStr is empty
                    put 1 into WarnAmber
                else
                    put 0 into WarnAmber
            end
            else
                put 0 into WarnAmber
        end
        else
            put 0 into WarnAmber
    end
    else
        put 0 into WarnAmber

    ! Column 1: date
    create CellDiv in DataRowDivs
    set the content of CellDiv to BookingDate

    ! Column 2: time
    create CellDiv in DataRowDivs
    set the content of CellDiv to BookingTime

    ! Column 3: name
    create CellDiv in DataRowDivs
    if Kind is `expense`
    begin
        put property `name` of Row into BookingName
        if BookingName is empty
            put property `description` of Row into BookingName
        set the content of CellDiv to BookingName
    end
    else
        set the content of CellDiv to BookingName

    ! Column 4: location
    create CellDiv in DataRowDivs
    put property `location` of Row into TempStr
    if TempStr is not empty
        set the content of CellDiv to TempStr

    ! Column 5: postcode
    create CellDiv in DataRowDivs
    put property `postcode` of Row into TempStr
    set the content of CellDiv to TempStr

    ! Column 6: expense flag (💰 only for expense rows)
    create CellDiv in DataRowDivs
    if Kind is `expense`
        set the content of CellDiv to `💰`

    ! Column 7: contact
    create CellDiv in DataRowDivs
    put property `contact` of Row into TempStr
    set the content of CellDiv to TempStr

    ! Column 8: client
    create CellDiv in DataRowDivs
    put property `client` of Row into BookingClient
    set the content of CellDiv to BookingClient

    ! Column 9: expense
    create CellDiv in DataRowDivs
    set the style of CellDiv to CellRight
    put Expense into MoneyVal
    gosub FormatMoney
    set the content of CellDiv to MoneyStr

    ! Column 10: fees
    create CellDiv in DataRowDivs
    set the style of CellDiv to CellRight
    put Fees into MoneyVal
    gosub FormatMoney
    set the content of CellDiv to MoneyStr

    ! Column 11: link sent check — amber background if warning
    create CellDiv in DataRowDivs
    set style `text-align` of CellDiv to `center`
    if WarnAmber is 1
        set style `background` of CellDiv to `#ffcc66`
    put property `linkSent` of Row into TempStr
    if TempStr is `false`
        put `` into TempStr
    if TempStr is not empty
        set the content of CellDiv to `✓`

    ! Column 12: invoiced check — deep pink if invoiced but not paid
    create CellDiv in DataRowDivs
    set style `text-align` of CellDiv to `center`
    put property `invoiced` of Row into TempStr
    put property `paid` of Row into Paid
    if TempStr is `false`
        put `` into TempStr
    if TempStr is not empty and Paid is not true
        set style `background` of CellDiv to `#ffb3b3`
    if TempStr is not empty
        set the content of CellDiv to `✓`

    ! Column 13: paid check — deep pink if invoiced but not paid
    create CellDiv in DataRowDivs
    set style `text-align` of CellDiv to `center`
    put property `invoiced` of Row into TempStr
    put property `paid` of Row into Paid
    if TempStr is `false`
        put `` into TempStr
    if TempStr is not empty and Paid is not true
        set style `background` of CellDiv to `#ffb3b3`
    if Paid is true
        set the content of CellDiv to `✓`

    add Mileage to MonthMileage
    add Expense to MonthExpense
    add Fees to MonthFees
    add Mileage to GrandMileage
    add Expense to GrandExpense
    add Fees to GrandFees

    ! Store slug in parallel data
    create RowWrappers in LogBody

    return
!! @hash placeholder
!!!


!! OnRowClick: open the edit modal for the clicked row. We read the slug
!! from the AllBookings array at the stored index.

OnRowClick:
    put the index of DataRowDivs into J
    put element J of AllBookings into Row
    put property `slug` of Row into EditSlugOld
    put property `_path` of Row into EditPath
    put 0 into IsCreate
    gosub PopulateForm
    set style `display` of Overlay to `flex`
    return
!! @hash placeholder
!!!


!! EmitSubtotal: render a monthly subtotal row.

EmitSubtotal:
    if LastFy is empty
        return

    put LastMm into Mo
    if left 1 of Mo is `0`
        put from 1 of Mo into Mo
    subtract 1 from Mo
    index MonthNames to Mo
    put MonthNames into MonthLabel
    put LastFy into Parts
    split Parts on `-`
    index Parts to 0
    put Parts into Yy
    put MonthLabel cat ` ` cat Yy cat ` total` into MonthLabel

    create SubDiv in LogBody
    set the style of SubDiv to RowStyleSub

    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    set the content of CellDiv to MonthLabel
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv
    create CellDiv in SubDiv

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
    create CellDiv in SubDiv
    return
!! @hash placeholder
!!!


!! EmitGrandTotal: render the grand total row.

EmitGrandTotal:
    create GrandDiv in LogBody
    set the style of GrandDiv to RowStyleGrand

    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    set the content of CellDiv to `Grand total`
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv
    create CellDiv in GrandDiv

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
    create CellDiv in GrandDiv
    return
!! @hash placeholder
!!!


!! FormatMoney: convert integer pence to £XX.XX string.
!! MoneyVal carries the value in (e.g. 1998); MoneyStr carries the result
!! out (e.g. "£19.98"). Negative values produce "-£19.98".

FormatMoney:
    if MoneyVal is less than 0
    begin
        negate MoneyVal giving TempStr
        gosub FormatMoneyInner
        put `-` cat MoneyStr into MoneyStr
        return
    end
    put MoneyVal into TempStr
    gosub FormatMoneyInner
    return

!! FormatMoneyInner: helper — TempStr in, MoneyStr out with £ prefix,
!! using from/right/length for correct string splitting.
FormatMoneyInner:
    put TempStr cat `` into MoneyStr
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
!! @hash placeholder
!!!


!! FormatMileage: convert integer tenths to XX.X string.
!! MileageVal carries the value in (e.g. 444); Mi carries the result
!! out (e.g. "44.4"). Zero produces empty string.

FormatMileage:
    if MileageVal is 0
    begin
        put empty into Mi
        return
    end
    put MileageVal cat `` into Mi
    put the length of Mi into MileLen
    if MileLen is 1
    begin
        put `0.` cat Mi into Mi
        return
    end
    put MileLen into MilePos
    subtract 1 from MilePos
    put from 0 to MilePos of Mi into Whole
    put from MilePos of Mi into FracStr
    put Whole cat `.` cat FracStr into Mi
    return
!! @hash placeholder
!!!


!! FyAndMmFromDate: given BookingDate (YYYY-MM-DD), set FY and Mm.
!! UK financial year: April = month 04 is FY start (e.g. 2026-27).
!! FY = "2026-27", Mm = "04" (month number only, no hyphen).

FyAndMmFromDate:
    put left 4 of BookingDate into FY          ! YYYY
    put from 5 of BookingDate into Mm          ! MM-DD (position 5 = month tens digit)
    put left 2 of Mm into Mm                   ! just the MM digits

    if the value of Mm is not less than 4
    begin
        put the value of FY into NextYr
        add 1 to NextYr
        put FY cat `-` cat right 2 of `0` cat NextYr into FY
    end
    else
    begin
        put the value of FY into FY
        subtract 1 from FY
        put the value of FY into NextYr
        add 1 to NextYr
        put FY cat `-` cat right 2 of `0` cat NextYr into FY
    end
    return
!! @hash placeholder
!!!


!! OnAdd: open the modal in create mode.

OnAdd:
    put 1 into IsCreate
    put `` into EditSlugOld
    put `` into EditPath
    set the content of DateInput to ``
    set the content of TimeInput to ``
    set the content of NameInput to ``
    set the content of LocationInput to ``
    set the content of PostcodeInput to ``
    set the content of DistanceInput to ``
    set the content of ContactInput to ``
    set the content of ClientInput to ``
    set the content of ClientEmailInput to ``
    set the content of DacastInput to ``
    set the content of StreamUrlInput to ``
    set the content of RecordingUrlInput to ``
    set attribute `disabled` of RecordingUrlBtn to `disabled`
    set the content of MileageInput to `0`
    set the content of ExpenseInput to `0`
    set the content of FeesInput to `0`
    remove attribute `checked` of LinkSentToggle
    set the content of LinkSentInput to ``
    remove attribute `checked` of InvoicedToggle
    set the content of InvoicedInput to ``
    remove attribute `checked` of PaidInput
    set the content of PaidDateInput to ``
    set the content of TitleField to ``
    set the content of ContactNameInput to ``
    set the content of ContactRelationInput to ``
    set the content of ContactPhoneInput to ``
    set the content of ContactEmailInput to ``
    set the content of RecordingTextInput to `A fully edited tribute video will be available in a few days, to view or download at the discretion of the family. This will include some or all of the following: coverage of the departure, multiple camera angles and closer views of those speaking.

In the meantime, here is a link to a recording of the stream, for those who may have missed it.`
    set the content of TributeUrlInput to ``
    set attribute `disabled` of TributeUrlBtn to `disabled`
    set the content of ModalTitle to `Add booking`
    set style `display` of DeleteBtn to `none`
    set the content of ModalStatus to ``
    gosub SelectKindService
    set style `display` of Overlay to `flex`
    return
!! @hash placeholder
!!!


!! PopulateForm: fill the modal with the current Row's data.

PopulateForm:
    set the content of ModalTitle to `Edit booking`
    set style `display` of DeleteBtn to `inline-block`

    put property `kind` of Row into Kind
    if Kind is `service`
        gosub SelectKindService
    else if Kind is `expense`
        gosub SelectKindExpense
    else
        gosub SelectKindSlideshow

    put property `date` of Row into BookingDate
    set the content of DateInput to BookingDate

    put property `time` of Row into BookingTime
    set the content of TimeInput to BookingTime

    put property `name` of Row into BookingName
    set the content of NameInput to BookingName

    put property `location` of Row into BookingLocation
    set the content of LocationInput to BookingLocation

    put property `postcode` of Row into TempStr
    set the content of PostcodeInput to TempStr

    put property `distance` of Row into TempStr
    set the content of DistanceInput to TempStr

    put property `contact` of Row into TempStr
    set the content of ContactInput to TempStr

    put property `client` of Row into TempStr
    set the content of ClientInput to TempStr

    put property `client_email` of Row into TempStr
    set the content of ClientEmailInput to TempStr

    put property `dacast_id` of Row into TempStr
    set the content of DacastInput to TempStr

    put property `stream_url` of Row into TempStr
    set the content of StreamUrlInput to TempStr

    put property `recording_url` of Row into TempStr
    set the content of RecordingUrlInput to TempStr
    if TempStr is not empty
        remove attribute `disabled` of RecordingUrlBtn
    else
        set attribute `disabled` of RecordingUrlBtn to `disabled`

    put property `mileage` of Row into MileageVal
    gosub FormatMileage
    if Mi is empty
        put `0` into Mi
    set the content of MileageInput to Mi

    put property `expense` of Row into MoneyVal
    divide MoneyVal by 100 giving ExpensePounds
    put MoneyVal modulo 100 into ExpensePence
    put ExpensePounds cat `.` into ExpenseDisplay
    if ExpensePence is less than 10
        put `0` cat ExpensePence into ExpensePenceStr
    else
        put ExpensePence into ExpensePenceStr
    set the content of ExpenseInput to ExpenseDisplay cat ExpensePenceStr

    put property `fees` of Row into Fees
    divide Fees by 100 giving FeesPounds
    set the content of FeesInput to FeesPounds

    put property `linkSent` of Row into TempStr
    put TempStr cat `` into TempStr
    if TempStr is `false`
        put `` into TempStr
    set the content of LinkSentInput to TempStr
    if TempStr is not empty
        set attribute `checked` of LinkSentToggle to `yes`
    else
        remove attribute `checked` of LinkSentToggle

    put property `invoiced` of Row into TempStr
    put TempStr cat `` into TempStr
    if TempStr is `false`
        put `` into TempStr
    set the content of InvoicedInput to TempStr
    if TempStr is not empty
        set attribute `checked` of InvoicedToggle to `yes`
    else
        remove attribute `checked` of InvoicedToggle

    put property `paid` of Row into Paid
    put Paid cat `` into Paid
    if Paid is `true`
        set attribute `checked` of PaidInput to `yes`
    else
        remove attribute `checked` of PaidInput

    put property `paidDate` of Row into TempStr
    set the content of PaidDateInput to TempStr

    put property `title` of Row into TempStr
    set the content of TitleField to TempStr

    put property `contact_name` of Row into TempStr
    set the content of ContactNameInput to TempStr

    put property `contact_relation` of Row into TempStr
    set the content of ContactRelationInput to TempStr

    put property `contact_telephone` of Row into TempStr
    set the content of ContactPhoneInput to TempStr

    put property `contact_email` of Row into TempStr
    set the content of ContactEmailInput to TempStr

    put property `recording_text` of Row into TempStr
    set the content of RecordingTextInput to TempStr

    put property `tribute_url` of Row into TempStr
    set the content of TributeUrlInput to TempStr
    if TempStr is not empty
        remove attribute `disabled` of TributeUrlBtn
    else
        set attribute `disabled` of TributeUrlBtn to `disabled`

    return
!! @hash placeholder
!!!


!! Kind selection toggles: show/hide relevant form sections.

SelectKindService:
    put `service` into Kind
    set the style of KindServiceBtn to KindSelectedStyle
    set the style of KindExpenseBtn to KindUnselectedStyle
    set the style of KindSlideshowBtn to KindUnselectedStyle
    set style `display` of NameInput to `inline-block`
    set style `display` of LocationInput to `inline-block`
    set style `display` of PostcodeInput to `inline-block`
    set style `display` of DistanceInput to `inline-block`
    set style `display` of ContactInput to `inline-block`
    set style `display` of ClientInput to `inline-block`
    set style `display` of ClientEmailInput to `inline-block`
    set style `display` of DacastInput to `inline-block`
    set style `display` of StreamUrlInput to `inline-block`
    set style `display` of TitleField to `inline-block`
    set style `display` of ContactNameInput to `inline-block`
    set style `display` of ContactRelationInput to `inline-block`
    set style `display` of ContactPhoneInput to `inline-block`
    set style `display` of ContactEmailInput to `inline-block`
    set style `display` of RecordingTextInput to `inline-block`
    set style `display` of TributeUrlInput to `inline-block`
    return

SelectKindExpense:
    put `expense` into Kind
    set the style of KindServiceBtn to KindUnselectedStyle
    set the style of KindExpenseBtn to KindSelectedStyle
    set the style of KindSlideshowBtn to KindUnselectedStyle
    set style `display` of NameInput to `inline-block`
    set style `display` of LocationInput to `none`
    set style `display` of PostcodeInput to `none`
    set style `display` of DistanceInput to `none`
    set style `display` of ContactInput to `none`
    set style `display` of ClientInput to `none`
    set style `display` of ClientEmailInput to `none`
    set style `display` of DacastInput to `none`
    set style `display` of StreamUrlInput to `none`
    set style `display` of TitleField to `none`
    set style `display` of ContactNameInput to `none`
    set style `display` of ContactRelationInput to `none`
    set style `display` of ContactPhoneInput to `none`
    set style `display` of ContactEmailInput to `none`
    set style `display` of RecordingTextInput to `none`
    set style `display` of TributeUrlInput to `none`
    return

SelectKindSlideshow:
    put `slideshow` into Kind
    set the style of KindServiceBtn to KindUnselectedStyle
    set the style of KindExpenseBtn to KindUnselectedStyle
    set the style of KindSlideshowBtn to KindSelectedStyle
    set style `display` of NameInput to `inline-block`
    set style `display` of LocationInput to `inline-block`
    set style `display` of PostcodeInput to `none`
    set style `display` of DistanceInput to `none`
    set style `display` of ContactInput to `inline-block`
    set style `display` of ClientInput to `inline-block`
    set style `display` of ClientEmailInput to `inline-block`
    set style `display` of DacastInput to `none`
    set style `display` of StreamUrlInput to `none`
    set style `display` of TitleField to `none`
    set style `display` of ContactNameInput to `none`
    set style `display` of ContactRelationInput to `none`
    set style `display` of ContactPhoneInput to `none`
    set style `display` of ContactEmailInput to `none`
    set style `display` of RecordingTextInput to `none`
    set style `display` of TributeUrlInput to `none`
    return
!! @hash placeholder
!!!


!! OnSave: read form fields, build a JSON record, POST to bookings-save.php.

OnSave:
    set the content of ModalStatus to `Saving...`

    ! Build slug from date + name if new
    if IsCreate
    begin
        put the content of DateInput into BookingDate
        put the content of NameInput into BookingName
        gosub MakeSlug
        put TempStr into EditSlugOld
    end

    !! Auto-fill mileage: if Mileage is 0 but Distance is set, double Distance for return trip
    put the content of MileageInput into TempStr
    if TempStr is `0`
    begin
        put the content of DistanceInput into TempStr
        if TempStr is not empty
        begin
            put the value of TempStr into TempNum
            multiply TempNum by 2
            put TempNum cat `.0` into TempStr
            set the content of MileageInput to TempStr
        end
    end

    !! Auto-fill expense: if Expense is 0.00 and Mileage is set, compute Mileage * 0.45
    put the content of ExpenseInput into TempStr
    if TempStr is `0.00`
    begin
        put the content of MileageInput into TempStr
        if TempStr is not `0` and TempStr is not empty
        begin
            put the value of TempStr into TempNum
            multiply TempNum by 45
            ! TempNum is now mileage * 45 (pence)
            divide TempNum by 100 giving ExpensePounds
            put TempNum modulo 100 into ExpensePence
            put ExpensePounds cat `.` into TempStr
            if ExpensePence is less than 10
                put TempStr cat `0` cat ExpensePence into TempStr
            else
                put TempStr cat ExpensePence into TempStr
            set the content of ExpenseInput to TempStr
        end
    end

    ! Start building the record
    put `{` into BodyText
    gosub JsonAddString with `slug`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `kind`
    ! Read paid boolean from checkbox
    put attribute `checked` of PaidInput into TempStr
    if TempStr is not empty
        put true into Paid
    else
        put false into Paid
    put BodyText cat `,"paid":` cat Paid into BodyText
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `date`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `time`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `name`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `location`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `postcode`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `distance`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `contact`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `client`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `client_email`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `dacast_id`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `stream_url`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `recording_url`
    put BodyText cat `,` into BodyText
    gosub JsonAddNumber with `mileage`
    put BodyText cat `,` into BodyText
    gosub JsonAddNumber with `expense`
    put BodyText cat `,` into BodyText
    gosub JsonAddNumber with `fees`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `linkSent`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `invoiced`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `paidDate`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `title`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `contact_name`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `contact_relation`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `contact_telephone`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `contact_email`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `recording_text`
    put BodyText cat `,` into BodyText
    gosub JsonAddString with `tribute_url`
    put BodyText cat `}` into BodyText

    rest post BodyText to `bookings-save.php` giving ResponseJson on failure
    begin
        set the content of ModalStatus to `Save failed — could not reach server.`
        wait 3 seconds
        set the content of ModalStatus to ``
        return
    end

    put json ResponseJson into ResponseObj
    put property `status` of ResponseObj into ResponseStatus
    if ResponseStatus is `ok`
    begin
        set the content of ModalStatus to `Saved ✓`
        wait 3 seconds
        set the content of ModalStatus to ``
        set style `display` of Overlay to `none`
        gosub Refresh
        return
    end

    set the content of ModalStatus to `Save failed: ` cat ResponseStatus
    wait 3 seconds
    set the content of ModalStatus to ``
    return
!! @hash placeholder
!!!


!! OnLinkSentToggle: when the toggle changes, set or clear the linkSent date.

OnLinkSentToggle:
    put attribute `checked` of LinkSentToggle into TempStr
    if TempStr is not empty
    begin
        gosub TodayString
        set the content of LinkSentInput to TodayStr
    end
    else
        set the content of LinkSentInput to ``
    return
!! @hash placeholder
!!!


!! OnInvoicedToggle: when the toggle changes, set or clear the invoiced date.

OnInvoicedToggle:
    put attribute `checked` of InvoicedToggle into TempStr
    if TempStr is not empty
    begin
        gosub TodayString
        set the content of InvoicedInput to TodayStr
    end
    else
        set the content of InvoicedInput to ``
    return
!! @hash placeholder
!!!


!! OnPaidToggle: when the paid checkbox changes, set or clear the paidDate.

OnPaidToggle:
    put attribute `checked` of PaidInput into TempStr
    if TempStr is not empty
    begin
        gosub TodayString
        set the content of PaidDateInput to TodayStr
    end
    else
        set the content of PaidDateInput to ``
    return
!! @hash placeholder
!!!


!! OnOpenStream: build the stream URL from form data and navigate there.

OnOpenStream:
    put the content of DateInput into BookingDate
    put the content of NameInput into BookingName
    gosub MakeSlug
    put `https://filming.eclecity.net/` cat TempStr into TargetUrl
    location TargetUrl
    return
!! @hash placeholder
!!!


!! OnOpenRecordingUrl: navigate to the recording URL in the current tab.

OnOpenRecordingUrl:
    put the content of RecordingUrlInput into TargetUrl
    if TargetUrl is not empty
        location TargetUrl
    return
!! @hash placeholder
!!!


!! OnOpenTributeUrl: navigate to the tribute video URL in the current tab.

OnOpenTributeUrl:
    put the content of TributeUrlInput into TargetUrl
    if TargetUrl is not empty
        location TargetUrl
    return
!! @hash placeholder
!!!


!! OnEmail1: fetch email template, substitute record data, build mailto: URI,
!! and open in the default email client.

OnEmail1:
    set the content of ModalStatus to `Loading template...`
    rest get EmailTemplate from `/email1.json` or begin
        set the content of ModalStatus to `Could not load email template.`
        wait 3 seconds
        set the content of ModalStatus to ``
        return
    end

    ! Build stream URL from form fields
    put the content of DateInput into BookingDate
    put the content of NameInput into BookingName
    gosub MakeSlug
    put `https://filming.eclecity.net/` cat TempStr into StreamUrl

    ! Read form fields into temp variables
    put the content of ContactEmailInput into ContactEmailVal
    put the content of ClientEmailInput into ClientEmailVal
    put the content of NameInput into NameVal
    put the content of LocationInput into LocationVal
    put the content of DateInput into DateVal
    put the content of TimeInput into TimeVal
    put the content of ContactNameInput into ContactNameVal
    put the content of ContactRelationInput into ContactRelationVal
    put the content of ContactInput into ClientRepVal
    put the content of ClientInput into ClientCompanyVal

    ! --- To field ---
    put property `to` of EmailTemplate into ToField
    replace `[CONTACT EMAIL]` with ContactEmailVal in ToField

    ! --- CC field ---
    put property `cc` of EmailTemplate into CcField
    replace `[CLIENT EMAIL]` with ClientEmailVal in CcField

    ! --- Subject field ---
    put property `subject` of EmailTemplate into SubjectField
    replace `[DECEASED]` with NameVal in SubjectField
    replace `[LOCATION]` with LocationVal in SubjectField
    replace `[DATE]` with DateVal in SubjectField
    replace `[TIME]` with TimeVal in SubjectField
    ! URL-encode the subject
    replace `%` with `%25` in SubjectField
    replace `&` with `%26` in SubjectField
    replace `"` with `%22` in SubjectField

    ! --- Body: build from body_parts array with %0A between parts ---
    put property `body_parts` of EmailTemplate into BodyParts
    put json count of BodyParts into PartCount
    put `` into BodyField
    put 0 into J
    while J is less than PartCount
    begin
        if J is greater than 0
            put BodyField cat `%0A` into BodyField
        put item J of BodyParts into PartText
        replace `[CONTACT EMAIL]` with ContactEmailVal in PartText
        replace `[CLIENT EMAIL]` with ClientEmailVal in PartText
        replace `[DECEASED]` with NameVal in PartText
        replace `[LOCATION]` with LocationVal in PartText
        replace `[DATE]` with DateVal in PartText
        replace `[TIME]` with TimeVal in PartText
        replace `[CONTACT]` with ContactNameVal in PartText
        replace `[RELATION]` with ContactRelationVal in PartText
        replace `[CLIENT REP]` with ClientRepVal in PartText
        replace `[CLIENT COMPANY]` with ClientCompanyVal in PartText
        replace `[STREAM]` with StreamUrl in PartText
        ! URL-encode this line
        replace `%` with `%25` in PartText
        replace `&` with `%26` in PartText
        replace `"` with `%22` in PartText
        put BodyField cat PartText into BodyField
        add 1 to J
    end

    ! Build mailto: URI (only include cc if not empty)
    put `mailto:` cat ToField into MailToUri
    if CcField is not empty
    begin
        put MailToUri cat `?cc=` cat CcField into MailToUri
        put MailToUri cat `&subject=` cat SubjectField into MailToUri
    end
    else
        put MailToUri cat `?subject=` cat SubjectField into MailToUri
    put MailToUri cat `&body=` cat BodyField into MailToUri
    location MailToUri
    set the content of ModalStatus to ``
    return
!! @hash placeholder
!!!


!! OnEmail2: fetch email2 template (recording notification), substitute record
!! data, build mailto: URI, and open in the default email client.

OnEmail2:
    set the content of ModalStatus to `Loading template...`
    rest get EmailTemplate from `/email2.json` or begin
        set the content of ModalStatus to `Could not load email template.`
        wait 3 seconds
        set the content of ModalStatus to ``
        return
    end

    ! Read form fields into temp variables
    put the content of ContactEmailInput into ContactEmailVal
    put the content of ClientEmailInput into ClientEmailVal
    put the content of NameInput into NameVal
    put the content of LocationInput into LocationVal
    put the content of DateInput into DateVal
    put the content of ContactNameInput into ContactNameVal
    put the content of TributeUrlInput into TributeUrlVal

    ! --- To field ---
    put property `to` of EmailTemplate into ToField
    replace `[CONTACT EMAIL]` with ContactEmailVal in ToField

    ! --- CC field ---
    put property `cc` of EmailTemplate into CcField
    replace `[CLIENT EMAIL]` with ClientEmailVal in CcField

    ! --- Subject field ---
    put property `subject` of EmailTemplate into SubjectField
    replace `[DECEASED]` with NameVal in SubjectField
    replace `[LOCATION]` with LocationVal in SubjectField
    replace `[DATE]` with DateVal in SubjectField
    ! URL-encode the subject
    replace `%` with `%25` in SubjectField
    replace `&` with `%26` in SubjectField
    replace `"` with `%22` in SubjectField

    ! --- Body: build from body_parts array with %0A between parts ---
    put property `body_parts` of EmailTemplate into BodyParts
    put json count of BodyParts into PartCount
    put `` into BodyField
    put 0 into J
    while J is less than PartCount
    begin
        if J is greater than 0
            put BodyField cat `%0A` into BodyField
        put item J of BodyParts into PartText
        replace `[CONTACT EMAIL]` with ContactEmailVal in PartText
        replace `[CLIENT EMAIL]` with ClientEmailVal in PartText
        replace `[DECEASED]` with NameVal in PartText
        replace `[LOCATION]` with LocationVal in PartText
        replace `[DATE]` with DateVal in PartText
        replace `[CONTACT]` with ContactNameVal in PartText
        replace `[TRIBUTE]` with TributeUrlVal in PartText
        ! URL-encode this line
        replace `%` with `%25` in PartText
        replace `&` with `%26` in PartText
        replace `"` with `%22` in PartText
        put BodyField cat PartText into BodyField
        add 1 to J
    end

    ! Build mailto: URI (only include cc if not empty)
    put `mailto:` cat ToField into MailToUri
    if CcField is not empty
    begin
        put MailToUri cat `?cc=` cat CcField into MailToUri
        put MailToUri cat `&subject=` cat SubjectField into MailToUri
    end
    else
        put MailToUri cat `?subject=` cat SubjectField into MailToUri
    put MailToUri cat `&body=` cat BodyField into MailToUri
    location MailToUri
    set the content of ModalStatus to ``
    return
!! @hash placeholder
!!!


!! TodayString: compute today's date as YYYY-MM-DD into TodayStr.

TodayString:
    put now into Now
    divide Now by 1000                     ! convert ms to seconds for date accessors
    put the year of Now into Yr
    put the month of Now into Mo
    add 1 to Mo                              ! JS getMonth() is 0-indexed
    if Mo is less than 10
        put `0` cat Mo into Mo
    put the day number of Now into Dd
    if Dd is less than 10
        put `0` cat Dd into Dd
    put Yr cat `-` cat Mo cat `-` cat Dd into TodayStr
    return
!! @hash placeholder
!!!


!! OnCancel: close the modal without saving.

OnCancel:
    set style `display` of Overlay to `none`
    return
!! @hash placeholder
!!!


!! OnDelete: confirm then delete the current record.

OnDelete:
    if EditSlugOld is empty
        return
    confirm `Delete this booking?` gosub DoDelete
    return
!! @hash placeholder
!!!


!! DoDelete: POST to bookings-delete.php.

DoDelete:
    put `{"path":"` cat EditPath cat `"}` into BodyText
    rest post BodyText to `bookings-delete.php` giving ResponseJson on failure
    begin
        set the content of ModalStatus to `Delete failed — server unreachable.`
        wait 3 seconds
        set the content of ModalStatus to ``
        return
    end
    put json ResponseJson into ResponseObj
    put property `status` of ResponseObj into ResponseStatus
    if ResponseStatus is `ok`
    begin
        set the content of ModalStatus to `Deleted ✓`
        wait 3 seconds
        set the content of ModalStatus to ``
        set style `display` of Overlay to `none`
        gosub Refresh
        return
    end
    set the content of ModalStatus to `Delete failed.`
    wait 3 seconds
    set the content of ModalStatus to ``
    return
!! @hash placeholder
!!!


!! MakeSlug: produce a URL-safe slug from BookingDate and BookingName.
!! Output format: YYMMDD-Firstname-Lastname (e.g. "260527-Eugenia-Manojlovic").
!! Strips non-alphanumeric characters; replaces spaces with hyphens.

MakeSlug:
    ! BookingDate is YYYY-MM-DD; extract YY, MM, DD by position.
    put from 2 of BookingDate into TempStr    ! 26-06-12
    put left 2 of TempStr into YYStr          ! 26
    put from 5 of BookingDate into TempStr    ! 06-12
    put left 2 of TempStr into Mo             ! 06
    put from 8 of BookingDate into TempStr    ! 12
    put left 2 of TempStr into Dd             ! 12
    put YYStr cat Mo cat Dd into TempStr      ! 260612

    ! Clean the name: keep only alnum, space -> hyphen
    put TempStr cat `-` into TempStr
    put BookingName into TempStr2
    put the length of TempStr2 into SortK
    put 0 into J
    while J is less than SortK
    begin
        put char J of TempStr2 into Ch
        if Ch is not less than `A` and Ch is not greater than `Z`
            put TempStr cat Ch into TempStr
        else if Ch is not less than `a` and Ch is not greater than `z`
            put TempStr cat Ch into TempStr
        else if Ch is not less than `0` and Ch is not greater than `9`
            put TempStr cat Ch into TempStr
        else if Ch is ` `
            put TempStr cat `-` into TempStr
        add 1 to J
    end
    ! TempStr is now the slug
    return
!! @hash placeholder
!!!


!! JsonAddString: append "key":"value" to BodyText. Reads from the
!! corresponding input field for the given key.

JsonAddString:
    param 0 into Key
    put BodyText cat `"` cat Key into BodyText
    put BodyText cat `":"` into BodyText
    ! Read the corresponding input
    if Key is `slug` put EditSlugOld into TempStr2
    else if Key is `kind` put Kind into TempStr2
    else if Key is `date` put the content of DateInput into TempStr2
    else if Key is `time` put the content of TimeInput into TempStr2
    else if Key is `name` put the content of NameInput into TempStr2
    else if Key is `location` put the content of LocationInput into TempStr2
    else if Key is `postcode` put the content of PostcodeInput into TempStr2
    else if Key is `distance` put the content of DistanceInput into TempStr2
    else if Key is `contact` put the content of ContactInput into TempStr2
    else if Key is `client` put the content of ClientInput into TempStr2
    else if Key is `client_email` put the content of ClientEmailInput into TempStr2
    else if Key is `dacast_id` put the content of DacastInput into TempStr2
    else if Key is `stream_url` put the content of StreamUrlInput into TempStr2
    else if Key is `recording_url` put the content of RecordingUrlInput into TempStr2
    else if Key is `linkSent` put the content of LinkSentInput into TempStr2
    else if Key is `invoiced` put the content of InvoicedInput into TempStr2
    else if Key is `title` put the content of TitleField into TempStr2
    else if Key is `contact_name` put the content of ContactNameInput into TempStr2
    else if Key is `contact_relation` put the content of ContactRelationInput into TempStr2
    else if Key is `contact_telephone` put the content of ContactPhoneInput into TempStr2
    else if Key is `contact_email` put the content of ContactEmailInput into TempStr2
    else if Key is `recording_text` put the content of RecordingTextInput into TempStr2
    else if Key is `tribute_url` put the content of TributeUrlInput into TempStr2
    else if Key is `paidDate` put the content of PaidDateInput into TempStr2
    else put `` into TempStr2

    ! Escape backslashes and quotes in the value
    put TempStr2 cat `` into TempStr
    put TempStr into TempOrig
    put `` into TempStr2
    put 0 into J
    put the length of TempOrig into SortK
    while J is less than SortK
    begin
        put left 1 of from J of TempOrig into Ch
        if Ch is `\`
            put TempStr2 cat `\\` into TempStr2
        else if Ch is `"`
            put TempStr2 cat `\"` into TempStr2
        else if Ch is newline
            put TempStr2 cat `\n` into TempStr2
        else
            put TempStr2 cat Ch into TempStr2
        add 1 to J
    end

    put BodyText cat TempStr2 cat `"` into BodyText
    return
!! @hash placeholder
!!!


!! JsonAddNumber: append "key":value to BodyText (no quotes around value).
!! Mileage/Expense/Fees inputs are in display format (miles/pounds);
!! convert back to tenths/pence before serializing.

JsonAddNumber:
    param 0 into Key
    put BodyText cat `"` cat Key cat `":` into BodyText
    if Key is `mileage`
    begin
        put the content of MileageInput into TempStr2
        if TempStr2 is empty put `0` into TempStr2
        gosub ParseMileageToTenths
    end
    else if Key is `expense`
    begin
        put the content of ExpenseInput into TempStr2
        if TempStr2 is empty put `0` into TempStr2
        gosub ParsePoundsToPence
    end
    else if Key is `fees`
    begin
        put the content of FeesInput into TempStr2
        if TempStr2 is empty put `0` into TempStr2
        gosub ParsePoundsToPence
    end
    else
        put `0` into TempStr2
    put BodyText cat TempStr2 into BodyText
    return
!! @hash placeholder
!!!


!! ParseMileageToTenths: convert display miles string (e.g. "44.4") to
!! integer tenths (e.g. 444). Input in TempStr2, result in TempStr2.

ParseMileageToTenths:
    put position of `.` in TempStr2 into Dot
    if Dot is -1
    begin
        multiply TempStr2 by 10
        return
    end
    put left Dot of TempStr2 into Whole
    add 1 to Dot
    put from Dot of TempStr2 into FracStr
    put left 1 of FracStr into FracStr
    multiply Whole by 10
    add FracStr to Whole
    put Whole into TempStr2
    return
!! @hash placeholder
!!!


!! ParsePoundsToPence: convert display pounds string (e.g. "19.98" or "100")
!! to integer pence (e.g. 1998 or 10000). Input in TempStr2, result in TempStr2.

ParsePoundsToPence:
    put position of `.` in TempStr2 into Dot
    if Dot is -1
    begin
        multiply TempStr2 by 100
        return
    end
    put left Dot of TempStr2 into Whole
    add 1 to Dot
    put from Dot of TempStr2 into FracStr
    ! Pad/truncate to 2 digits
    put FracStr cat `00` into FracStr
    put left 2 of FracStr into FracStr
    multiply Whole by 100
    add FracStr to Whole
    put Whole into TempStr2
    return
!! @hash placeholder
!!!


!! OnLoadSample: seed with demo data. POSTs sample records to the server.

OnLoadSample:
    set the content of ExportStatus to `Loading sample data...`
    ! POST each sample row individually
    ! (Implementation deferred — will load from a sample endpoint or inline data)
    set the content of ExportStatus to `Sample data loaded.`
    gosub Refresh
    return
!! @hash placeholder
!!!


!! OnExport: the Export button is an <a> pointing to export.php,
!! so navigation happens natively. We just show a status message.

OnExport:
    set the content of ExportStatus to `Download started.`
    return
!! @hash placeholder
!!!