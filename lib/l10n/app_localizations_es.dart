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
  String get social => 'Social';

  @override
  String get profile => 'Perfil';

  @override
  String get bio => 'Biografía';

  @override
  String get bioHint => 'Cuéntales algo sobre ti a tus amigos';

  @override
  String get addABio => 'Añade una biografía';

  @override
  String get sharedGoals => 'Objetivos compartidos';

  @override
  String get shareGoalsToShowOnProfile =>
      'Los objetivos que compartas aparecerán aquí para que los vean tus amigos.';

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
      'Cómo te encuentran tus amigos. 3 a 20 letras, números o _';

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
      '¡Hola, soy Acorn! 🌰 Bienvenido a Budget Tree. Elige un nombre de usuario para terminar de configurar. Así te encuentran tus amigos, pero puedes hacer crecer tu bosque con o sin ellos.';

  @override
  String get onboardingAcornBusy => 'Plantando tu cuenta… ¡un momento! 🌱';

  @override
  String get onboardingAcornError => 'Mmm, no funcionó. ¡Probemos otro nombre!';

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
    return '«$name» alcanzó el nivel $tier, ahora un $tierName.';
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
  String get privateOnlyYou => 'Privada, solo para ti';

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

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get signOutQuestion => '¿Cerrar sesión?';

  @override
  String get signOutBody =>
      'Tu bosque está guardado en la nube: vuelve a iniciar sesión cuando quieras para recuperarlo.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get eraseAllTitle => '¿Borrar todos los datos?';

  @override
  String get eraseAllBody =>
      'Esto eliminará permanentemente cada árbol de presupuesto y cada meta. Tus preferencias se conservarán. Esto no se puede deshacer.';

  @override
  String get eraseEverything => 'Borrar todo';

  @override
  String get absolutelySure => '¿Estás totalmente seguro?';

  @override
  String get lastChanceBody =>
      'Última oportunidad. Después de esto, cada árbol y meta guardados desaparecerán.';

  @override
  String get keepMyData => 'Conservar mis datos';

  @override
  String get yesErase => 'Sí, borrar';

  @override
  String get appearanceUpper => 'APARIENCIA';

  @override
  String get textSize => 'Tamaño del texto';

  @override
  String get scaleCompact => 'Compacto';

  @override
  String get scaleDefault => 'Predeterminado';

  @override
  String get scaleLarge => 'Grande';

  @override
  String get themePalette => 'Paleta de tema';

  @override
  String get paletteForest => 'Bosque';

  @override
  String get paletteMidnight => 'Medianoche';

  @override
  String get paletteTwilight => 'Crepúsculo';

  @override
  String get motion => 'Animaciones';

  @override
  String get fullAnimations => 'Animaciones completas';

  @override
  String get fullAnimationsSub =>
      'Desactiva para pantallas más rápidas y con menos animación';

  @override
  String get soundHaptics => 'Sonido y vibración';

  @override
  String get feedbackCues => 'Señales de respuesta';

  @override
  String get feedbackCuesSub =>
      'Toques y sonidos al plantar, fijar metas y ahorrar';

  @override
  String get notificationsUpper => 'NOTIFICACIONES';

  @override
  String get guideUpper => 'GUÍA';

  @override
  String get replayTutorial => 'Repetir tutorial';

  @override
  String get replayTutorialSub => 'Deja que Acorn te guíe por la app de nuevo.';

  @override
  String get accountUpper => 'CUENTA';

  @override
  String get signedInAs => 'Sesión iniciada como';

  @override
  String get signOutSub => 'Tus datos siguen seguros en la nube.';

  @override
  String get unknown => 'Desconocido';

  @override
  String get dataUpper => 'DATOS';

  @override
  String get eraseAllData => 'Borrar todos los datos';

  @override
  String get eraseAllDataSub =>
      'Elimina cada árbol de presupuesto y meta guardados.';

  @override
  String get aboutUpper => 'ACERCA DE';

  @override
  String get builtWith => 'Hecho con';

  @override
  String get budgetWarnings => 'Avisos de presupuesto';

  @override
  String get budgetWarningsSub =>
      'Cuando un presupuesto se acerca o supera tus ingresos';

  @override
  String get streakReminders => 'Recordatorios de racha';

  @override
  String get streakRemindersSub =>
      'Un aviso diario para mantener viva tu racha de ahorro';

  @override
  String get remindMeAt => 'Recordarme a las';

  @override
  String get weeklySummary => 'Resumen semanal';

  @override
  String get weeklySummarySub => 'Un repaso semanal de tu progreso';

  @override
  String get dayLabel => 'Día';

  @override
  String get timeLabel => 'Hora';

  @override
  String get weekdayMon => 'Lunes';

  @override
  String get weekdayTue => 'Martes';

  @override
  String get weekdayWed => 'Miércoles';

  @override
  String get weekdayThu => 'Jueves';

  @override
  String get weekdayFri => 'Viernes';

  @override
  String get weekdaySat => 'Sábado';

  @override
  String get weekdaySun => 'Domingo';

  @override
  String get done => 'Listo';

  @override
  String get saveBudgetTreeQuestion => '¿Guardar el árbol de presupuesto?';

  @override
  String saveBudgetTreeBody(String name) {
    return 'Guarda «$name» en tu bosque. Puedes verlo y editarlo cuando quieras desde la hoja Modificar.';
  }

  @override
  String get groupOptionalUpper => 'GRUPO (OPCIONAL)';

  @override
  String get autoLinkBranches => 'Vincular ramas a metas automáticamente';

  @override
  String get autoLinkBranchesDesc =>
      'Asocia los nombres de gastos con los nombres de metas existentes. Las ramas vinculadas alimentan esas metas durante los ciclos de pago.';

  @override
  String autoLinkedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ramas vinculadas',
      one: '1 rama vinculada',
    );
    return '$_temp0 automáticamente a las metas coincidentes.';
  }

  @override
  String get treePlantedSnack => '¡Árbol plantado en tu bosque!';

  @override
  String get processPay => 'Procesar pago';

  @override
  String get saveMyTree => 'Guardar mi árbol';

  @override
  String get updateTree => 'Actualizar árbol';

  @override
  String get gardenersTips => 'Consejos del jardinero';

  @override
  String get gardenersTipsSub => 'Cómo asignar mejor tu dinero';

  @override
  String get tapALeaf => 'Toca una hoja para ver su presupuesto';

  @override
  String payProcessed(int periods, String amount, int goals, String when) {
    return '$periods período(s) de pago procesado(s) · $amount → $goals meta(s). Próximo pago $when.';
  }

  @override
  String noPayPeriods(String when) {
    return 'Aún no ha pasado ningún período de pago. Próximo pago $when.';
  }

  @override
  String get linkBranchToGoals => 'Vincular esta rama a metas';

  @override
  String selectGoalsBranch(String name) {
    return 'Selecciona las metas que apoya esta rama «$name».';
  }

  @override
  String get noGoalsPlanted => 'Aún no hay metas plantadas';

  @override
  String get createGoalComeBack =>
      'Crea una meta en la Arboleda y vuelve para vincularla.';

  @override
  String percentOfIncome(String pct) {
    return '$pct% de tus ingresos';
  }

  @override
  String get allocated => 'Asignado';

  @override
  String ofIncome(String amount) {
    return 'de $amount de ingresos';
  }

  @override
  String get linkedGoalsUpper => 'METAS VINCULADAS';

  @override
  String get linkEllipsis => 'Vincular…';

  @override
  String get notFundingGoals =>
      'Esta rama aún no financia ninguna meta. Toca «Vincular…» para conectarla con arbolitos de la Arboleda.';

  @override
  String get totalIncome => 'Ingresos totales';

  @override
  String overBudgetAmount(String amount) {
    return 'Excedido: $amount';
  }

  @override
  String unallocatedAmount(String amount) {
    return 'Sin asignar: $amount';
  }

  @override
  String get timeNow => 'ahora';

  @override
  String timeToday(String time) {
    return 'hoy $time';
  }

  @override
  String get timeTomorrow => 'mañana';

  @override
  String timeInDays(int count) {
    return 'en $count días';
  }

  @override
  String nextPayLine(String when) {
    return 'próximo pago $when';
  }

  @override
  String get todayShort => 'hoy';

  @override
  String onDate(String date) {
    return 'el $date';
  }

  @override
  String get stageSeed => 'Semilla';

  @override
  String get stageSprout => 'Brote';

  @override
  String get stageYoungSapling => 'Arbolito joven';

  @override
  String get stageSapling => 'Arbolito';

  @override
  String get stageGrowingTree => 'Árbol en crecimiento';

  @override
  String get stageMature => 'Maduro';

  @override
  String get tierSeedling => 'Plántula';

  @override
  String get tierSapling => 'Arbolito';

  @override
  String get tierYoungOak => 'Roble joven';

  @override
  String get tierMatureOak => 'Roble maduro';

  @override
  String get tierToweringOak => 'Roble imponente';

  @override
  String get tierAncientOak => 'Roble antiguo';

  @override
  String get badgesTitle => 'Insignias';

  @override
  String badgesEarned(int earned, int total) {
    return '$earned de $total obtenidas';
  }

  @override
  String get badgeUnlocked => '¡Insignia desbloqueada!';

  @override
  String get niceExcl => '¡Genial!';

  @override
  String badgeMessage(String title, String desc) {
    return '$title. $desc';
  }

  @override
  String get achFirstSproutTitle => 'Primer brote';

  @override
  String get achFirstSproutDesc => 'Planta tu primer árbol de presupuesto.';

  @override
  String get achFirstSaplingTitle => 'Primer arbolito';

  @override
  String get achFirstSaplingDesc => 'Crea tu primera meta de ahorro.';

  @override
  String get achFirstDropTitle => 'Primera gota';

  @override
  String get achFirstDropDesc => 'Haz tu primer depósito hacia una meta.';

  @override
  String get achOrchardKeeperTitle => 'Guardián del huerto';

  @override
  String get achOrchardKeeperDesc => 'Cuida tres metas a la vez.';

  @override
  String get achGreenThumbTitle => 'Mano verde';

  @override
  String get achGreenThumbDesc => 'Ahorra \$1,000 en tu arboleda.';

  @override
  String get achConsistentTitle => 'Constante';

  @override
  String get achConsistentDesc => 'Alcanza una racha de ahorro de 3 semanas.';

  @override
  String get achFirstHarvestTitle => 'Primera cosecha';

  @override
  String get achFirstHarvestDesc => 'Completa una meta de ahorro.';

  @override
  String get achDevotedTitle => 'Devoto';

  @override
  String get achDevotedDesc => 'Alcanza una racha de ahorro de 8 semanas.';

  @override
  String get achMightyOakTitle => 'Roble poderoso';

  @override
  String get achMightyOakDesc => 'Haz crecer una meta hasta el nivel 5 o más.';

  @override
  String get achOldGrowthTitle => 'Bosque antiguo';

  @override
  String get achOldGrowthDesc => 'Ahorra \$10,000 en tu arboleda.';

  @override
  String get sugAddIncomeTitle => 'Añade tus ingresos primero';

  @override
  String get sugAddIncomeReason =>
      'Un árbol necesita raíces. Añade una fuente de ingresos para que podamos sugerir cómo repartirla entre ramas y metas.';

  @override
  String get sugOverAllocTitle => 'Las ramas superan al tronco';

  @override
  String sugOverAllocReason(String amount) {
    return 'Has asignado $amount más de lo que ganas. Recorta una rama o dos para que el árbol pueda sostenerlas.';
  }

  @override
  String get sugIdleTitle => 'Pon a trabajar el dinero inactivo';

  @override
  String sugIdleReason(String amount, int pct) {
    return '$amount ($pct%) de tus ingresos aún no está asignado. Añade una rama de ahorro y vincúlala a una meta para que crezca en vez de perderse.';
  }

  @override
  String sugPruneTitle(String name) {
    return 'Podar «$name»';
  }

  @override
  String get sugPruneReason =>
      'Esta rama no recibe dinero. Finánciala o pódala para mantener tu árbol enfocado.';

  @override
  String sugHeavyTitle(String name) {
    return '«$name» es una rama pesada';
  }

  @override
  String sugHeavyReason(int pct) {
    return 'Se lleva el $pct% de tus ingresos. Si puedes recortarla, ese dinero podría alimentar una meta de ahorro.';
  }

  @override
  String get sugFedTitle => 'Tus metas se están alimentando';

  @override
  String sugFedReason(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ramas envían',
      one: '1 rama envía',
    );
    return '$_temp0 dinero a una meta en cada ciclo de pago. Sigue así. Así crecen los arbolitos.';
  }

  @override
  String get sugLinkTitle => 'Vincula una rama a una meta';

  @override
  String get sugLinkReason =>
      'Ninguna de tus ramas alimenta todavía una meta de ahorro. Vincular una significa que cada ciclo de pago riega un arbolito por ti automáticamente.';

  @override
  String get sugHealthyTitle => 'Árbol sano y equilibrado';

  @override
  String get sugHealthyReason =>
      'Tus ramas están bien proporcionadas y dentro de tus ingresos. Nada que cambiar. Solo sigue regando tus metas.';

  @override
  String get giconSavings => 'Ahorro';

  @override
  String get giconTravel => 'Viaje';

  @override
  String get giconVehicle => 'Vehículo';

  @override
  String get giconHome => 'Hogar';

  @override
  String get giconEducation => 'Educación';

  @override
  String get giconWedding => 'Boda';

  @override
  String get giconEmergency => 'Emergencia';

  @override
  String get giconTech => 'Tecnología';

  @override
  String get giconGift => 'Regalo';

  @override
  String get giconOther => 'Otro';

  @override
  String get expHousing => 'Vivienda';

  @override
  String get expFood => 'Comida';

  @override
  String get expTransport => 'Transporte';

  @override
  String get expSavings => 'Ahorro';

  @override
  String get expEntertainment => 'Entretenimiento';

  @override
  String get expSubscriptions => 'Suscripciones';

  @override
  String get expHealthcare => 'Salud';

  @override
  String get expPersonal => 'Personal';

  @override
  String get expOther => 'Otro';

  @override
  String get incSalary => 'Salario';

  @override
  String get incWages => 'Sueldo';

  @override
  String get incPartTime => 'Empleo a tiempo parcial';

  @override
  String get incFreelance => 'Trabajo independiente';

  @override
  String get incInvestments => 'Inversiones';

  @override
  String get incDividends => 'Dividendos';

  @override
  String get incRental => 'Ingresos por alquiler';

  @override
  String get incBusiness => 'Ingresos del negocio';

  @override
  String get incBenefits => 'Prestaciones del gobierno';

  @override
  String get incScholarship => 'Beca';

  @override
  String get incPension => 'Pensión';

  @override
  String get monJan => 'ene.';

  @override
  String get monFeb => 'feb.';

  @override
  String get monMar => 'mar.';

  @override
  String get monApr => 'abr.';

  @override
  String get monMay => 'may.';

  @override
  String get monJun => 'jun.';

  @override
  String get monJul => 'jul.';

  @override
  String get monAug => 'ago.';

  @override
  String get monSep => 'sep.';

  @override
  String get monOct => 'oct.';

  @override
  String get monNov => 'nov.';

  @override
  String get monDec => 'dic.';

  @override
  String budgetCardCounts(int expenses, int sources) {
    String _temp0 = intl.Intl.pluralLogic(
      expenses,
      locale: localeName,
      other: '$expenses gastos',
      one: '1 gasto',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sources,
      locale: localeName,
      other: '$sources fuentes',
      one: '1 fuente',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get tutIntro1 =>
      '¡Hola! Soy Acorn, tu pequeño guía aquí en Budget Tree.';

  @override
  String get tutIntro2 =>
      'En vez de solo contarte cómo funciona, lo haremos juntos. Probarás cada parte tú mismo mientras avanzamos.';

  @override
  String get tutIntro3 =>
      'Tómate tu tiempo; te espero en cada paso. ¿Listo? Primera parada, ¡el huerto del Presupuesto!';

  @override
  String get tutClosing1 =>
      '¡Y ese es todo el bosque! Toca el botón de info en cualquier pantalla y te explicaré esa parte otra vez.';

  @override
  String get tutClosing2 =>
      'Ahora hagamos crecer algo maravilloso juntos. ¡Nos vemos por ahí!';

  @override
  String get tutCreate1 =>
      'Aquí estamos. Esta es la pantalla Crear, donde plantas un árbol de presupuesto nuevecito.';

  @override
  String get tutCreate2 =>
      'Añadirás lo que ganas, luego a dónde va, y algunos detalles personales. Los pasos siguen la enredadera de arriba.';

  @override
  String get tutCreate3 =>
      '¡Define tu calendario de pago y mira cómo tu presupuesto se convierte en un árbol!';

  @override
  String get tutForest1 =>
      'Este es Tu bosque, donde cada presupuesto que has plantado crece junto.';

  @override
  String get tutForest2 =>
      'Cambia entre una vista de árbol frondosa y una cuadrícula ordenada arriba, y fíltralos por categoría.';

  @override
  String get tutForest3 =>
      'Toca cualquier árbol para cuidarlo: revisa el desglose, edítalo o quítalo.';

  @override
  String get tutGoals1 =>
      'Ahora estamos en La Arboleda, donde tus metas de ahorro brotan como pequeños arbolitos.';

  @override
  String get tutGoals2 =>
      'Fija una cantidad objetivo y luego riégala con depósitos a lo largo del tiempo.';

  @override
  String get tutGoals3 =>
      '¡Cada aporte ayuda a tu arbolito a acercarse un poco más a su plena floración!';

  @override
  String get tutSettings1 =>
      'Última parada: Ajustes, donde haces la app a tu gusto.';

  @override
  String get tutSettings2 =>
      'Cambia el tema entre Bosque, Medianoche y Crepúsculo, ajusta el tamaño del texto o reduce las animaciones.';

  @override
  String get tutSettings3 =>
      'Y puedes repetir todo este recorrido desde aquí cuando quieras.';

  @override
  String get tutOpenCreate => 'Abrir Crear →';

  @override
  String get tutOpenForest => 'Abrir el Bosque →';

  @override
  String get tutOpenGoals => 'Abrir la Arboleda →';

  @override
  String get tutOpenSettings => 'Abrir Ajustes →';

  @override
  String get tutTaskCreate1 =>
      '¡Plantemos tu primer árbol de presupuesto, juntos!';

  @override
  String get tutTaskCreate2 =>
      'Abriré la pantalla Crear y me quedaré junto a ti, guiando cada fase: la Semilla, las Ramas y las Raíces.';

  @override
  String get tutTaskCreate3 => '¡Toca abajo y pongamos manos a la obra!';

  @override
  String get tutTaskForest1 =>
      'Ahora paseemos por Tu bosque, donde crecen tus presupuestos.';

  @override
  String get tutTaskForest2 =>
      'Toca tu árbol para mirar dentro, y prueba el botón de árbol y cuadrícula de arriba.';

  @override
  String get tutTaskForest3 =>
      'Mira bien a tu alrededor y luego toca la flecha de atrás para volver conmigo.';

  @override
  String get tutTaskGoals1 =>
      '¡Hora de una meta de ahorro! Esta es La Arboleda.';

  @override
  String get tutTaskGoals2 =>
      'Toca el + para plantar un arbolito, ponle un nombre y un objetivo, y guárdalo.';

  @override
  String get tutTaskGoals3 => 'Luego vuelve a mí con la flecha. ¡Adelante!';

  @override
  String get tutTaskSettings1 =>
      'Última parada. Hagamos la app tuya, en Ajustes.';

  @override
  String get tutTaskSettings2 =>
      'Prueba a tocar un tema diferente y mira cómo todo el bosque cambia de color.';

  @override
  String get tutTaskSettings3 => 'Vuelve cuando estés contento con el aspecto.';

  @override
  String get tutSuccessCreate1 =>
      '¡Mira eso! ¡Tu primer árbol está plantado! 🌳';

  @override
  String get tutSuccessCreate2 =>
      'Maravillosamente hecho. Ese presupuesto ahora vive en tu bosque.';

  @override
  String get tutSuccessForest1 =>
      'Tu bosque va tomando forma. Cada presupuesto que creas planta otro árbol aquí.';

  @override
  String get tutSuccessGoals1 =>
      '¡Maravilloso! ¡Tu primer arbolito se eleva hacia el cielo! 🌱';

  @override
  String get tutSuccessGoals2 =>
      'Aliméntalo con depósitos y crecerá hacia tu objetivo.';

  @override
  String get tutSuccessSettings1 =>
      '¡Se ve genial! Puedes afinar todo eso en cualquier momento.';

  @override
  String get tutRetryCreate1 =>
      'Mmm, ¡aún no veo un árbol nuevo! ¿Quieres intentarlo otra vez?';

  @override
  String get tutRetryCreate2 =>
      'Añade un ingreso y un gasto, luego planta y guarda tu árbol. O salta este paso por ahora.';

  @override
  String get tutRetryGoals1 =>
      'Aún no hay ningún arbolito plantado. ¿Lo intentamos otra vez?';

  @override
  String get tutRetryGoals2 =>
      'Toca el + y guarda una meta, o salta este paso y vuelve más tarde.';

  @override
  String get tutSkipCreate1 =>
      '¡No pasa nada! Puedes plantar un presupuesto cuando quieras desde la hoja Crear.';

  @override
  String get tutSkipGoals1 =>
      '¡Está bien! Planta una meta cuando estés listo desde la hoja Metas.';

  @override
  String get tutStep0a =>
      '🌱 La fase de la Semilla. Cada árbol empieza por lo que lo alimenta: tus ingresos.';

  @override
  String get tutStep0b =>
      'Escribe una fuente como «Salario», introduce la cantidad y toca el + para añadirla.';

  @override
  String get tutStep0c =>
      'Añade cada forma en que ganas dinero. Cuando estés listo, toca Siguiente abajo.';

  @override
  String get tutStep1a =>
      '🌿 Las Ramas. Aquí es donde tu dinero se extiende: tus gastos.';

  @override
  String get tutStep1b =>
      'Elige una categoría, ponle nombre, fija una cantidad y añádela. Mira cuánto queda por asignar arriba.';

  @override
  String get tutStep1c =>
      'Añade tus gastos principales y luego toca Siguiente para fijar tus raíces.';

  @override
  String get tutStep2a => '🪵 Las Raíces: los detalles que afianzan tu árbol.';

  @override
  String get tutStep2b =>
      'Nombra tu presupuesto y elige tu calendario de pago, que es con qué frecuencia el dinero fluye a tus metas.';

  @override
  String get tutStep2c =>
      '¿Todo listo? ¡Toca «Plantar mi árbol de presupuesto» abajo para hacerlo crecer!';

  @override
  String get tutSaveTree1 =>
      'Mira cómo crece, ¡es tu presupuesto como un árbol vivo! 🌳';

  @override
  String get tutSaveTree2 =>
      'Toca «Guardar mi árbol» abajo a la derecha para plantarlo en tu bosque para siempre.';

  @override
  String get tourLetsGo => '¡Vamos!';

  @override
  String get tourSkipTour => 'Saltar recorrido';

  @override
  String get tourLetsGrow => '¡A crecer!';

  @override
  String get tourClose => 'Cerrar';

  @override
  String get tourTryAgain => 'Reintentar';

  @override
  String get tourSkipStep => 'Saltar paso';

  @override
  String get tourNextStop => 'Siguiente parada →';

  @override
  String get tourTapContinue => 'Toca para continuar';

  @override
  String get tourSkip => 'Saltar';

  @override
  String get tourTapFinish => 'Toca para terminar';

  @override
  String notifOverBudgetTitle(String name) {
    return '🌳 «$name» supera el presupuesto';
  }

  @override
  String notifOverBudgetMsg(String allocated, String income, String over) {
    return 'Has asignado $allocated de tus $income de ingresos, $over de más. Recorta una rama para volver al equilibrio.';
  }

  @override
  String notifFillingTitle(String name) {
    return '⚠️ «$name» se está llenando';
  }

  @override
  String notifFillingMsg(String allocated, String income, String remaining) {
    return 'Has asignado $allocated de $income. Solo quedan $remaining por presupuestar este ciclo.';
  }

  @override
  String notifStreakTitleActive(int count) {
    return '🔥 racha de $count semanas';
  }

  @override
  String get notifStreakTitleNone => '🌱 Empieza una racha';

  @override
  String notifStreakActive(int count) {
    return '¡Llevas una racha de ahorro de $count semanas! Añade a una meta hoy para mantenerla creciendo.';
  }

  @override
  String get notifStreakNone =>
      'Riega una meta hoy, aunque sea poco, para empezar una racha de ahorro.';

  @override
  String get notifWeeklyTitle => '📊 Tu semana en la arboleda';

  @override
  String get notifWeeklyNone =>
      'Aún no hay depósitos esta semana. Una pequeña cantidad mantiene tus arbolitos creciendo, y tu racha viva.';

  @override
  String notifWeeklyChange(String amount, String arrow, int pct) {
    return 'Esta semana ahorraste $amount ($arrow $pct% vs la semana pasada). ¡Sigue haciendo crecer tus metas!';
  }

  @override
  String notifWeeklyPlain(String amount) {
    return 'Esta semana ahorraste $amount. ¡Sigue haciendo crecer tus metas!';
  }

  @override
  String get gateErrorTitle => 'No se pudo completar la configuración';

  @override
  String get gateErrorBody =>
      'No pudimos conectar con el servidor para configurar tu cuenta. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get claimUsernameTitle => 'Elige un nombre de usuario';

  @override
  String get claimUsernameBody => 'Así te encuentran y te añaden tus amigos.';

  @override
  String get usernameHint => 'nombre de usuario';

  @override
  String get claimUsernameButton => 'Reservar nombre';

  @override
  String get usernameTakenShort => 'Ese nombre de usuario ya está en uso.';

  @override
  String get signedOut => 'Sesión cerrada 🌱';

  @override
  String get expenseBreakdownUpper => 'DESGLOSE DE GASTOS';

  @override
  String get categoryNameTripsHint => 'p. ej. Viajes';

  @override
  String get createButton => 'Crear';

  @override
  String get register => 'Registrarse';

  @override
  String get startButton => 'Empezar';

  @override
  String get swipeToWalk =>
      'Desliza para pasear · toca un árbol para ver detalles';

  @override
  String get tapForDetails => 'Toca para ver detalles';

  @override
  String get newCategoryTitle => 'Nueva categoría';

  @override
  String get newCategoryBody =>
      'Nombra tu categoría. Los árboles y arbolitos de esta categoría se teñirán con el color elegido.';

  @override
  String get colourUpper => 'COLOR';

  @override
  String get homeSlogan => 'Haz crecer tu bosque, haz crecer tus ahorros';

  @override
  String get newTreeInForest => '¡Un nuevo árbol crece en tu bosque!';

  @override
  String get deleteCategoryTitle => '¿Eliminar grupo?';

  @override
  String deleteCategoryBody(String name) {
    return '¿Eliminar el grupo «$name»? Los árboles y arbolitos que lo usan solo perderán su etiqueta de color.';
  }

  @override
  String get longPressToDeleteGroup =>
      'Mantén pulsado un grupo para eliminarlo';

  @override
  String sharedByName(String name) {
    return 'Compartido por $name';
  }

  @override
  String get savingsAndGoals => 'Ahorros y objetivos';

  @override
  String get stepPlanTitle => 'Plan inteligente';

  @override
  String get stepPlanSub => 'Deja que el coach reparta tus ingresos';

  @override
  String get vinePlan => 'Plan';

  @override
  String get yourExpenses => 'Tus gastos';

  @override
  String get describeYourBudget => 'Describe tu presupuesto';

  @override
  String get describeYourBudgetHint =>
      'Dile al coach cómo quieres manejar tu dinero. Por ejemplo, ahorrar mucho para un viaje, dejar algo para diversión, o cubrir primero lo esencial.';

  @override
  String get budgetIdeaSaveHard => 'Ahorrar lo máximo posible';

  @override
  String get budgetIdeaBalanced => 'Estilo de vida equilibrado';

  @override
  String get budgetIdeaEssentials => 'Cubrir primero lo esencial';

  @override
  String get budgetIdeaDebt => 'Pagar deudas rápido';

  @override
  String get amountOptionalLabel => 'Monto (opcional)';

  @override
  String get amountOptionalHint =>
      '¿No sabes cuánto? Déjalo en blanco y el coach decidirá.';

  @override
  String get pickAPlan => 'Elige un plan';

  @override
  String get regeneratePlans => 'Regenerar planes';

  @override
  String get setAmountsMyself => 'Definir los montos yo mismo';

  @override
  String get setAmounts => 'Definir montos';

  @override
  String get aiUnavailableManual =>
      'El coach no está disponible ahora, así que define tus montos aquí.';

  @override
  String get useTheseAmounts => 'Usar estos montos';

  @override
  String get useAiPlansInstead => 'Usar planes de IA en su lugar';

  @override
  String get allocationsReady => 'Asignación lista';

  @override
  String get thinkingUp => 'Preparando planes...';

  @override
  String get generatePlans => 'Generar planes con IA';

  @override
  String get tutStepPlanA =>
      'Ahora la parte divertida. Dime cómo quieres que sea tu presupuesto.';

  @override
  String get tutStepPlanB =>
      'Sugeriré algunas formas de repartir tus ingresos según lo que dijiste.';

  @override
  String get tutStepPlanC =>
      'Elige la que te guste, o ajusta los montos tú mismo.';

  @override
  String get fundFromBranchTitle => '¿Financiar este objetivo?';

  @override
  String get fundFromBranchBody =>
      'Vincula una rama del presupuesto para regar este objetivo automáticamente en cada pago.';

  @override
  String get notNow => 'Ahora no';

  @override
  String get targetDateLabel => 'Fecha objetivo';

  @override
  String get pickATargetDate => 'Elige una fecha objetivo';

  @override
  String get planWithAi => 'Planificar con IA';

  @override
  String get calculateMonthly => 'Calcular mensual';

  @override
  String recommendedMonthly(String amount) {
    return 'Ahorra $amount al mes para lograrlo';
  }

  @override
  String planMonthsLine(String amount, int months) {
    return '$amount al mes termina en unos $months meses';
  }

  @override
  String get alternativeDates => 'FECHAS ALTERNATIVAS';

  @override
  String get aiUnavailableSimple =>
      'El coach no está disponible, aquí tienes la cifra mensual simple.';

  @override
  String get reflectionWeeklyTitle => 'Tu semana en el bosque';

  @override
  String get reflectionMonthlyTitle => 'Tu mes en el bosque';

  @override
  String get notifReflectionTitle => 'Tu reflexión está lista';

  @override
  String get aiCoachUpper => 'COACH IA';

  @override
  String get aiCoach => 'Coach IA';

  @override
  String get aiCoachSub =>
      'Planes inteligentes de presupuesto y objetivos, más reflexiones semanales';

  @override
  String get aiCoachNeedsOnline =>
      'Inicia sesión y conéctate para usar el coach IA.';

  @override
  String get goalStepName => 'Nombre';

  @override
  String get goalStepAmount => 'Monto';

  @override
  String get aiPlanPromptTitle => '¿Quieres ayuda para planificar?';

  @override
  String get aiPlanPromptBody =>
      'El coach puede sugerir cuánto ahorrar cada mes y fechas que se ajusten a tus ingresos. O configúralo tú mismo.';

  @override
  String get setItUpMyself => 'Lo configuraré yo mismo';

  @override
  String get goalStepWhen => 'Plazo';

  @override
  String get timeframeNote =>
      '¿Cuándo quieres alcanzar esta meta? Daremos forma a un plan de riego en función de eso.';

  @override
  String get timeframeUncappedNote =>
      'Las metas sin límite no tienen fecha tope. Elige una fecha si quieres un objetivo, o sigue adelante.';

  @override
  String get wateringPlanTitle => 'Plan de riego';

  @override
  String get wateringPlanIntro =>
      'Elige con qué frecuencia y cuánto regar esta meta. Te recordaremos para que sigas al día.';

  @override
  String get remindToWaterTitle => 'Recordarme regar';

  @override
  String get remindToWaterSub =>
      'Recibe un aviso antes de cada riego, y un recordatorio el mismo día.';

  @override
  String planAboutMonths(int months) {
    return 'Unos $months meses para alcanzarla';
  }

  @override
  String get customWaterTitle => 'Personalizar';

  @override
  String get amountPerWatering => 'Cantidad por riego';

  @override
  String get cadenceWeekly => 'Semanal';

  @override
  String get cadenceBiweekly => 'Cada 2 semanas';

  @override
  String get cadenceMonthly => 'Mensual';

  @override
  String get cadenceEveryWeekly => 'cada semana';

  @override
  String get cadenceEveryBiweekly => 'cada 2 semanas';

  @override
  String get cadenceEveryMonthly => 'cada mes';

  @override
  String get wateringReminders => 'Recordatorios de riego';

  @override
  String get wateringRemindersSub =>
      'Recordatorios para regar tus metas a tiempo';

  @override
  String notifWaterDueTitle(String name) {
    return '💧 Hora de regar $name';
  }

  @override
  String notifWaterDueMsg(String name, String amount) {
    return 'Tu retoño $name necesita $amount. Riégalo para seguir al día.';
  }

  @override
  String notifWaterSoonTitle(String name) {
    return '🌱 Riego de $name próximo';
  }

  @override
  String notifWaterSoonMsg(String name, String amount) {
    return 'Aviso: $name necesita $amount en 2 días.';
  }

  @override
  String get stepSurveyTitle => 'Unas preguntas rápidas';

  @override
  String get stepSurveySub => 'Ayuda al coach a dimensionar tu presupuesto';

  @override
  String get vineSurvey => 'Encuesta';

  @override
  String get surveyIntroTitle => 'Cuéntanos sobre ti';

  @override
  String get surveyIntroBody =>
      'Responde unas preguntas rápidas y el coach estimará los montos de cualquier gasto que dejaste en blanco. Cada pregunta es opcional.';

  @override
  String get budgetNoteTitle => '¿Algo más? (opcional)';

  @override
  String get budgetNoteHint =>
      'Por ejemplo: quiero ahorrar mucho para una casa, o guardar algo para gustos.';

  @override
  String get leftoverGoalTitle => 'Haz crecer una meta con tu sobrante';

  @override
  String leftoverGoalBody(String amount) {
    return 'Te sobran $amount. Envíalos a una meta y se convierte en una rama que la financia cada ciclo de pago.';
  }

  @override
  String get growAGoalWithIt => 'Hacer crecer una meta';

  @override
  String get leftoverPickGoalTitle => 'Enviar el sobrante a';

  @override
  String get leftoverNewGoal => 'Crear una meta nueva';

  @override
  String get leftoverNewGoalTitle => 'Nombra tu meta';

  @override
  String get surveyHousehold => '¿Cuántas personas hay en tu hogar?';

  @override
  String get surveyHouseholdJustMe => 'Solo yo';

  @override
  String get surveyHouseholdTwo => 'Dos';

  @override
  String get surveyHouseholdThreeFour => '3 a 4';

  @override
  String get surveyHouseholdFivePlus => '5 o más';

  @override
  String get surveyDining => '¿Con qué frecuencia comes fuera?';

  @override
  String get surveyDiningRarely => 'Rara vez';

  @override
  String get surveyDiningSometimes => 'A veces';

  @override
  String get surveyDiningOften => 'A menudo';

  @override
  String get surveyHousing => '¿Cómo es tu vivienda?';

  @override
  String get surveyHousingRent => 'Alquilo';

  @override
  String get surveyHousingOwn => 'Soy propietario';

  @override
  String get surveyHousingFamily => 'Con familia';

  @override
  String get surveyCommute => '¿Cómo te desplazas?';

  @override
  String get surveyCommuteCar => 'Coche';

  @override
  String get surveyCommuteTransit => 'Transporte';

  @override
  String get surveyCommuteActive => 'Bici o a pie';

  @override
  String get surveyCommuteRemote => 'Trabajo desde casa';

  @override
  String get surveyPriority => '¿Qué importa más ahora?';

  @override
  String get surveyPrioritySave => 'Ahorrar mucho';

  @override
  String get surveyPriorityBalanced => 'Un equilibrio';

  @override
  String get surveyPriorityEnjoy => 'Disfrutar ahora';

  @override
  String get surveyDebt => '¿Pagos de deudas?';

  @override
  String get surveyDebtNone => 'Ninguno';

  @override
  String get surveyDebtSome => 'Algunos';

  @override
  String get surveyDebtLots => 'Muchos';

  @override
  String get tutStepSurveyA => 'Ahora unas preguntas rápidas sobre tu vida.';

  @override
  String get tutStepSurveyB =>
      'Tus respuestas me ayudan a estimar los gastos de los que no estabas seguro.';

  @override
  String get tutStepSurveyC =>
      'Responde lo que quieras, luego construiremos tus planes.';

  @override
  String get verifyTitle => 'Revisa tu correo';

  @override
  String verifyBody(String email) {
    return 'Enviamos un código de 6 dígitos a $email. Escríbelo abajo para confirmar tu cuenta.';
  }

  @override
  String get verifyCodeLabel => 'Código de verificación';

  @override
  String get enterCode => 'Escribe el código de 6 dígitos';

  @override
  String get verifyButton => 'Verificar correo';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String get codeResent => 'Te enviamos un código nuevo.';

  @override
  String get verifyBadCode =>
      'Ese código es incorrecto o caducó. Inténtalo de nuevo o reenvíalo.';

  @override
  String get loginExploreFirst => 'Pruébala primero, sin cuenta';

  @override
  String get pulseWaterTitle => 'Hora de regar';

  @override
  String pulseWaterBody(String name, String amount) {
    return 'Dale $amount a $name para que siga creciendo.';
  }

  @override
  String pulseWaterOverdueBody(String name) {
    return '$name se perdió su último riego. Un depósito rápido lo pone al día.';
  }

  @override
  String get pulseStreakAtRiskTitle => 'Racha en peligro';

  @override
  String pulseStreakAtRiskBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'racha de $count semanas',
      one: 'racha de 1 semana',
    );
    return 'Riega una meta antes de que termine la semana para mantener tu $_temp0.';
  }

  @override
  String get pulseStreakTitle => 'Racha de ahorro';

  @override
  String pulseStreakBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas seguidas.',
      one: '1 semana seguida.',
    );
    return '$_temp0 ¡Sigue así!';
  }

  @override
  String get pulsePlantTitle => 'Empieza aquí';

  @override
  String get pulsePlantBody =>
      'Planta tu primer árbol y mira crecer tu presupuesto.';

  @override
  String surveyProgress(int current, int total) {
    return 'Pregunta $current de $total';
  }

  @override
  String get surveyDoneTitle => 'Eso es todo';

  @override
  String get surveyDoneBody =>
      'Toca una respuesta para cambiarla o añade una nota para el coach abajo.';

  @override
  String get surveySkippedLabel => 'Omitida';

  @override
  String get guestUpgradeTitle => '¡Tu primer árbol está plantado!';

  @override
  String get guestUpgradeBody =>
      'Crea una cuenta gratuita y tu bosque quedará guardado en la nube, a salvo aunque cambies de teléfono. Todo lo que creaste te acompaña.';

  @override
  String get guestUpgradeLater => 'Quizás más tarde';

  @override
  String get payFreqWeekly => 'Semanal';

  @override
  String get payFreqBiWeekly => 'Cada 2 semanas';

  @override
  String get payFreqSemiMonthly => 'Dos veces al mes';

  @override
  String get payFreqMonthly => 'Mensual';

  @override
  String get budgetCycleTitle => '¿Cada cuánto haces tu presupuesto?';

  @override
  String get budgetCycleBody =>
      'Todo lo de abajo cuenta por ciclo. Un ingreso que llega con otro ritmo se convierte automáticamente.';

  @override
  String get incomeArrives => '¿Cada cuánto llega?';

  @override
  String approxEachCycle(String amount) {
    return '≈ $amount por ciclo';
  }

  @override
  String totalIncomeCycle(String cycle) {
    return 'Ingreso total ($cycle)';
  }
}
