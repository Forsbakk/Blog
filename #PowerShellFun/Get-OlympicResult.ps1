$Days = @(
    "https://www.eurosport.no/ol/langrenn/event/langrenn-74km-75km-skiathlon-kvinner"
    "https://www.eurosport.no/ol/hurtiglop-skoyter/event/hurtiglop-skoyter-5000-meter-menn/"
    "https://www.eurosport.no/ol/skiskyting/event/skiskyting-12-5-km-jaktstart-menn/"
    "https://www.eurosport.no/ol/langrenn/event/langrenn-individuell-klassisk-sprint-menn/"
    "https://www.eurosport.no/ol/skiskyting/event/skiskyting-15-km-individuelt-kvinner/"
    "https://www.eurosport.no/ol/alpint/event/alpint-super-g-menn/"
    "https://www.olympic.org/pyeongchang-2018/results/en/cross-country-skiing/results-men-s-15km-free-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/ski-jumping/result-men-s-large-hill-individual-fnl-0002sj-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/cross-country-skiing/results-men-s-4-x-10km-relay-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/speed-skating/result-men-s-500m-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/nordic-combined/results-individual-gundersen-lh-10km-fnl-0001cc-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/cross-country-skiing/results-ladies-team-sprint-free-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/alpine-skiing/results-men-s-slalom-fnl-000200-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/biathlon/results-men-s-4x7-5km-relay-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/cross-country-skiing/results-men-s-50km-mass-start-classic-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/cross-country-skiing/results-ladies-30km-mass-start-classic-fnl-000100-.htm"
)

$URL = "https://www.eurosport.no/ol/alpint/event/alpint-utfor-menn/phase/asm010o01/"
$WH = "https://outlook.office.com/webhook/a709d725-19f0-44cc-9a19-423144c0e90e@5eca1ec4-5a64-407b-9778-9f9147b7a293/IncomingWebhook/add628ae1f6e42879095aa7c724d148b/3eb3235c-90a4-4b04-8ec4-88c3dea3e446"

function Get-OLResults {
        Param (
            $URL
        )
    $page = Invoke-WebRequest $URL
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
        }
        $obj = New-Object psobject -Property $properties
        Write-Output $obj
    }
}

Function Invoke-OLResults {
    $data = Get-OLResults -URL $URL
    $sec = @()
    $BNF = $false
    $first = $data | Where-Object { ($_.Place -eq "1") -or ($_.Place -eq "=1") }
    foreach ($i in $first) {
        $iProps = @{
            "startGroup" = "true"
            "activityTitle" = "**$($i.Athlete)**"
            "activityText" = "Plassering: $($i.Place)"
            "activityImage" = $i.athleteFlag
        }
        if ($i.athleteFlag -eq "https://www.eurosport.no/d3images/ml/flags/s/NOR.png") { 
            $BNF = $true
            $iProps += @{
                "activitySubtitle" = "Beste norske"
            }
        }
        $sec += $iProps
    }
    $second = $data | Where-Object { ($_.Place -eq "2") -or ($_.Place -eq "=2") }
    foreach ($i in $second) {
        $iProps = @{
            "startGroup" = "true"
            "activityTitle" = "**$($i.Athlete)**"
            "activityText" = "Plassering: $($i.Place)"
            "activityImage" = $i.athleteFlag
        }
        if ($i.athleteFlag -eq "https://www.eurosport.no/d3images/ml/flags/s/NOR.png") { 
            $BNF = $true
            $iProps += @{
                "activitySubtitle" = "Beste norske"
            }
        }
        $sec += $iProps
    }
    $third = $data | Where-Object { ($_.Place -eq "3") -or ($_.Place -eq "=3") }
    foreach ($i in $third) {
        $iProps = @{
            "startGroup" = "true"
            "activityTitle" = "**$($i.Athlete)**"
            "activityText" = "Plassering: $($i.Place)"
            "activityImage" = $i.athleteFlag
        }
        if ($i.athleteFlag -eq "https://www.eurosport.no/d3images/ml/flags/s/NOR.png") { 
            $BNF = $true
            $iProps += @{
                "activitySubtitle" = "Beste norske"
            }
        }
        $sec += $iProps
    }
    if ($BNF -eq $false) {
        $bn = ($data | Where-Object { $_.athleteFlag -eq "https://www.eurosport.no/d3images/ml/flags/s/NOR.png" } | Measure-Object -Property place -Minimum).Minimum
        $i = $data | Where-Object { $_.Place -eq $bn }
        $iProps = @{
            "startGroup" = "true"
            "activityTitle" = "**$($i.Athlete)**"
            "activityText" = "Plassering: $($i.Place)"
            "activityImage" = $i.athleteFlag
            "activitySubtitle" = "Beste norske"
        }
        $sec += $iProps
    }
    $properties = @{
        "@type" = "MessageCard"
        "@context" = "http://schema.org/extensions"
        "summary" = "OL rapport"
        "themeColor" = "0075FF"
        "title" = "OL rapport"
        "sections" = $sec
    }
    $obj = New-Object psobject -Property $properties
    $body = $obj | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri $WH -Method Post -Body $body
}
Invoke-OLResults