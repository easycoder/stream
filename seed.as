!   seed.as
!   One-shot CSV → monthly JSON seed importer for the account project.
!
!   Reads account.csv, parses each row, classifies it as `service` or `expense`
!   (skipping totals and placeholders), normalises money to integer pence and
!   mileage to integer tenths-of-a-mile, computes the UK financial year from
!   the row's date, and writes each row to data/<FY>/<MM>.json using the
!   `append to json file` primitive.
!
!   Usage:  allspeak seed.as
!   Re-run: delete the data/ directory first.
!
!   Kept in the public repo as a reference example of converting an existing
!   spreadsheet to AllSpeak's monthly-JSON store. The original account.csv
!   it consumed is not included — adapt the parsing rules in `Classify` and
!   the column layout to match your own spreadsheet.

    script Seed

!! Declare every variable the script uses up front, grouped by purpose.
!!
!! AllSpeak requires declarations before use, including scratch counters
!! inside loops. Keeping them all here means the body code reads as plain
!! prose with no setup noise.

    variable BaseDir
    variable Csv
    variable NumLines
    variable LineIndex
    variable Line
    variable Fields
    variable LineLen
    variable Pos
    variable Next
    variable Peek
    variable FieldIndex
    variable Field
    variable Ch
    variable Ch2
    variable InQuotes
    variable Kind
    variable Seq
    variable RawDate
    variable Item
    variable Iso
    variable Fy
    variable Mm
    variable Day
    variable Month
    variable Year
    variable StartYear
    variable EndYear
    variable YearLen
    variable EndStr
    variable EndTail
    variable Parts
    variable Pence
    variable Tenths
    variable Whole
    variable Cents
    variable Stripped
    variable Money
    variable TargetPath
    variable FyDir
    variable SeenFys
    variable ServicesAdded
    variable ExpensesAdded
    variable Skipped

    dictionary Row
!! @hash d46f8712
!!!

!! Refuse to overwrite an existing data store.
!!
!! The CSV is use-and-dispose, so after a successful first import the user
!! works in the GUI. Re-running would `append` rows on top of edited data,
!! which would corrupt it — abort and let the user clear the directory by
!! hand if they really want a clean re-import.

    put cwd into BaseDir
    if file BaseDir cat `/data` exists
    begin
        print `data/ already exists. Delete it (rm -rf data) to re-run the importer.`
        exit
    end
    system `mkdir -p ` cat BaseDir cat `/data`
!! @hash cd4a62a6
!!!

!! Load the CSV file and split it into lines.
!!
!! Strip any carriage returns first so Windows-origin CRLF endings don't
!! leave a trailing \r on every line. `split … on newline` then gives us
!! an indexable array of plain lines.

    load Csv from BaseDir cat `/account.csv`
    replace `\r` with `` in Csv
    split Csv on newline
    put the elements of Csv into NumLines
!! @hash 46953cb7
!!!

!! Walk the data lines, dispatching each to parse / classify / write.
!!
!! Line 0 is the merged-cell title row; line 1 is the column headers; data
!! starts at line 2. Empty lines (blanks at the end of the CSV) are skipped.
!! Each kept row is appended directly to data/<FY>/<MM>.json — we do not
!! hold rows in memory because append-to-json-file does the bucketing for
!! us. The Skipped tally lets a human eyeball whether anything unexpected
!! got dropped.

    put empty into SeenFys
    put 0 into ServicesAdded
    put 0 into ExpensesAdded
    put 0 into Skipped
    put 2 into LineIndex
    while LineIndex is less than NumLines
    begin
        index Csv to LineIndex
        put Csv into Line
        if Line is not empty
        begin
            gosub ParseLine
            gosub Classify
            if Kind is `service`
            begin
                gosub BuildService
                gosub WriteRow
                add 1 to ServicesAdded
            end
            else if Kind is `expense`
            begin
                gosub BuildExpense
                gosub WriteRow
                add 1 to ExpensesAdded
            end
            else
                add 1 to Skipped
        end
        add 1 to LineIndex
    end
!! @hash 61bb9b50
!!!

!! Print a one-line summary and exit.

    print `Imported ` cat ServicesAdded cat ` service(s), ` cat ExpensesAdded cat ` expense(s); skipped ` cat Skipped cat ` row(s).`
    exit
!! @hash 910d75e1
!!!


!! Quote-aware split of Line into the 13-slot Fields array.
!!
!! Walks the line character by character. Inside a quoted field, commas are
!! literal text; outside, commas mark field boundaries. A pair of double
!! quotes inside a quoted field collapses to one literal quote. Any cell
!! that contains a comma or quote in the CSV is delimited by surrounding
!! double quotes — e.g. money like `"£2,030.00"`.

