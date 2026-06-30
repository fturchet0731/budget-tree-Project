import 'app_localizations.dart';

/// The predetermined budget questionnaire. Answers help the AI coach estimate
/// realistic amounts for expense categories the user left blank (for example a
/// food budget shaped by household size and dining habits). Keys are stable;
/// only the shown text is localized, mirroring `preset_labels.dart`.

class SurveyOption {
  final String key;
  final String Function(AppLocalizations) label;
  const SurveyOption(this.key, this.label);
}

class SurveyQuestion {
  final String key;
  final String Function(AppLocalizations) prompt;
  final List<SurveyOption> options;
  const SurveyQuestion(this.key, this.prompt, this.options);
}

List<SurveyQuestion> budgetSurveyQuestions() => [
  SurveyQuestion('household', (l) => l.surveyHousehold, [
    SurveyOption('justMe', (l) => l.surveyHouseholdJustMe),
    SurveyOption('two', (l) => l.surveyHouseholdTwo),
    SurveyOption('threeFour', (l) => l.surveyHouseholdThreeFour),
    SurveyOption('fivePlus', (l) => l.surveyHouseholdFivePlus),
  ]),
  SurveyQuestion('dining', (l) => l.surveyDining, [
    SurveyOption('rarely', (l) => l.surveyDiningRarely),
    SurveyOption('sometimes', (l) => l.surveyDiningSometimes),
    SurveyOption('often', (l) => l.surveyDiningOften),
  ]),
  SurveyQuestion('housing', (l) => l.surveyHousing, [
    SurveyOption('rent', (l) => l.surveyHousingRent),
    SurveyOption('own', (l) => l.surveyHousingOwn),
    SurveyOption('family', (l) => l.surveyHousingFamily),
  ]),
  SurveyQuestion('commute', (l) => l.surveyCommute, [
    SurveyOption('car', (l) => l.surveyCommuteCar),
    SurveyOption('transit', (l) => l.surveyCommuteTransit),
    SurveyOption('active', (l) => l.surveyCommuteActive),
    SurveyOption('remote', (l) => l.surveyCommuteRemote),
  ]),
  SurveyQuestion('priority', (l) => l.surveyPriority, [
    SurveyOption('save', (l) => l.surveyPrioritySave),
    SurveyOption('balanced', (l) => l.surveyPriorityBalanced),
    SurveyOption('enjoy', (l) => l.surveyPriorityEnjoy),
  ]),
  SurveyQuestion('debt', (l) => l.surveyDebt, [
    SurveyOption('none', (l) => l.surveyDebtNone),
    SurveyOption('some', (l) => l.surveyDebtSome),
    SurveyOption('lots', (l) => l.surveyDebtLots),
  ]),
];
