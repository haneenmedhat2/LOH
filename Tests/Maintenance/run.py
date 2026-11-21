from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
sources = [
    'LOH/Networking/NetworkConstants.swift',
    'LOH/Networking/HandelRequest/Endpoint.swift',
    'LOH/Networking/HandleResponse/NetworkExecuter.swift',
    'LOH/Networking/HandleResponse/ResponseDecoder.swift',
    'LOH/Networking/HandleResponse/ResponseError.swift',
    'LOH/Networking/HandleResponse/APIResponseStatus.swift',
    'LOH/Networking/HandleResponse/ResponseHandler.swift',
    'LOH/App/Maintenance/ViewModel/MaintenanceViewModel.swift',
    'Tests/Maintenance/TestSupport.swift',
    'Tests/Maintenance/MaintenanceTests.swift',
]
with tempfile.TemporaryDirectory(prefix='loh-maintenance-tests-') as directory:
    binary = str(Path(directory) / 'MaintenanceTests')
    subprocess.run([
        'xcrun', 'swiftc', '-swift-version', '5', '-module-cache-path', str(Path(directory) / 'modules'),
        *[str(root / path) for path in sources], '-o', binary,
    ], check=True)
    subprocess.run([binary], check=True, timeout=30)
