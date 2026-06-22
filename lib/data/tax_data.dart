// 2024 tax bracket data used by TaxCalculator. Data is bundled into the
// app rather than fetched live because (a) tax brackets only change once a
// year so a network round-trip would be wasted on most launches and
// (b) most public tax-calculation APIs require paid API keys. Each year's
// brackets can be updated in-place — see `code` to find the entry quickly.

class TaxBracket {
  final double upTo;
  final double rate;
  const TaxBracket(this.upTo, this.rate);
}

class Jurisdiction {
  final String code;
  final String name;
  final String country; // 'CA' or 'US'
  final List<TaxBracket> nationalBrackets;
  final List<TaxBracket> subnationalBrackets;
  const Jurisdiction({
    required this.code,
    required this.name,
    required this.country,
    required this.nationalBrackets,
    required this.subnationalBrackets,
  });
}

/// Canadian federal brackets, 2024 (CRA).
const _caFederal = [
  TaxBracket(55867, 0.150),
  TaxBracket(111733, 0.205),
  TaxBracket(173205, 0.260),
  TaxBracket(246752, 0.290),
  TaxBracket(double.infinity, 0.330),
];

/// US federal brackets, 2024 (single filer).
const _usFederal = [
  TaxBracket(11600, 0.10),
  TaxBracket(47150, 0.12),
  TaxBracket(100525, 0.22),
  TaxBracket(191950, 0.24),
  TaxBracket(243725, 0.32),
  TaxBracket(609350, 0.35),
  TaxBracket(double.infinity, 0.37),
];

