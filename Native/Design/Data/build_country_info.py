"""Build the offline facts resource from a local factbook.json checkout.
Usage: python3 Native/Design/Data/build_country_info.py /path/to/factbook.json
No network or executable code from the dataset is used.
"""
import hashlib
import html
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
NATIVE = HERE.parent.parent
SOURCE = Path(sys.argv[1]).resolve()
CATALOGUE = json.loads((NATIVE / 'FlagMaster/Resources/countries.json').read_text())
TRANSLATIONS = {}
for line in (HERE / 'country-info.zh-Hant.tsv').read_text().splitlines():
    code, capital, flag = line.split('\t')
    assert code not in TRANSLATIONS, code
    TRANSLATIONS[code] = (capital, flag)
assert set(TRANSLATIONS) == {c['abb2'] for c in CATALOGUE}

def clean(value):
    value = re.sub(r'<br\s*/?>', '\n', value, flags=re.I)
    return html.unescape(re.sub(r'<[^>]+>', '', value)).strip()

def localized(en, zh):
    return {'en': en, 'zhHant': zh}

profiles = {}
for path in sorted(SOURCE.glob('*/*.json')):
    d = json.loads(path.read_text())
    code = d.get('Communications', {}).get('Internet country code', {}).get('text', '')
    match = re.fullmatch(r'\.([a-z]{2})', code)
    if match:
        iso = {'UK': 'GB'}.get(match[1].upper(), match[1].upper())
        profiles[iso] = (path, d)
profiles['FR'] = (SOURCE / 'europe/fr.json', json.loads((SOURCE / 'europe/fr.json').read_text()))

flowers = {
    'TW': ('Plum blossom', '梅花', 'https://www.president.gov.tw/Page/98'),
    'SG': ('Vanda Miss Joaquim orchid', '卓錦萬代蘭', 'https://www.nhb.gov.sg/what-we-do/our-work/community-engagement/education/resources/national-symbols/national-flower'),
    'AU': ('Golden wattle (Acacia pycnantha)', '金合歡（Acacia pycnantha）', 'https://www.pmc.gov.au/honours-and-symbols/australian-national-symbols/australian-floral-emblem'),
    'KR': ('Mugunghwa / rose of Sharon', '木槿（無窮花）', 'https://www.mois.go.kr/eng/sub/a03/nationalSymbol_3/screen.do'),
    'ZA': ('King protea', '帝王花', 'https://www.gov.za/about-sa/national-flower'),
    'US': ('Rose', '玫瑰', 'https://postalmuseum.si.edu/exhibition/beautiful-blooms/the-rose-queen-of-flowers'),
    'MY': ('Hibiscus (Hibiscus rosa-sinensis)', '朱槿（大紅花）', 'https://www.malaysia.gov.my/en/government/kenali-malaysia/national-flower'),
    'PH': ('Sampaguita (Jasminum sambac)', '茉莉（Sampaguita）', 'https://www.nationalmuseum.gov.ph/2021/11/10/philippine-national-flower-sampaguita/'),
    'NP': ('Rhododendron arboreum', '樹形杜鵑（Rhododendron arboreum）', 'https://giwmscdnone.gov.np/media/pdf_upload/Plant%20Fact%20Sheet%20%202025_kupfs7p.pdf'),
    'LK': ('Blue water lily (Nymphaea nouchali)', '藍睡蓮（Nymphaea nouchali）', 'https://www.cabinetoffice.gov.lk/cab/index.php?Itemid=49&dID=6113&id=16&lang=en&option=com_content&view=article'),
    'MX': ('Dahlia', '大理花', 'https://www.gob.mx/snics/articulos/dalia-flor-nacional-mexicana'),
    'AR': ('Ceibo (Erythrina crista-galli)', '雞冠刺桐（Ceibo）', 'https://www.argentina.gob.ar/pais/ceibo'),
    'CL': ('Copihue (Lapageria rosea)', '智利鐘花（Copihue）', 'https://biblioredes.gob.cl/bibliotecas/panguipulli/contenidos-locales'),
    'JM': ('Lignum vitae', '癒創木花（Lignum vitae）', 'https://opm.gov.jm/symbols/national-flower-lignum-vitae/'),
    'BD': ('White water lily (Shapla)', '白睡蓮（Shapla）', 'https://bdembjp.mofa.gov.bd/public/storage/pdf/Country_Profile.pdf'),
}

