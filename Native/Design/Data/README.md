# Offline study-card information

`FlagMaster/Resources/country-info.json` contains one entry for each of the 198
catalogue codes. Every entry has an English reference description, a concise
Traditional Chinese flag introduction, capital/administrative-seat information,
source URLs and a collection date. Region and location reuse the existing
StudyRegion and WorldMapData models. The EU is explicitly treated as a union.

The primary bulk source is [factbook.json](https://github.com/factbook/factbook.json),
a CC0 distribution of public-domain World Factbook country profiles. The English
reference prose is cleaned of HTML. Traditional Chinese summaries are editorial
adaptations in `country-info.zh-Hant.tsv`, not automatic word substitutions.
`FACTBOOK-LICENSE.md` preserves the upstream license. Source checksums are stored
in `factbook-source-sha256.json`. Collection date is not a claim that all upstream
facts were reverified on that day.

Rebuild from a downloaded local checkout:

```sh
python3 Native/Design/Data/build_country_info.py /path/to/factbook.json
```

The importer maps source internet codes to catalogue ISO codes, handles the UK/GB
and France exceptions, checks full catalogue coverage, and applies documented
editorial overrides. It performs no network access; the app reads bundled data.
National-flower sources and capital/flag exceptions are kept in the importer.

## Coverage and limits

- Capital/seat and flag descriptions: 198/198 entries, in English and Traditional
  Chinese. Multi-capital states and countries without a formal capital retain
  those distinctions. The capital of Equatorial Guinea is updated to Ciudad de
  la Paz using its government's January 2026 announcement.
- National flowers: 15 sourced entries (AR, AU, BD, CL, JM, KR, LK, MX, MY, NP,
  PH, SG, TW, US, ZA). The other 182 country entries explicitly say the collection
  has not yet documented the flower. That is **not** a claim that no national
  flower exists. The EU entry is not applicable. Do not infer national-flower
  status from a national tree, general plant symbol, popularity poll, or folklore.
- Japanese and Korean interface labels are localized; reference prose currently
  falls back to English, with a visible explanation in the panel.
- Afghanistan's existing asset is a historical republic-era flag and is labeled
  accordingly. Costa Rica and Venezuela display versions without coats of arms;
  their descriptions match these assets. Kyrgyzstan's introduction omits the
  outdated yurt-line detail in the bulk source. Existing flag images are unchanged.
- Borders, country recognition, disputed capitals and source conventions are not
  resolved by this feature. Palestine's claimed capital and administrative centre
  are distinguished, and Jerusalem's disputed status is retained for Israel.
- Sources are available from the information panel. Reading facts and maps needs
  no network connection; opening a source link does.

## Verification

`CountryInformationTests` verifies exact catalogue coverage, bilingual fields,
source links, absence of raw HTML, explicit flower status, and special cases.

Simulator fixture:

```text
--preview-screen flashcards --preview-country TW --preview-info --preview-motion
```

`--preview-info-checks` exercises the state used by the info button, confirms that
navigation is blocked while information is open, then closes it, changes country,
and checks that reopening shows the new country's information. It is not a
substitute for real-device gesture and VoiceOver testing.
