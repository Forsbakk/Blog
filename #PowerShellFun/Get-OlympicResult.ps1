$Days = @(
    "https://www.eurosport.no/ol/langrenn/event/langrenn-74km-75km-skiathlon-kvinner"
    "https://www.eurosport.no/ol/hurtiglop-skoyter/event/hurtiglop-skoyter-5000-meter-menn/"
    "https://www.eurosport.no/ol/skiskyting/event/skiskyting-12-5-km-jaktstart-menn/"
    "https://www.eurosport.no/ol/langrenn/event/langrenn-individuell-klassisk-sprint-menn/"
    "https://www.eurosport.no/ol/skiskyting/event/skiskyting-15-km-individuelt-kvinner/"
    "https://www.eurosport.no/ol/alpint/event/alpint-super-g-menn/"
    "https://www.eurosport.no/ol/langrenn/event/langrenn-15-km-fristil-menn/"
    "https://www.eurosport.no/ol/hopp/event/hopp-stor-bakke-menn/"
    "https://www.eurosport.no/ol/langrenn/event/langrenn-4x10-km-stafett-menn/"
    "https://www.eurosport.no/ol/hurtiglop-skoyter/event/hurtiglop-skoyter-500-meter-menn/"
    "https://www.eurosport.no/ol/kombinert/event/kombinert-stor-bakke-individuell/"
    "https://www.eurosport.no/ol/langrenn/event/langrenn-lagsprint-fristil-kvinner/"
    "https://www.eurosport.no/ol/alpint/event/alpint-slalam-menn/"
    "https://www.eurosport.no/ol/skiskyting/event/skiskyting-4x7-5-km-stafett-menn/"
    "https://www.eurosport.no/ol/langrenn/event/langrenn-50-kilometer-klassisk-fellesstart-menn/"
    "https://www.eurosport.no/ol/langrenn/event/langrenn-30-kilometer-klassisk-fellesstart-menn/"
)

$Webhook = "" #INSERT YOUR WEBHOOK HERE

function Get-OLResults {
        Param (
            $URL
        )
    $page = Invoke-WebRequest $URL
    $dataCond = $page.ParsedHtml.body.getElementsByTagName("h2") | Select-Object -ExpandProperty innerText
    if ($dataCond -notcontains "Resultater") {
        Write-Output "NO DATA AVAILABLE"
    }
    else {
        $raceTitle = $page.ParsedHtml.title
        $table = $page.ParsedHtml.body.getElementsByTagName('Table') | Select-Object Rows
        $hRow = $true
        ForEach ($row in $table.rows) {
            if ($hRow -eq $true) {
                $hRow = $false
            }
            else {
                $cells = $row.cells
                $placement = $cells[0].innerText
                $athlete = $cells[2].innerText
                $athlete = $athlete.Trim()
                $athleteFlag = $cells[2].getElementsByTagName("IMG") | Select-Object -ExpandProperty Src
            }
            $athleteFlag = $athleteFlag -replace "about:","https://www.eurosport.no"

            $properties = @{
                Place = $placement
                Athlete = $athlete
                athleteFlag = $athleteFlag
                raceTitle = $raceTitle
            }
            $obj = New-Object psobject -Property $properties
            Write-Output $obj
        }
    }
}
Function Send-OLResults {
    Param (
        $URL,
        $WH
    )
    $data = Get-OLResults -URL $URL
    if ($data -eq "NO DATA AVAILABLE") {}
    else {
        $sec = @()
        $BNF = $false
        $RTF = $false
        $first = $data | Where-Object { ($_.Place -eq "1") -or ($_.Place -eq "=1") }
        foreach ($i in $first) {
            if ($RTF -eq $false) {
                $raceTitle = $i.raceTitle
                $RTF = $true
            }
            $iProps = @{
                "startGroup" = "true"
                "activityTitle" = $i.Athlete
                "activityText" = "Placement: $($i.Place)"
                "activityImage" = $i.athleteFlag
            }
            if ($i.athleteFlag -eq "https://www.eurosport.no/d3images/ml/flags/s/NOR.png") { 
                $BNF = $true
                $iProps += @{
                    "activitySubtitle" = "Best norwegian athlete"
                }
            }
            $sec += $iProps
        }
        $second = $data | Where-Object { ($_.Place -eq "2") -or ($_.Place -eq "=2") }
        foreach ($i in $second) {
            $iProps = @{
                "startGroup" = "true"
                "activityTitle" = $i.Athlete
                "activityText" = "Placement: $($i.Place)"
                "activityImage" = $i.athleteFlag
            }
            if (($i.athleteFlag -eq "https://www.eurosport.no/d3images/ml/flags/s/NOR.png") -and ($BNF -eq $false)) { 
                $BNF = $true
                $iProps += @{
                    "activitySubtitle" = "Best norwegian athlete"
                }
            }
            $sec += $iProps
        }
        $third = $data | Where-Object { ($_.Place -eq "3") -or ($_.Place -eq "=3") }
        foreach ($i in $third) {
            $iProps = @{
                "startGroup" = "true"
                "activityTitle" = $i.Athlete
                "activityText" = "Placement: $($i.Place)"
                "activityImage" = $i.athleteFlag
            }
            if (($i.athleteFlag -eq "https://www.eurosport.no/d3images/ml/flags/s/NOR.png") -and ($BNF -eq $false)) { 
                $BNF = $true
                $iProps += @{
                    "activitySubtitle" = "Best norwegian athlete"
                }
            }
            $sec += $iProps
        }
        if ($BNF -eq $false) {
            $bn = ($data | Where-Object { $_.athleteFlag -eq "https://www.eurosport.no/d3images/ml/flags/s/NOR.png" } | Measure-Object -Property place -Minimum).Minimum
            $i = $data | Where-Object { $_.Place -eq $bn }
            $iProps = @{
                "startGroup" = "true"
                "activityTitle" = $i.Athlete
                "activityText" = "Placement: $($i.Place)"
                "activityImage" = $i.athleteFlag
                "activitySubtitle" = "Best norwegian athlete"
            }
            $sec += $iProps
        }
        $properties = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "summary" = $raceTitle
            "themeColor" = "0075FF"
            "title" = $raceTitle
            "sections" = $sec
        }
        $obj = New-Object psobject -Property $properties
        $body = $obj | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri $Webhook -Method Post -Body $body -ContentType "application/json;charset=UTF-8" | Out-Null
    }
}

foreach ($day in $Days) {
    Send-OLResults -URL $day -WH $Webhook
}