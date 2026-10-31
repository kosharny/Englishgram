"""Refresh interface keys from the Swift compiler's extraction output."""
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
derived = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('/tmp/EnglishgramBuild')
output = root / 'Englishgram/Resources/Localizable.xcstrings'
catalog = json.loads(output.read_text()) if output.exists() else {'sourceLanguage': 'ru', 'strings': {}, 'version': '1.0'}
keys = set()
for source in derived.glob('Build/Intermediates.noindex/Englishgram.build/Debug-iphonesimulator/Englishgram.build/Objects-normal/arm64/*.stringsdata'):
    extraction = json.loads(source.read_text())
    if not Path(extraction['source']).exists():
        continue
    keys.update(item['key'] for item in extraction.get('tables', {}).get('Localizable', []))
if not keys:
    raise SystemExit('Build the simulator target first to extract interface strings.')
catalog['strings'] = {key: catalog['strings'].get(key, {'localizations': {'ru': {'stringUnit': {'state': 'translated', 'value': key}}}}) for key in sorted(keys)}
output.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
print(f'Updated {len(keys)} interface strings.')
