<# This script deletes specified containers within a given Azure storage account.
		It checks if a lock exists on the storage account, removes the lock if present,
		deletes the specified containers, and restores the lock (if removed) afterward.
		Replace container names in the array '$containersToDelete' as needed. #>

		$resourceGroupName = "resourceGroupName"
		$storageAccountName = "storageAccountName"
		$containersToDelete = @("container1", "container2", "container3")

		$storageAccountScope = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Id
		$storageAccountContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

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

		foreach ($containerName in $containersToDelete) {

			$containerExists = Get-AzStorageContainer -Context $storageAccountContext -Name $containerName

			if ($containerExists) {
				Write-Output "Container '$containerName' exists."

				# Delete the specified container under the same storage account
				Write-Output "Deleting container..."
				Remove-AzStorageContainer -Context $storageAccountContext -Name $containerName -Force
			}
			else {
				Write-Output "Container '$containerName' does not exist."
			}
		}

		# Restore the lock if it was removed
		if ($lockRemoved) {
			Write-Output "Creating lock back ..."
			New-AzResourceLock -LockLevel $storageAccountLock.Properties.Level -LockNotes $storageAccountLock.Properties.Notes -LockName $storageAccountLock.Name -Scope $storageAccountScope -Force

		}
