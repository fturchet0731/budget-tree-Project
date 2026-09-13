import 'app_localizations.dart';

/// The budget questionnaire. Answers help the AI coach estimate realistic
/// amounts for expense categories the user left blank, and shape how it weights
/// the split. Keys are stable; only the shown text is localized, mirroring
/// `preset_labels.dart`.
///
/// The bank holds ~20 questions but a given user only sees the ones that apply
/// to them: [SurveyQuestion.visibleIf] gates the follow-ups on earlier answers,
/// so someone with no children never gets asked about childcare and a renter is
/// never asked about property upkeep. A typical run is 12 to 15 questions.

class SurveyOption {
  final String key;
  final String Function(AppLocalizations) label;
  const SurveyOption(this.key, this.label);
}

class SurveyQuestion {
  final String key;
  final String Function(AppLocalizations) prompt;
  final List<SurveyOption> options;

  /// Whether this question applies, given what's been answered so far. Null
  /// means it's always asked.
  final bool Function(Map<String, String> answers)? visibleIf;

  const SurveyQuestion(this.key, this.prompt, this.options, {this.visibleIf});
}

/// Every question in the bank, in the order they'd be asked.
List<SurveyQuestion> budgetSurveyQuestions() => [
  // ── Who and where: the two biggest drivers of every household number ──
  SurveyQuestion('household', (l) => l.surveyHousehold, [
    SurveyOption('justMe', (l) => l.surveyHouseholdJustMe),
    SurveyOption('two', (l) => l.surveyHouseholdTwo),
    SurveyOption('threeFour', (l) => l.surveyHouseholdThreeFour),
    SurveyOption('fivePlus', (l) => l.surveyHouseholdFivePlus),
  ]),
  SurveyQuestion('kids', (l) => l.surveyKids, [
    SurveyOption('none', (l) => l.surveyKidsNone),
    SurveyOption('one', (l) => l.surveyKidsOne),
    SurveyOption('twoThree', (l) => l.surveyKidsTwoThree),
    SurveyOption('fourPlus', (l) => l.surveyKidsFourPlus),
  ]),
  SurveyQuestion(
    'childcare',
    (l) => l.surveyChildcare,
    [
      SurveyOption('daycare', (l) => l.surveyChildcareDaycare),
      SurveyOption('school', (l) => l.surveyChildcareSchool),
      SurveyOption('family', (l) => l.surveyChildcareFamily),
      SurveyOption('none', (l) => l.surveyChildcareNone),
    ],
    visibleIf: (a) => a['kids'] != null && a['kids'] != 'none',
  ),
  SurveyQuestion('housing', (l) => l.surveyHousing, [
    SurveyOption('rent', (l) => l.surveyHousingRent),
    SurveyOption('mortgage', (l) => l.surveyHousingMortgage),
    SurveyOption('owned', (l) => l.surveyHousingOwned),
    SurveyOption('family', (l) => l.surveyHousingFamily),
  ]),
  SurveyQuestion(
    'rentShare',
    (l) => l.surveyRentShare,
    [
      SurveyOption('alone', (l) => l.surveyRentShareAlone),
      SurveyOption('split', (l) => l.surveyRentShareSplit),
    ],
    visibleIf: (a) => a['housing'] == 'rent',
  ),
  SurveyQuestion(
    'homeUpkeep',
    (l) => l.surveyHomeUpkeep,
    [
      SurveyOption('included', (l) => l.surveyHomeUpkeepIncluded),
      SurveyOption('separate', (l) => l.surveyHomeUpkeepSeparate),
      SurveyOption('unsure', (l) => l.surveyHomeUpkeepUnsure),
    ],
    visibleIf: (a) =>
        a['housing'] == 'mortgage' || a['housing'] == 'owned',
  ),

  // ── Getting around ──
  SurveyQuestion('commute', (l) => l.surveyCommute, [
    SurveyOption('car', (l) => l.surveyCommuteCar),
    SurveyOption('transit', (l) => l.surveyCommuteTransit),
    SurveyOption('active', (l) => l.surveyCommuteActive),
    SurveyOption('remote', (l) => l.surveyCommuteRemote),
  ]),
  SurveyQuestion(
    'carCosts',
    (l) => l.surveyCarCosts,
    [
      SurveyOption('paying', (l) => l.surveyCarCostsPaying),
      SurveyOption('ownedOld', (l) => l.surveyCarCostsOwned),
      SurveyOption('shared', (l) => l.surveyCarCostsShared),
    ],
    visibleIf: (a) => a['commute'] == 'car',
  ),

  // ── Day to day spending ──
  SurveyQuestion('dining', (l) => l.surveyDining, [
    SurveyOption('rarely', (l) => l.surveyDiningRarely),
    SurveyOption('sometimes', (l) => l.surveyDiningSometimes),
    SurveyOption('often', (l) => l.surveyDiningOften),
  ]),
  SurveyQuestion('groceries', (l) => l.surveyGroceries, [
    SurveyOption('budget', (l) => l.surveyGroceriesBudget),
    SurveyOption('middle', (l) => l.surveyGroceriesMiddle),
    SurveyOption('premium', (l) => l.surveyGroceriesPremium),
  ]),
  SurveyQuestion('subscriptions', (l) => l.surveySubscriptions, [
    SurveyOption('none', (l) => l.surveySubscriptionsNone),
    SurveyOption('few', (l) => l.surveySubscriptionsFew),
    SurveyOption('many', (l) => l.surveySubscriptionsMany),
  ]),
  SurveyQuestion('pets', (l) => l.surveyPets, [
    SurveyOption('none', (l) => l.surveyPetsNone),
    SurveyOption('one', (l) => l.surveyPetsOne),
    SurveyOption('several', (l) => l.surveyPetsSeveral),
  ]),
  SurveyQuestion(
    'petCosts',
    (l) => l.surveyPetCosts,
    [
      SurveyOption('basic', (l) => l.surveyPetCostsBasic),
      SurveyOption('regular', (l) => l.surveyPetCostsRegular),
      SurveyOption('medical', (l) => l.surveyPetCostsMedical),
    ],
    visibleIf: (a) => a['pets'] != null && a['pets'] != 'none',
  ),
  SurveyQuestion(
    'healthCosts',
    (l) => l.surveyHealth,
    [
      SurveyOption('minimal', (l) => l.surveyHealthMinimal),
      SurveyOption('regular', (l) => l.surveyHealthRegular),
      SurveyOption('ongoing', (l) => l.surveyHealthOngoing),
    ],
    // Only worth asking once the household is big enough for it to move the
    // numbers, or there are children in it.
    visibleIf: (a) =>
        (a['kids'] != null && a['kids'] != 'none') ||
        a['household'] == 'threeFour' ||
        a['household'] == 'fivePlus',
  ),

  // ── Income shape ──
  SurveyQuestion('stability', (l) => l.surveyStability, [
    SurveyOption('steady', (l) => l.surveyStabilitySteady),
    SurveyOption('varies', (l) => l.surveyStabilityVaries),
    SurveyOption('unpredictable', (l) => l.surveyStabilityUnpredictable),
  ]),
  SurveyQuestion(
    'incomeFloor',
    (l) => l.surveyIncomeFloor,
    [
      SurveyOption('close', (l) => l.surveyIncomeFloorClose),
      SurveyOption('some', (l) => l.surveyIncomeFloorSome),
      SurveyOption('wide', (l) => l.surveyIncomeFloorWide),
    ],
    visibleIf: (a) =>
        a['stability'] == 'varies' || a['stability'] == 'unpredictable',
  ),

  // ── Debt and cushion ──
  SurveyQuestion('debt', (l) => l.surveyDebt, [
    SurveyOption('none', (l) => l.surveyDebtNone),
    SurveyOption('some', (l) => l.surveyDebtSome),
    SurveyOption('lots', (l) => l.surveyDebtLots),
  ]),
  SurveyQuestion(
    'debtType',
    (l) => l.surveyDebtType,
    [
      SurveyOption('cards', (l) => l.surveyDebtTypeCards),
      SurveyOption('student', (l) => l.surveyDebtTypeStudent),
      SurveyOption('vehicle', (l) => l.surveyDebtTypeVehicle),
      SurveyOption('mixed', (l) => l.surveyDebtTypeMixed),
    ],
    visibleIf: (a) => a['debt'] != null && a['debt'] != 'none',
  ),
  SurveyQuestion('emergencyFund', (l) => l.surveyEmergency, [
    SurveyOption('none', (l) => l.surveyEmergencyNone),
    SurveyOption('under1', (l) => l.surveyEmergencyUnderOne),
    SurveyOption('oneToThree', (l) => l.surveyEmergencyOneToThree),
    SurveyOption('threePlus', (l) => l.surveyEmergencyThreePlus),
  ]),

  // ── What they want out of it ──
  SurveyQuestion('budgetFor', (l) => l.surveyBudgetFor, [
    SurveyOption('cushion', (l) => l.surveyBudgetForCushion),
    SurveyOption('debt', (l) => l.surveyBudgetForDebt),
    SurveyOption('bigGoal', (l) => l.surveyBudgetForBigGoal),
    SurveyOption('control', (l) => l.surveyBudgetForControl),
  ]),
  SurveyQuestion('priority', (l) => l.surveyPriority, [
    SurveyOption('save', (l) => l.surveyPrioritySave),
    SurveyOption('balanced', (l) => l.surveyPriorityBalanced),
    SurveyOption('enjoy', (l) => l.surveyPriorityEnjoy),
  ]),
];

/// The questions that actually apply, given [answers] so far. This is what the
/// step walks through and what gets sent to the coach, so a follow-up whose
/// trigger was later changed (children, then back to none) drops out of both.
List<SurveyQuestion> visibleSurveyQuestions(Map<String, String> answers) =>
    budgetSurveyQuestions()
        .where((q) => q.visibleIf == null || q.visibleIf!(answers))
        .toList();
