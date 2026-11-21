from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="loh-auth-cancellation-") as directory:
    binary = str(Path(directory) / "tests")
    sources = [
        "LOH/App/AuthCycle/Login/ViewModel/LoginViewModel.swift",
        "LOH/App/AuthCycle/CompleteRegisterDataView/ViewModel/CompleteRegisterDataViewModel.swift",
        "LOH/App/AuthCycle/CompleteRegisterDataView/Model/UserRegisterModel.swift",
        "LOH/App/AuthCycle/Shared/Model/AuthInput.swift",
        "Tests/AuthCancellation/AuthCancellationTests.swift",
    ]
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", "-module-cache-path", directory + "/modules",
                    *[str(root / source) for source in sources], "-o", binary], check=True)
    subprocess.run([binary], check=True)