/// All supported jurisdictions. Sorted by country then alphabetic name.
const List<Jurisdiction> jurisdictions = [
  // ── Canada ─────────────────────────────────────
  Jurisdiction(
    code: 'CA-AB',
    name: 'Alberta',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(148269, 0.10),
      TaxBracket(177922, 0.12),
      TaxBracket(237230, 0.13),
      TaxBracket(355845, 0.14),
      TaxBracket(double.infinity, 0.15),
    ],
  ),
  Jurisdiction(
    code: 'CA-BC',
    name: 'British Columbia',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(47937, 0.0506),
      TaxBracket(95875, 0.0770),
      TaxBracket(110076, 0.1050),
      TaxBracket(133664, 0.1229),
      TaxBracket(181232, 0.1470),
      TaxBracket(252752, 0.1680),
      TaxBracket(double.infinity, 0.2050),
    ],
  ),
  Jurisdiction(
    code: 'CA-MB',
    name: 'Manitoba',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(47000, 0.1080),
      TaxBracket(100000, 0.1275),
      TaxBracket(double.infinity, 0.1740),
    ],
  ),
  Jurisdiction(
    code: 'CA-NB',
    name: 'New Brunswick',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(49958, 0.094),
      TaxBracket(99916, 0.140),
      TaxBracket(185064, 0.160),
      TaxBracket(double.infinity, 0.195),
    ],
  ),
  Jurisdiction(
    code: 'CA-NL',
    name: 'Newfoundland and Labrador',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(43198, 0.087),
      TaxBracket(86395, 0.145),
      TaxBracket(154244, 0.158),
      TaxBracket(215943, 0.178),
      TaxBracket(275870, 0.198),
      TaxBracket(551739, 0.208),
      TaxBracket(1103478, 0.213),
      TaxBracket(double.infinity, 0.218),
    ],
  ),
  Jurisdiction(
    code: 'CA-NS',
    name: 'Nova Scotia',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(29590, 0.0879),
      TaxBracket(59180, 0.1495),
      TaxBracket(93000, 0.1667),
      TaxBracket(150000, 0.1750),
      TaxBracket(double.infinity, 0.2100),
    ],
  ),
  Jurisdiction(
    code: 'CA-ON',
    name: 'Ontario',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(51446, 0.0505),
      TaxBracket(102894, 0.0915),
      TaxBracket(150000, 0.1116),
      TaxBracket(220000, 0.1216),
      TaxBracket(double.infinity, 0.1316),
    ],
  ),
  Jurisdiction(
    code: 'CA-PE',
    name: 'Prince Edward Island',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(32656, 0.0965),
      TaxBracket(64313, 0.1363),
      TaxBracket(105000, 0.1665),
      TaxBracket(140000, 0.1800),
      TaxBracket(double.infinity, 0.1875),
    ],
  ),
  Jurisdiction(
    code: 'CA-QC',
    name: 'Quebec',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(51780, 0.140),
      TaxBracket(103545, 0.190),
      TaxBracket(126000, 0.240),
      TaxBracket(double.infinity, 0.2575),
    ],
  ),
  Jurisdiction(
    code: 'CA-SK',
    name: 'Saskatchewan',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(52057, 0.105),
      TaxBracket(148734, 0.125),
      TaxBracket(double.infinity, 0.145),
    ],
  ),
  Jurisdiction(
    code: 'CA-YT',
    name: 'Yukon',
    country: 'CA',
    nationalBrackets: _caFederal,
    subnationalBrackets: [
      TaxBracket(55867, 0.0640),
      TaxBracket(111733, 0.0900),
      TaxBracket(173205, 0.1090),
      TaxBracket(500000, 0.1280),
      TaxBracket(double.infinity, 0.1500),
    ],
  ),

  // ── United States (state portion, ~2024) ──────
  // For US states with no state income tax we use a single 0% subnational
  // bracket; the federal portion still applies.
  Jurisdiction(
    code: 'US-CA',
    name: 'California',
    country: 'US',
    nationalBrackets: _usFederal,
    subnationalBrackets: [
      TaxBracket(10412, 0.010),
      TaxBracket(24684, 0.020),
      TaxBracket(38959, 0.040),
      TaxBracket(54081, 0.060),
      TaxBracket(68350, 0.080),
      TaxBracket(349137, 0.093),
      TaxBracket(418961, 0.103),
      TaxBracket(698271, 0.113),
      TaxBracket(double.infinity, 0.123),
    ],
  ),
  Jurisdiction(
    code: 'US-FL',
    name: 'Florida',
    country: 'US',
    nationalBrackets: _usFederal,
    subnationalBrackets: [TaxBracket(double.infinity, 0.0)],
  ),
  Jurisdiction(
    code: 'US-NY',
    name: 'New York',
    country: 'US',
    nationalBrackets: _usFederal,
    subnationalBrackets: [
      TaxBracket(8500, 0.04),
      TaxBracket(11700, 0.045),
      TaxBracket(13900, 0.0525),
      TaxBracket(80650, 0.055),
      TaxBracket(215400, 0.06),
      TaxBracket(1077550, 0.0685),
      TaxBracket(5000000, 0.0965),
      TaxBracket(25000000, 0.103),
      TaxBracket(double.infinity, 0.109),
    ],
  ),
  Jurisdiction(
    code: 'US-TX',
    name: 'Texas',
    country: 'US',
    nationalBrackets: _usFederal,
    subnationalBrackets: [TaxBracket(double.infinity, 0.0)],
  ),
  Jurisdiction(
    code: 'US-WA',
    name: 'Washington',
    country: 'US',
    nationalBrackets: _usFederal,
    subnationalBrackets: [TaxBracket(double.infinity, 0.0)],
  ),
];

/// Returns the jurisdiction that best matches [input] — accepts either the
/// short code (e.g. 'CA-ON') or any case-insensitive prefix of the name
/// (e.g. 'ontario', 'Ont', 'New B'). Returns null when no confident match.
Jurisdiction? findJurisdiction(String? input) {
  if (input == null) return null;
  final needle = input.trim().toLowerCase();
  if (needle.isEmpty) return null;
  // Code exact match first
  for (final j in jurisdictions) {
    if (j.code.toLowerCase() == needle) return j;
  }
  // Name exact match
  for (final j in jurisdictions) {
    if (j.name.toLowerCase() == needle) return j;
  }
  // Name prefix
  for (final j in jurisdictions) {
    if (j.name.toLowerCase().startsWith(needle)) return j;
  }
  // Substring as last resort
  for (final j in jurisdictions) {
    if (j.name.toLowerCase().contains(needle)) return j;
  }
  return null;
}
