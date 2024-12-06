# Prompt the user to enter the path of the folder they want to report on
$Path = Read-Host "Enter the path of the folder you want to report on"

# Get the list of folders under the specified path, including all subfolders
$Folders = Get-ChildItem -Path $Path -Directory -Recurse

# Create an empty array to store the output
$Output = @()

# Loop through each folder and add the folder path, item count, and size to the output array
foreach ($Folder in $Folders) {
    $ItemCount = (Get-ChildItem -Path $Folder.FullName | Measure-Object).Count
    $Size = (Get-ChildItem -Path $Folder.FullName | Measure-Object -Property Length -Sum).Sum
    $Output += [PSCustomObject]@{
        "Folder Path" = $Folder.FullName
        "Item Count" = $ItemCount
        "Size" = $Size
    }
}

# Export the output array to a CSV file
$Output | Export-Csv -Path "C:\Your\Output\File.csv" -NoTypeInformation
