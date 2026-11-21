"""Keep screens separate and include Model/ViewModel layers only when used."""
from pathlib import Path

root = Path(__file__).resolve().parents[2]
app = root / "LOH/App"
layers = {"View", "Model", "ViewModel"}
screens = set()

for source in sorted(app.rglob("*.swift")):
    parts = source.relative_to(app).parts
    layer = next((i for i, part in enumerate(parts) if part in layers), None)
    assert layer is not None, f"Place {source.relative_to(root)} in a screen or Shared layer"
    if "Shared" not in parts[:layer]:
        screens.add(app.joinpath(*parts[:layer]))

for screen in sorted(screens):
    assert (screen / "View").is_dir(), f"Missing {screen.relative_to(root)}/View"
    for layer in sorted(layers):
        directory = screen / layer
        if directory.exists():
            assert any(directory.rglob("*.swift")), f"Remove unused {directory.relative_to(root)}"

assert not (app / "HomeCycle/HomeView").exists(), "Do not bundle Home screens under HomeView"
assert (app / "HomeCycle/HomeMerchant/View/HomeMerchantView.swift").is_file()
assert (app / "HomeCycle/Shared/View").is_dir()
print(f"PASS: {len(screens)} screens have their own View folder; Model/ViewModel folders exist only when used")
