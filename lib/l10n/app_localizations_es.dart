// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get retry => 'Reintentar';

  @override
  String get close => 'Cerrar';

  @override
  String get next => 'Siguiente';

  @override
  String get friends => 'Amigos';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elige tu idioma';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get dashboardChooseBranch => 'Elige una rama';

  @override
  String get dashboardCreate => 'Crear';

  @override
  String get dashboardCreateSub => 'Nuevo presupuesto';

  @override
  String get dashboardModify => 'Modificar';

  @override
  String get dashboardModifySub => 'Tu bosque';

  @override
  String get dashboardGoals => 'Metas';

  @override
  String get dashboardGoalsSub => 'Metas de ahorro';

  @override
  String get dashboardSettings => 'Ajustes';

  @override
  String get dashboardSettingsSub => 'Preferencias';

  @override
  String get dashboardBackToGround => 'Volver al suelo';

  @override
  String get loginWelcomeBack => 'Bienvenido de nuevo a tu arboleda';

  @override
  String get loginPlantForest => 'Planta tu bosque en la nube';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get usernameHelper =>
      'Cómo te encuentran tus amigos — 3 a 20 letras, números o _';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get newHereCreate => '¿Nuevo aquí? Crea una cuenta';

  @override
  String get haveAccountSignIn => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get enterEmail => 'Introduce tu correo electrónico';

  @override
  String get enterValidEmail => 'Introduce un correo electrónico válido';

  @override
  String get passwordTooShort => 'Al menos 6 caracteres';

  @override
  String get accountCreatedConfirm =>
      'Cuenta creada. Revisa tu correo para confirmar y luego inicia sesión.';

  @override
  String get somethingWentWrong => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get onboardingDisplayNameLabel => 'Nombre visible (opcional)';

  @override
  String get onboardingDisplayNameHelper =>
      'Se muestra a tus amigos en lugar de @usuario';

  @override
  String get onboardingUsernameHelper => '3 a 20 letras, números o _';

  @override
  String get onboardingEnterForest => 'Entrar al bosque';

  @override
  String get onboardingAcornWelcome =>
      '¡Hola, soy Acorn! 🌰 Bienvenido a Budget Tree. Elige un nombre de usuario para terminar de configurar — así te encuentran tus amigos, pero puedes hacer crecer tu bosque con o sin ellos.';

  @override
  String get onboardingAcornBusy => 'Plantando tu cuenta… ¡un momento! 🌱';

  @override
  String get onboardingAcornError =>
      'Mmm, no funcionó — ¡probemos otro nombre!';

  @override
  String get chooseUsername => 'Elige un nombre de usuario';

  @override
  String get usernameRule => '3 a 20 letras, números o guion bajo';

  @override
  String get usernameTaken =>
      'Ese nombre de usuario ya está en uso. Prueba con otro.';

  @override
  String get onboardingSaveError =>
      'No se pudo guardar tu perfil. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get add => 'Añadir';

  @override
  String get accept => 'Aceptar';

  @override
  String get decline => 'Rechazar';

  @override
  String get completedCheck => 'Completado ✓';

  @override
  String get featured => 'DESTACADO';

  @override
  String get myBudgets => 'Mis presupuestos';

  @override
  String get noBudgetsTitle => 'Aún no hay presupuestos guardados';

  @override
  String get noBudgetsBody => 'Crea uno desde el panel';

  @override
  String noSharedGoalsYet(String name) {
    return '$name aún no ha compartido ninguna meta.';
  }

  @override
  String percentThere(int pct) {
    return '$pct% alcanzado';
  }

  @override
  String get friendsNeedAccountTitle => 'Los amigos requieren una cuenta';

  @override
  String get friendsNeedAccountBody =>
      'Inicia sesión con conexión a Internet para añadir amigos y compartir metas.';

  @override
  String get couldntLoadFriends => 'No se pudieron cargar los amigos';

  @override
  String get friendsTablesMissing =>
      'Las tablas de amigos aún no están configuradas. Aplica la migración de la base de datos con `supabase db push` y vuelve a intentarlo.';

  @override
  String get couldntReachFriends =>
      'No se pudo conectar con los amigos. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String requestSentTo(String username) {
    return 'Solicitud enviada a @$username';
  }

  @override
  String youAreUsername(String username) {
    return 'Eres @$username';
  }

  @override
  String get howFriendsSeeStatus => 'Cómo ven tu estado tus amigos:';

  @override
  String get addAFriend => 'Añadir un amigo';

  @override
  String get searchByUsername => 'Buscar por nombre de usuario';

  @override
  String get requests => 'Solicitudes';

  @override
  String get noFriendsYet =>
      'Aún no tienes amigos: añade a alguien por su nombre de usuario.';

  @override
  String sharedGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metas compartidas',
      one: '1 meta compartida',
      zero: 'ninguna meta compartida',
    );
    return '$_temp0';
  }

  @override
  String get pinWhichGoal => '¿Qué meta fijar?';

  @override
  String get shareGoalFirstToPin =>
      'Comparte primero una meta con amigos para fijarla como tu estado.';

  @override
  String get statusModeBest => 'Mejor meta';

  @override
  String get statusModeAverage => 'Promedio de metas';

  @override
  String get statusModeWorst => 'Peor meta';

  @override
  String get statusModeGoal => 'Una meta elegida';

  @override
  String get groveTitle => 'La Arboleda';

  @override
  String get loadingEllipsis => 'Cargando…';

  @override
  String get plantAGoal => 'Plantar una meta';

  @override
  String get goalReached => '¡Meta alcanzada!';

  @override
  String goalsGrowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metas están creciendo',
      one: '1 meta está creciendo',
    );
    return '$_temp0';
  }

  @override
  String completedFilter(int count) {
    return 'Completadas · $count';
  }

  @override
  String savingStreakWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'racha de ahorro de $count semanas',
      one: 'racha de ahorro de 1 semana',
    );
    return '$_temp0';
  }

  @override
  String get startSavingStreak => 'Empieza una racha de ahorro';

  @override
  String get streakAtRisk =>
      'Añade a una meta esta semana para mantenerla viva';

  @override
  String streakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return 'Mejor: $_temp0 · ¡bien hecho!';
  }

  @override
  String get depositEachWeek => 'Deposita cada semana para crear una racha';

  @override
  String monthThisAmount(String amount) {
    return '$amount este mes';
  }

  @override
  String monthVsLastUp(int pct) {
    return '+$pct% vs el mes pasado';
  }

  @override
  String monthVsLastDown(int pct) {
    return '$pct% vs el mes pasado';
  }

  @override
  String get noSaplingsTitle => 'Aún no hay arbolitos';

  @override
  String get noSaplingsBody =>
      'Planta una meta y mírala crecer a medida que ahorras para ella.';

  @override
  String get plantFirstSapling => 'Planta tu primer arbolito';

  @override
  String get noSaplingsCategoryTitle =>
      'Aún no hay arbolitos en esta categoría';

  @override
  String get noSaplingsCategoryBody =>
      'Planta una meta en esta categoría o quita el filtro para ver todos los arbolitos.';

  @override
  String get showAll => 'Mostrar todo';

  @override
  String get shareThisGoalTitle => '¿Compartir esta meta?';

  @override
  String get shareThisGoalBody =>
      '¿Quieres que tus amigos vean esta meta y su planta en su lista de amigos? Puedes cambiarlo en cualquier momento en la meta.';

  @override
  String get keepPrivate => 'Mantener privada';

  @override
  String get shareWithFriends => 'Compartir con amigos';

  @override
  String get newSapling => 'Nuevo arbolito';

  @override
  String get aboutThisGoal => 'Sobre esta meta';

  @override
  String get goalName => 'Nombre de la meta';

  @override
  String get goalNameHint => 'p. ej. Viaje a Japón';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get notesHint => '¿Por qué te importa esto?';

  @override
  String get howMuch => '¿Cuánto?';

  @override
  String get targetAmount => 'Cantidad objetivo';

  @override
  String get targetHint => 'p. ej. 3500';

  @override
  String get growForever => 'Crecer sin límite (sin objetivo)';

  @override
  String get growForeverDesc =>
      'El arbolito crece por niveles (Plántula → Roble antiguo) en lugar de tener un tope.';

  @override
  String get iconLabel => 'Icono';

  @override
  String get groupOptional => 'Grupo (opcional)';

  @override
  String get groupNote =>
      'Asignar un grupo tiñe este arbolito con el color del grupo.';

  @override
  String get plantASaplingTitle => 'Plantar un arbolito';

  @override
  String get plantASaplingSub =>
      'Una nueva meta comienza como una sola semilla';

  @override
  String get plantSapling => 'Plantar arbolito';

  @override
  String get delete => 'Eliminar';

  @override
  String get name => 'Nombre';

  @override
  String get featuredOnProfileSnack =>
      'Destacada en tu perfil: tus amigos la verán primero.';

  @override
  String get removedFromProfile => 'Quitada de tu perfil.';

  @override
  String get couldntUpdateProfile => 'No se pudo actualizar tu perfil.';

  @override
  String get waterTheSapling => 'Riega el arbolito';

  @override
  String depositToward(String name) {
    return 'Depositar para «$name»';
  }

  @override
  String get deposit => 'Depositar';

  @override
  String get withdraw => 'Retirar';

  @override
  String get goalReachedTitle => '¡Meta alcanzada!';

  @override
  String goalReachedMsg(String name) {
    return 'Tu arbolito «$name» ha crecido hasta ser un árbol maduro. ¡Bien hecho!';
  }

  @override
  String get newGrowthTitle => '¡Nuevo crecimiento!';

  @override
  String newGrowthMsg(String name, int tier, String tierName) {
    return '«$name» alcanzó el nivel $tier — $tierName.';
  }

  @override
  String get keepGrowing => 'Seguir creciendo';

  @override
  String get milestoneTitle => '¡Hito!';

  @override
  String milestoneMsg(String name, String stage, int pct) {
    return '«$name» creció hasta $stage ($pct%).';
  }

  @override
  String get nice => 'Genial';

  @override
  String get removeSaplingTitle => '¿Eliminar el arbolito?';

  @override
  String removeSaplingBody(String name) {
    return '«$name» se eliminará permanentemente de tu arboleda.';
  }

  @override
  String get editGoal => 'Editar meta';

  @override
  String get target => 'Objetivo';

  @override
  String get growForeverTiers =>
      'Crecer sin límite (sin objetivo, por niveles)';

  @override
  String get groupUpper => 'GRUPO';

  @override
  String get savedUpper => 'AHORRADO';

  @override
  String get tierUpper => 'NIVEL';

  @override
  String get targetUpper => 'OBJETIVO';

  @override
  String percentGrown(int pct) {
    return '$pct% crecido';
  }

  @override
  String get noCapKeepsGrowing => 'Sin tope · sigue creciendo';

  @override
  String get goalReachedShort => 'Meta alcanzada';

  @override
  String amountToGo(String amount) {
    return 'Faltan $amount';
  }

  @override
  String get visibleToFriends => 'Visible para amigos';

  @override
  String get privateOnlyYou => 'Privada — solo tú';

  @override
  String get featuredOnYourProfile => 'Destacada en tu perfil';

  @override
  String get featureOnYourProfile => 'Destacar en tu perfil';

  @override
  String get fundedByUpper => 'FINANCIADA POR';

  @override
  String get adjust => 'Ajustar';

  @override
  String get milestoneSeed => 'Semilla';

  @override
  String get milestoneMature => 'Maduro';

  @override
  String get edit => 'Editar';

  @override
  String get walkThroughForest => 'Recorre tu bosque';

  @override
  String get gridList => 'Lista en cuadrícula';

  @override
  String get removeTreeTitle => '¿Eliminar este árbol?';

  @override
  String removeTreeBody(String name) {
    return '«$name» se eliminará permanentemente de tu bosque.';
  }

  @override
  String get yourForest => 'Tu bosque';

  @override
  String budgetTreesPlanted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count árboles de presupuesto plantados',
      one: '1 árbol de presupuesto plantado',
    );
    return '$_temp0';
  }

  @override
  String get viewFullTree => 'Ver árbol completo';

  @override
  String get noTreesCategoryTitle => 'Aún no hay árboles en esta categoría';

  @override
  String get noTreesCategoryBody =>
      'Planta un nuevo árbol en esta categoría o quita el filtro para ver todo.';

  @override
  String get forestEmptyTitle => 'Tu bosque está vacío';

  @override
  String get forestEmptyBody =>
      'Planta tu primer árbol de presupuesto volviendo atrás y creando un presupuesto.';

  @override
  String get goPlantATree => 'Ir a plantar un árbol';

  @override
  String get editBudget => 'Editar presupuesto';

  @override
  String get budgetName => 'Nombre del presupuesto';

  @override
  String get categoryUpper => 'CATEGORÍA';

  @override
  String incomeAmount(String amount) {
    return 'Ingresos: $amount';
  }

  @override
  String overAmount(String amount) {
    return '⚠ Excedido: $amount';
  }

  @override
  String leftAmount(String amount) {
    return 'Restante: $amount';
  }

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get stepIncomeTitle => 'Fuentes de ingresos';

  @override
  String get stepExpensesTitle => 'Ramas de gastos';

  @override
  String get stepNamePayTitle => 'Nombre y calendario de pago';

  @override
  String get stepIncomeSub => '¿Qué alimenta tu árbol?';

  @override
  String get stepExpensesSub => '¿Hasta dónde llegan las ramas?';

  @override
  String get stepNamePaySub =>
      'Nombra tu árbol y define con qué frecuencia te pagan';

  @override
  String get vineSeed => 'Semilla';

  @override
  String get vineBranches => 'Ramas';

  @override
  String get vineRoots => 'Raíces';

  @override
  String get quickPick => 'Elección rápida';

  @override
  String get addASource => 'Añadir una fuente';

  @override
  String get sourceName => 'Nombre de la fuente';

  @override
  String get sourceNameHint => 'p. ej. Salario';

  @override
  String get amountDollar => 'Cantidad \$';

  @override
  String get rootsFeedingTree => 'Raíces que alimentan el árbol';

  @override
  String get totalMonthlyIncome => 'Ingresos mensuales totales';

  @override
  String get canopyMeter => 'Medidor de la copa';

  @override
  String allocatedAmount(String amount) {
    return 'Asignado: $amount';
  }

  @override
  String overByAmount(String amount) {
    return 'Excedido por $amount';
  }

  @override
  String remainingAmount(String amount) {
    return 'Restante: $amount';
  }

  @override
  String get pickABranch => 'Elige una rama';

  @override
  String get addABranch => 'Añadir una rama';

  @override
  String get categoryName => 'Nombre de la categoría';

  @override
  String get branchesReachingOut => 'Ramas que se extienden';

  @override
  String get nameYourTree => 'Nombra tu árbol';

  @override
  String get budgetNameHint => 'p. ej. Presupuesto de enero';

  @override
  String get payScheduleLabel => 'Calendario de pago';

  @override
  String get payFrequencyLabel => 'Frecuencia de pago';

  @override
  String get firstPayDate => 'Fecha del primer pago';

  @override
  String firstPayOn(String date) {
    return 'Primer pago: $date';
  }

  @override
  String get payScheduleInfo =>
      'Tu calendario de pago permite que el árbol de presupuesto procese los ciclos de pago y aporte dinero a tus metas vinculadas automáticamente.';

  @override
  String get plantMyBudgetTree => 'Plantar mi árbol de presupuesto';
}
