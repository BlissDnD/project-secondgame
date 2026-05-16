@echo off
setlocal EnableDelayedExpansion

if not exist trimmed mkdir trimmed

set MAXW=0
set MAXH=0

echo Scanning images...

REM === MAX MÉRETEK KERESÉSE ===
for %%f in (*.png) do (

    for /f %%s in ('
        magick "%%f" -trim +repage -format "%%w %%h" info:
    ') do (
        set SIZE=%%s
    )

    for /f "tokens=1,2" %%a in ("!SIZE!") do (
        set W=%%a
        set H=%%b

        if !W! GTR !MAXW! set MAXW=!W!
        if !H! GTR !MAXH! set MAXH=!H!
    )
)

echo.
echo MAX WIDTH  = !MAXW!
echo MAX HEIGHT = !MAXH!
echo.

echo Processing...

REM === KÉPEK FELDOLGOZÁSA ===
for %%f in (*.png) do (

    echo Processing %%f

    magick "%%f" ^
        -trim +repage ^
        -background transparent ^
        -gravity south ^
        -extent !MAXW!x!MAXH! ^
        "trimmed\%%~nxf"
)

echo.
echo DONE
pause