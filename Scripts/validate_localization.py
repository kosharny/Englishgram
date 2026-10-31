"""Validate offline localization coverage and protected English examples."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "Englishgram/Resources"
CYRILLIC = re.compile(r"[А-Яа-яЁё]")
PROTECTED = re.compile(
    r"%[@\d$.*hlfdiu]+|%%|"
    r"[A-Za-z][A-Za-z0-9’' /+→=,.:;!?_()\-]*[A-Za-z0-9.!?)]|[A-Za-z]"
)


def source_strings(value):
    if isinstance(value, str) and CYRILLIC.search(value):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from source_strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from source_strings(item)


def main():
    catalog = json.loads((RESOURCES / "Localizable.xcstrings").read_text())
    translations = json.loads((RESOURCES / "CourseTranslationsEG.json").read_text())
    sources = set()
    for path in (ROOT / "Englishgram/Data").glob("*.json"):
        sources.update(source_strings(json.loads(path.read_text())))
    for language in ("pl", "uk"):
        values = translations[language]
        for source in sources:
            translated = values.get(source)
            assert translated, f"Missing {language} course translation: {source}"
            assert not re.search(r"ZX[QK]|KXZ|QXZ", translated), source
            for example in PROTECTED.findall(source):
                assert example in translated, f"Changed English example in {language}: {example}"
        for key, entry in catalog["strings"].items():
            unit = entry.get("localizations", {}).get(language, {}).get("stringUnit", {})
            assert unit.get("state") == "translated" and unit.get("value"), (language, key)
            assert re.findall(r"%(?:@|lld|d|%)", key) == re.findall(
                r"%(?:@|lld|d|%)", unit["value"]
            ), f"Changed format placeholders in {language}: {key}"
        print(f"{language}: {len(catalog['strings'])} UI strings, {len(sources)} course strings validated")


if __name__ == "__main__":
    main()
