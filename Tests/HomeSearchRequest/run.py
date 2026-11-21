"""Compile the production search request with its real filter model."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / "LOH/App/HomeCycle/Shared/Model/HomeAPIModels.swift").read_text()
request = source[source.index("struct HomeSearchRequest:"):source.index("extension KeyedDecodingContainer {")]
with tempfile.TemporaryDirectory(prefix="loh-search-request-") as directory:
    temp = Path(directory)
    request_file = temp / "HomeSearchRequest.swift"
    request_file.write_text("import Foundation\n\n" + request)
    binary = temp / "tests"
    subprocess.run(["xcrun", "swiftc", "-swift-version", "5", "-module-cache-path", str(temp / "modules"),
                    str(root / "LOH/App/HomeCycle/Shared/Model/HomeCatalog.swift"), str(request_file),
                    str(Path(__file__).with_name("HomeSearchRequestTests.swift")), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
