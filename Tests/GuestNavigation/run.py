"""Run the production auth/app coordinators with lightweight session and tab doubles."""
from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='loh-guest-navigation-') as directory:
    binary = str(Path(directory) / 'GuestNavigationTests')
    sources = [
        'LOH/Coordinator/BaseCoordinator/BaseCoordinator.swift',
        'LOH/Coordinator/BaseCoordinator/AppRoot.swift',
        'LOH/Coordinator/BaseCoordinator/AppCoordinator.swift',
        'LOH/Coordinator/AuthCoordinator/AuthCoordinator.swift',
        'Tests/GuestNavigation/GuestNavigationTests.swift',
    ]
    subprocess.run(['xcrun', 'swiftc', '-swift-version', '5', '-module-cache-path', directory + '/modules',
                    *[str(root / source) for source in sources], '-o', binary], check=True)
    subprocess.run([binary], check=True)
