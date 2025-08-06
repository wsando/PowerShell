# Replace with the target user's UPN or email
$User = "user@domain.com"

# Connect to Exchange Online (if not already connected)
# Connect-ExchangeOnline -UserPrincipalName admin@domain.com

# Get all mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited
# Create an array to store results
$delegatedMailboxes = @()

foreach ($mbx in $mailboxes) {
    $permissions = Get-MailboxPermission -Identity $mbx.Identity | Where-Object {
        $_.User.ToString() -eq $User -and $_.AccessRights -ne "None"
    }

    if ($permissions) {
        $delegatedMailboxes += [PSCustomObject]@{
            Mailbox         = $mbx.Identity
            AccessRights    = ($permissions | Select-Object -ExpandProperty AccessRights) -join ", "
        }
    }
}

# Display results
$delegatedMailboxes | Format-Table -AutoSize
