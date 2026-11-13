#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
device=(root/'Sources/Services/DeviceInfoService.swift').read_text()
model=(root/'Sources/Models/DeviceInfo.swift').read_text()
storage=(root/'Sources/Views/StorageView.swift').read_text()
updates=(root/'Sources/Services/UpdateIntelligenceService.swift').read_text()
assert 'volumeAvailableCapacityForImportantUsageKey' in device
assert 'availableBytes: Int64?' in model
assert 'Available Storage' in storage and 'availableBytes ?? model.device.freeBytes' in storage
assert 'volumeAvailableCapacityForImportantUsageKey' in updates
assert 'ProviderCredentials' not in device
print('Fix 8 storage-source assertions passed; macOS runtime comparison still required.')