# Explicit exceptions are kept here instead of silently rewriting source data.
capital_overrides = {
    'GQ': ('Ciudad de la Paz', 'https://www.guineaecuatorialpress.com/noticias/el_presidente_de_la_republica_proclama_la_ciudad_de_la_paz_como_capital_de_la_republica_de_guinea_ecuatorial_con_la_firma_de_un_decreto_ley'),
    'MM': ('Nay Pyi Taw (administrative capital)', None),
    'NL': ('Amsterdam (capital); The Hague (seat of government)', None),
    'MY': ('Kuala Lumpur (capital); Putrajaya (administrative centre)', None),
    'CH': ('Bern (federal seat)', None),
    'ID': ('Jakarta; Nusantara is the new-capital development project', 'https://www.dpr.go.id/kegiatan-dpr/berita/Tinjau-Implementasi-UU-IKN-Komisi-II-Fokus-Persiapan-Pembentukan-Ibu-Kota-Politik-di-2028-66140'),
    'IL': ('Jerusalem (internationally disputed status)', None),
    'PS': ('East Jerusalem (claimed capital); Ramallah (administrative centre)', 'https://www.mofa.pna.ps/en-us/mn/our-position'),
    'EU': ('No single capital; institutions in Brussels, Strasbourg, Luxembourg and Frankfurt', None),
}
flag_overrides = {
    'AF': 'This card shows the historical republic-era flag: black, red and green vertical bands with a white national emblem. The emblem includes a mosque and wheat. Afghanistan’s current de facto authorities use a different, white flag.',
    'CR': 'Five horizontal bands of blue, white, red, white and blue, with a wider red band. This card shows the civil version without a coat of arms. White is associated with peace; blue with the sky and opportunity.',
    'VE': 'Yellow, blue and red horizontal bands, with eight white stars in an arc on the blue band. This card shows the version without a coat of arms. The eighth star was added in 2006.',
    'KG': 'A yellow sun with 40 rays on a red field. Inside the sun is the roof opening of a traditional Kyrgyz yurt, known as a tunduk. The rays represent the Kyrgyz tribes; red is associated with bravery.',
    'PS': 'Black, white and green horizontal bands, with a red triangle at the hoist. The colours come from Arab flag traditions. The Palestine Liberation Organization adopted this flag in 1964.',
    'TW': 'A red field with a white sun on a blue canton. The sun’s twelve rays represent the traditional twelve two-hour periods of a day and continuing progress. Blue, white and red also express liberty, equality and fraternity.',
    'EU': 'Twelve gold stars form a circle on a blue field, expressing unity and harmony. The number of stars is fixed and does not count member states. The European Union is a union, not a country.',
}
extra_sources = {
    'TW': ['https://english.president.gov.tw/page/96'],
    'PS': ['https://www.mfae.gov.ps/en-us/palestine/thepalestinianflag', 'https://en.wikipedia.org/wiki/Outline_of_Palestine'],
}
result = {}
for country in CATALOGUE:
    code = country['abb2']
    path, data = profiles[code]
    g = data.get('Government', {})
    capital = clean(g.get('Capital', {}).get('name', {}).get('text', ''))
    flag = clean(g.get('Flag', {}).get('text', ''))
    # Public-domain reference prose; retain complete sentences and line breaks.
    sources = [{'title': 'World Factbook · ' + country['en'], 'url': 'https://github.com/factbook/factbook.json/blob/master/' + path.relative_to(SOURCE).as_posix()}]
    if code in capital_overrides:
        capital, url = capital_overrides[code]
        if url: sources.append({'title': 'Capital reference', 'url': url})
    if code in flag_overrides: flag = flag_overrides[code]
    for url in extra_sources.get(code, []): sources.append({'title': 'Country / flag reference', 'url': url})
    flower = None
    if code in flowers:
        en, zh, url = flowers[code]
        flower = localized(en, zh)
        sources.append({'title': 'National flower reference', 'url': url})
    capital_zh, flag_zh = TRANSLATIONS[code]
    assert capital and flag and capital_zh and flag_zh, code
    result[code] = {
        'capital': localized(capital, capital_zh),
        'flagDescription': localized(flag, flag_zh),
        'flower': flower,
        'flowerStatus': 'documented' if flower else ('notApplicable' if code == 'EU' else 'notCollected'),
        'sources': sources,
        'collectedOn': '2026-11-08',
        'historicalFlag': code == 'AF',
    }
    if code == 'PS': result[code]['sources'] = sources[1:]

out = NATIVE / 'FlagMaster/Resources/country-info.json'
out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
manifest = {str(path.relative_to(SOURCE)): hashlib.sha256(path.read_bytes()).hexdigest() for path, _ in profiles.values()}
(HERE / 'factbook-source-sha256.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
print(f'Wrote {len(result)} country cards; {len(flowers)} documented national flowers.')