ParseLine:
    set the elements of Fields to 13
    put 0 into Pos
    put 0 into FieldIndex
    put empty into Field
    clear InQuotes
    put the length of Line into LineLen
    while Pos is less than LineLen
    begin
        put Pos into Next
        add 1 to Next
        put from Pos to Next of Line into Ch
        if InQuotes is true
        begin
            if Ch is `"`
            begin
                if Next is less than LineLen
                begin
                    put Next into Peek
                    add 1 to Peek
                    put from Next to Peek of Line into Ch2
                    if Ch2 is `"`
                    begin
                        put Field cat `"` into Field
                        put Peek into Pos
                    end
                    else
                    begin
                        clear InQuotes
                        put Next into Pos
                    end
                end
                else
                begin
                    clear InQuotes
                    put Next into Pos
                end
            end
            else
            begin
                put Field cat Ch into Field
                put Next into Pos
            end
        end
        else
        begin
            if Ch is `"`
            begin
                set InQuotes
                put Next into Pos
            end
            else if Ch is `,`
            begin
                index Fields to FieldIndex
                put Field into Fields
                add 1 to FieldIndex
                put empty into Field
                put Next into Pos
            end
            else
            begin
                put Field cat Ch into Field
                put Next into Pos
            end
        end
    end
    index Fields to FieldIndex
    put Field into Fields
    return
!! @hash 58b503d3
!!!


!! Decide whether Fields represents a service, an expense, or junk.
!!
!! Service: Seq (Fields[0]) and Date (Fields[1]) both non-empty.
!! Expense: Seq empty, Date non-empty, Mileage/Item (Fields[8]) is text
!!          (non-numeric), e.g. "Fees".
!! Skip:    everything else — monthly-total rows (Date empty), the grand
!!          total at the foot, and placeholder rows where Mileage/Item is
!!          numeric "0.0" but no real money applies.

Classify:
    index Fields to 0
    put Fields into Seq
    index Fields to 1
    put Fields into RawDate
    index Fields to 8
    put Fields into Item
    if Seq is not empty and RawDate is not empty
        put `service` into Kind
    else if Seq is empty and RawDate is not empty and Item is not empty
    begin
        if Item is `0.0`
            put `skip` into Kind
        else if Item is numeric
            put `skip` into Kind
        else
            put `expense` into Kind
    end
    else
        put `skip` into Kind
    return
!! @hash fc37f03b
!!!


!! Populate Row as a service-kind dictionary from Fields.
!!
!! Calls ParseDate (which also sets Fy and Mm) and the money/mileage
!! normalisers. Drops Seq (becomes derivable from position) and Monthly
!! (computed at render time).

BuildService:
    reset Row
    set entry `kind` of Row to `service`

    index Fields to 1
    put Fields into RawDate
    gosub ParseDate
    set entry `date` of Row to Iso

    index Fields to 2
    put Fields into Field
    set entry `name` of Row to Field

    index Fields to 3
    put Fields into Field
    set entry `location` of Row to Field

    index Fields to 4
    put Fields into Field
    set entry `time` of Row to Field

    index Fields to 5
    put Fields into Field
    set entry `distance` of Row to Field

    index Fields to 6
    put Fields into Field
    set entry `contact` of Row to Field

    index Fields to 7
    put Fields into Field
    set entry `client` of Row to Field

    index Fields to 8
    put Fields into Money
    gosub ParseMileage
    set entry `mileage` of Row to Tenths

    index Fields to 9
    put Fields into Money
    gosub ParseMoney
    set entry `expense` of Row to Pence

    index Fields to 10
    put Fields into Money
    gosub ParseMoney
    set entry `paid` of Row to Pence

    index Fields to 11
    put Fields into Money
    gosub ParseMoney
    set entry `fees` of Row to Pence
    return
!! @hash 0c427c67
!!!


!! Populate Row as an expense-kind dictionary from Fields.
!!
!! Expense rows have no name/location/time/distance/contact/client; the
!! Mileage/Item column carries a free-form description (e.g. "Fees").
!! Money columns are kept since the user may record either a cost, a
!! receipt, or both against an expense row.

