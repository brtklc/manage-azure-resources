		# This PowerShell script checks if a specified container exists within an Azure Storage Account. If the container exists, it removes any existing lock on the storage account, deletes the container, and then re-applies the lock (if it was removed).

		$resourceGroupName = "resourceGroupName"
		$storageAccountName = "storageAccountName"
		$containerToDelete = "container"

		$storageAccountScope = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Id
		$storageAccountContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
		$containerExists = Get-AzStorageContainer -Context $storageAccountContext -Name $containerToDelete

		if ($containerExists) {
			Write-Output "Container '$containerToDelete' exists."

			# Check if there is a Lock on the storage account
			$storageAccountLock = Get-AzResourceLock -Scope $storageAccountScope

			if ($storageAccountLock) {
				Write-Output "Removing lock on storage account..."
				Write-Output "Lock Name: $($storageAccountLock.Name)"
				Write-Output "Lock Level: $($storageAccountLock.Properties.Level)"
				Write-Output "Lock Notes: $($storageAccountLock.Properties.Notes)"
				Remove-AzResourceLock -LockId $storageAccountLock.LockId -Force
				$lockRemoved = $true

			}
			else {
				Write-Output "No lock on storage account..."
			}

			# Delete the specified container under the same storage account
			Write-Output "Deleting container..."
			Remove-AzStorageContainer -Context $storageAccountContext -Name $containerToDelete

			if ($lockRemoved) {
				Write-Output "Creating lock back ..."
				New-AzResourceLock -LockLevel $storageAccountLock.Properties.Level -LockNotes $storageAccountLock.Properties.Notes -LockName $storageAccountLock.Name -Scope $storageAccountScope -Force

			}
		}
		else {
			Write-Output "Containder does not exist."
		}
