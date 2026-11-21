from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="loh-faq-") as directory:
    binary = str(Path(directory) / "tests")
    subprocess.run([
        "xcrun", "swiftc", "-swift-version", "5",
        "-module-cache-path", directory + "/modules",
        str(root / "LOH/App/MoreCycle/AllMoreViews/Tickets/FAQ/FAQModels.swift"),
        str(Path(__file__).with_name("FAQModelsTests.swift")),
        "-o", binary,
    ], check=True)
    subprocess.run([binary], check=True)
