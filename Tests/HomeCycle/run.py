"""Exercise the real preview catalog and state without network services or a simulator."""
from pathlib import Path
import subprocess
import tempfile
import json
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="loh-home-tests-") as directory:
    temporary = Path(directory)
    executable = temporary / "HomeCatalogTests"
    subprocess.run([
        "xcrun", "swiftc", "-swift-version", "5", "-module-cache-path", str(temporary / "modules"),
        str(root / "LOH/App/HomeCycle/Shared/Model/HomeCatalog.swift"),
        str(root / "LOH/App/HomeCycle/Shared/Model/HomeLocalization.swift"),
        str(Path(__file__).with_name("HomeCatalogTests.swift")), "-o", str(executable),
    ], check=True)
    subprocess.run([str(executable)], check=True)

catalog = root / "LOH/Core/Assets.xcassets"
manifest = json.loads((root / "LOH/Shared/Resourses/LOHHomeAssetManifest.json").read_text())
for item in manifest:
    matches = list(catalog.rglob(item["asset"] + ".imageset"))
    assert len(matches) == 1, item["asset"]
    contents = json.loads((matches[0] / "Contents.json").read_text())
    path = matches[0] / contents["images"][0]["filename"]
    assert path.stat().st_size > 0, path
    svg = ET.parse(path).getroot()
    assert float(svg.attrib["width"]) > 0 and float(svg.attrib["height"]) > 0, path

source = "\n".join(p.read_text() for p in (root / "LOH/App/HomeCycle").rglob("*.swift"))
keys = set(re.findall(r'home(?:Text|Format)\("([a-zA-Z]+)"\)', source))
for language in ["ar", "en"]:
    strings = (root / f"LOH/Shared/Localization/Strings/{language}.lproj/Localizable.strings").read_text()
    available = set(re.findall(r'^"home\.([^"]+)"\s*=', strings, re.M))
    assert keys <= available, (language, keys - available)
    subprocess.run(["plutil", "-lint", str(root / f"LOH/Shared/Localization/Strings/{language}.lproj/Localizable.strings")], check=True)
print(f"PASS: {len(manifest)} original Figma exports and both localization tables")

# Each language must provide every key and preserve the same format arguments.
tables = {}
for language in ["ar", "en"]:
    path = root / f"LOH/Shared/Localization/Strings/{language}.lproj/Localizable.strings"
    pairs = re.findall(r'^"home\.([^"]+)"\s*=\s*"(.*)";', path.read_text(), re.M)
    assert len(pairs) == len(dict(pairs)), f"Duplicate keys in {language}"
    tables[language] = dict(pairs)
assert tables["ar"].keys() == tables["en"].keys()
for key in tables["en"]:
    assert tables["ar"][key].strip() and tables["en"][key].strip(), key
    arguments = lambda value: sorted(re.findall(r"%(?:[0-9]+\$)?[@df]", value))
    assert arguments(tables["ar"][key]) == arguments(tables["en"][key]), key
print("PASS: complete Arabic/English key parity and format argument compatibility")

# Exercise the real language manager and actual .lproj bundle lookups.
import shutil
with tempfile.TemporaryDirectory(prefix="loh-language-tests-") as directory:
    temporary = Path(directory)
    bundle = temporary / "Localization.bundle"
    bundle.mkdir()
    for language in ["ar", "en"]:
        # Reproduce the shipped app: only its established Localizable table.
        destination = bundle / f"{language}.lproj"
        destination.mkdir()
        subprocess.run(["plutil", "-convert", "binary1", "-o", str(destination / "Localizable.strings"),
                        str(root / f"LOH/Shared/Localization/Strings/{language}.lproj/Localizable.strings")], check=True)
        assert not (destination / "HomeLocalizable.strings").exists()
    executable = temporary / "HomeLanguageTests"
    subprocess.run([
        "xcrun", "swiftc", "-swift-version", "5", "-module-cache-path", str(temporary / "modules"),
        str(root / "LOH/Shared/Localization/Language.swift"),
        str(root / "LOH/App/HomeCycle/Shared/Model/HomeLocalization.swift"),
        str(root / "LOH/App/HomeCycle/Shared/Model/HomeCatalog.swift"),
        str(Path(__file__).with_name("HomeLanguageTests.swift")), "-o", str(executable),
    ], check=True)
    subprocess.run([str(executable), str(bundle)], check=True)