BuildExpense:
    reset Row
    set entry `kind` of Row to `expense`

    index Fields to 1
    put Fields into RawDate
    gosub ParseDate
    set entry `date` of Row to Iso

    index Fields to 8
    put Fields into Field
    set entry `description` of Row to Field

    index Fields to 9
    put Fields into Money
    gosub ParseMoney
    set entry `expense` of Row to Pence

    index Fields to 10
    put Fields into Money
    gosub ParseMoney
    set entry `paid` of Row to Pence

    index Fields to 11
    put Fields into Money
    gosub ParseMoney
    set entry `fees` of Row to Pence
    return
!! @hash 71dff2bf
!!!


!! Parse RawDate ("DD/MM/YYYY") and set Iso, Fy, Mm.
!!
!! UK financial year runs 6 April – 5 April. A date on or after 6 April of
!! year Y belongs to FY "Y-(Y+1)"; earlier belongs to "(Y-1)-Y". Years are
!! named with the last two digits of the closing year (e.g. 2026-27).

ParseDate:
    put RawDate into Parts
    split Parts on `/`
    index Parts to 0
    put Parts into Day
    index Parts to 1
    put Parts into Month
    index Parts to 2
    put Parts into Year

    put Year cat `-` cat Month cat `-` cat Day into Iso
    put Month into Mm

    put Year into StartYear
    if Month is less than 4
        subtract 1 from StartYear
    else if Month is 4
    begin
        if Day is less than 6
            subtract 1 from StartYear
    end
    put StartYear into EndYear
    add 1 to EndYear
    put EndYear cat `` into EndStr
    put the length of EndStr into YearLen
    put YearLen into Pos
    subtract 2 from Pos
    put from Pos of EndStr into EndTail
    put StartYear cat `-` cat EndTail into Fy
    return
!! @hash b7978e42
!!!


!! Convert Money (e.g. "£2,030.00", "£0.00", "") into integer Pence.
!!
!! Strip £ and thousands separators, trim whitespace, split on '.'; whole
!! pounds × 100 + the two-digit pence part. An empty input becomes 0. A
!! value with no decimal point is treated as whole pounds.

ParseMoney:
    put Money into Stripped
    replace `£` with `` in Stripped
    replace `,` with `` in Stripped
    put trim Stripped into Stripped
    if Stripped is empty
    begin
        put 0 into Pence
        return
    end
    if Stripped includes `.`
    begin
        put Stripped into Parts
        split Parts on `.`
        index Parts to 0
        put Parts into Whole
        index Parts to 1
        put Parts into Cents
        if Whole is empty put 0 into Whole
        if the length of Cents is 1 put Cents cat `0` into Cents
        if the length of Cents is greater than 2
            put from 0 to 2 of Cents into Cents
        put Whole into Pence
        multiply Pence by 100
        add Cents to Pence
    end
    else
    begin
        put Stripped into Pence
        multiply Pence by 100
    end
    return
!! @hash 16cc0309
!!!


!! Convert Money (re-used as input variable) into integer tenths-of-a-mile.
!!
!! Mileage in the CSV is one-decimal like "44.4" or "0.0". We store it as
!! integer tenths so totals stay in integer arithmetic per AllSpeak's
!! floats-are-strings idiom — display code divides by 10 for presentation.
!! Empty or non-numeric input becomes 0.

ParseMileage:
    put trim Money into Stripped
    if Stripped is empty
    begin
        put 0 into Tenths
        return
    end
    if Stripped includes `.`
    begin
        put Stripped into Parts
        split Parts on `.`
        index Parts to 0
        put Parts into Whole
        index Parts to 1
        put Parts into Cents
        if Whole is empty put 0 into Whole
        if the length of Cents is 0 put `0` into Cents
        put from 0 to 1 of Cents into Cents
        put Whole into Tenths
        multiply Tenths by 10
        add Cents to Tenths
    end
    else
    begin
        put Stripped into Tenths
        multiply Tenths by 10
    end
    return
!! @hash aa99384f
!!!


!! Append Row to data/<FY>/<MM>.json, creating the FY directory on demand.
!!
!! `append to json file` creates the file with a one-element array if it
!! doesn't exist, but is silent about parent directories, so we ensure
!! the FY subdirectory exists with `mkdir -p` the first time we see each FY.
!! SeenFys is a comma-joined string used as a tiny membership set so we
!! don't shell out for every row.

WriteRow:
    put `,` cat Fy cat `,` into FyDir
    if SeenFys does not include FyDir
    begin
        system `mkdir -p ` cat BaseDir cat `/data/` cat Fy
        put SeenFys cat FyDir into SeenFys
    end
    put BaseDir cat `/data/` cat Fy cat `/` cat Mm cat `.json` into TargetPath
    append Row to json file TargetPath
    return
!! @hash dc5f2954
!!!
