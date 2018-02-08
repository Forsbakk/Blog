$Days = @(
    "https://www.olympic.org/pyeongchang-2018/results/en/cross-country-skiing/results-ladies-7-5km--plus--7-5km-skiathlon-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/speed-skating/result-men-s-5000m-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/biathlon/results-men-s-12-5km-pursuit-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/cross-country-skiing/results-men-s-sprint-classic-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/biathlon/results-women-s-15km-individual-fnl-000100-.htm"
    "https://www.olympic.org/pyeongchang-2018/results/en/alpine-skiing/results-men-s-super-g-fnl-000100-.htm"
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

$testURI = "https://www.olympic.org/pyeongchang-2018/results/en/luge/lugr073a-men-s-singles-trno-b00200-.htm"

$data = Invoke-WebRequest -Uri $testURI

$table = $data.ParsedHtml.Body.getElementsByTagName("TABLE") | Select InnerHTML
$table.InnerHTML