import 'app_localizations.dart';

/// Localized display names for the fixed preset vocabularies (goal icons,
/// expense-category presets, income-source suggestions, month abbreviations).
/// The underlying keys stored in models stay English/stable; only the shown
/// label is translated.

String goalIconLabel(AppLocalizations l, String key) {
  switch (key) {
    case 'savings':
      return l.giconSavings;
    case 'travel':
      return l.giconTravel;
    case 'vehicle':
      return l.giconVehicle;
    case 'home':
      return l.giconHome;
    case 'education':
      return l.giconEducation;
    case 'wedding':
      return l.giconWedding;
    case 'emergency':
      return l.giconEmergency;
    case 'tech':
      return l.giconTech;
    case 'gift':
      return l.giconGift;
    default:
      return l.giconOther;
  }
}

String expensePresetLabel(AppLocalizations l, String key) {
  switch (key) {
    case 'home':
      return l.expHousing;
    case 'food':
      return l.expFood;
    case 'transport':
      return l.expTransport;
    case 'savings':
      return l.expSavings;
    case 'entertainment':
      return l.expEntertainment;
    case 'subscriptions':
      return l.expSubscriptions;
    case 'healthcare':
      return l.expHealthcare;
    case 'personal':
      return l.expPersonal;
    default:
      return l.expOther;
  }
}

/// Stable keys for the income-source quick-pick chips.
const incomeSuggestionKeys = [
  'salary', 'wages', 'partTime', 'freelance', 'investments', 'dividends',
  'rental', 'business', 'benefits', 'scholarship', 'pension',
];

String incomeSuggestionLabel(AppLocalizations l, String key) {
  switch (key) {
    case 'salary':
      return l.incSalary;
    case 'wages':
      return l.incWages;
    case 'partTime':
      return l.incPartTime;
    case 'freelance':
      return l.incFreelance;
    case 'investments':
      return l.incInvestments;
    case 'dividends':
      return l.incDividends;
    case 'rental':
      return l.incRental;
    case 'business':
      return l.incBusiness;
    case 'benefits':
      return l.incBenefits;
    case 'scholarship':
      return l.incScholarship;
    default:
      return l.incPension;
  }
}

/// Three-letter month abbreviations, indexed 0 (Jan) to 11 (Dec).
List<String> monthAbbrevs(AppLocalizations l) => [
      l.monJan, l.monFeb, l.monMar, l.monApr, l.monMay, l.monJun,
      l.monJul, l.monAug, l.monSep, l.monOct, l.monNov, l.monDec,
    ];
