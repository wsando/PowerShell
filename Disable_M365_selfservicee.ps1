# this script disables all self service trials in M365
$policies = Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase |
Where-Object { $_.PolicyValue -eq "Enabled" }

foreach ($policy in $policies) {
Update-MSCommerceProductPolicy `
-PolicyId AllowSelfServicePurchase `
-ProductId $policy.ProductId `
-Value "Disabled"
Write-Host "Disabled self-service for $($policy.ProductName)"
}