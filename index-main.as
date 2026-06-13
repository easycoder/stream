!   index-main.as
!   Anonymous landing page for eclecity.net.

    script Index

    div Body
    variable Layout

    create Body
    rest get Layout from `index.json`
    render Layout in Body

    stop
