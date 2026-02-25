import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// The name of the application
  ///
  /// In pt, this message translates to:
  /// **'Imperium'**
  String get appName;

  /// No description provided for @welcomeMessage.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao Imperium'**
  String get welcomeMessage;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu controle financeiro pessoal'**
  String get welcomeSubtitle;

  /// No description provided for @onboardingTitle1.
  ///
  /// In pt, this message translates to:
  /// **'Controle Total'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDescription1.
  ///
  /// In pt, this message translates to:
  /// **'Tenha controle completo das suas finanças em um só lugar'**
  String get onboardingDescription1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In pt, this message translates to:
  /// **'Simples e Elegante'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDescription2.
  ///
  /// In pt, this message translates to:
  /// **'Interface intuitiva para gerenciar receitas e despesas'**
  String get onboardingDescription2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In pt, this message translates to:
  /// **'Alcance seus Objetivos'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDescription3.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe seu progresso e conquiste suas metas financeiras'**
  String get onboardingDescription3;

  /// No description provided for @getStarted.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get skip;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get error;

  /// No description provided for @success.
  ///
  /// In pt, this message translates to:
  /// **'Sucesso'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retry;

  /// No description provided for @homeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get homeTitle;

  /// No description provided for @totalBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Total'**
  String get totalBalance;

  /// No description provided for @monthSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do Mês'**
  String get monthSummary;

  /// No description provided for @recentTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Transações Recentes'**
  String get recentTransactions;

  /// No description provided for @seeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas'**
  String get seeAll;

  /// No description provided for @noTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma transação encontrada'**
  String get noTransactions;

  /// No description provided for @noTransactionsHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicione sua primeira transação tocando no botão +'**
  String get noTransactionsHint;

  /// No description provided for @income.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get expense;

  /// No description provided for @incomes.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get incomes;

  /// No description provided for @expenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get expenses;

  /// No description provided for @addTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Transação'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Editar Transação'**
  String get editTransaction;

  /// No description provided for @transactionType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get transactionType;

  /// No description provided for @transactionValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get transactionValue;

  /// No description provided for @transactionDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get transactionDescription;

  /// No description provided for @transactionCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get transactionCategory;

  /// No description provided for @transactionDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get transactionDate;

  /// No description provided for @transactionAdded.
  ///
  /// In pt, this message translates to:
  /// **'Transação adicionada com sucesso'**
  String get transactionAdded;

  /// No description provided for @transactionUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Transação atualizada com sucesso'**
  String get transactionUpdated;

  /// No description provided for @transactionDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Transação excluída com sucesso'**
  String get transactionDeleted;

  /// No description provided for @deleteTransactionConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir esta transação?'**
  String get deleteTransactionConfirm;

  /// No description provided for @categoryFood.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In pt, this message translates to:
  /// **'Transporte'**
  String get categoryTransport;

  /// No description provided for @categoryHousing.
  ///
  /// In pt, this message translates to:
  /// **'Moradia'**
  String get categoryHousing;

  /// No description provided for @categoryLeisure.
  ///
  /// In pt, this message translates to:
  /// **'Lazer'**
  String get categoryLeisure;

  /// No description provided for @categoryHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get categoryHealth;

  /// No description provided for @categoryEducation.
  ///
  /// In pt, this message translates to:
  /// **'Educação'**
  String get categoryEducation;

  /// No description provided for @categorySalary.
  ///
  /// In pt, this message translates to:
  /// **'Salário'**
  String get categorySalary;

  /// No description provided for @categoryFreelance.
  ///
  /// In pt, this message translates to:
  /// **'Freelance'**
  String get categoryFreelance;

  /// No description provided for @categoryOther.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get categoryOther;

  /// No description provided for @transactionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transações'**
  String get transactionsTitle;

  /// No description provided for @debtsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dívidas'**
  String get debtsTitle;

  /// No description provided for @filterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get filterAll;

  /// No description provided for @filterCurrentMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este Mês'**
  String get filterCurrentMonth;

  /// No description provided for @filterLast7Days.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 7 dias'**
  String get filterLast7Days;

  /// No description provided for @filterCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get filterCustom;

  /// No description provided for @filterByType.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por tipo'**
  String get filterByType;

  /// No description provided for @sortByDate.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por data'**
  String get sortByDate;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Escuro'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Claro'**
  String get lightMode;

  /// No description provided for @language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @about.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get about;

  /// No description provided for @version.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get version;

  /// No description provided for @aboutApp.
  ///
  /// In pt, this message translates to:
  /// **'Sobre o App'**
  String get aboutApp;

  /// No description provided for @aboutDescription.
  ///
  /// In pt, this message translates to:
  /// **'Imperium é seu aplicativo de finanças pessoais, projetado para ajudá-lo a controlar suas receitas e despesas de forma simples e elegante.'**
  String get aboutDescription;

  /// No description provided for @validationRequired.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get validationRequired;

  /// No description provided for @validationInvalidValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido'**
  String get validationInvalidValue;

  /// No description provided for @validationMinValue.
  ///
  /// In pt, this message translates to:
  /// **'O valor deve ser maior que zero'**
  String get validationMinValue;

  /// No description provided for @validationSelectCategory.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma categoria'**
  String get validationSelectCategory;

  /// No description provided for @today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get tomorrow;

  /// No description provided for @scheduleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Agenda'**
  String get scheduleTitle;

  /// No description provided for @noSchedules.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum agendamento'**
  String get noSchedules;

  /// No description provided for @noSchedulesHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque no + para adicionar um agendamento'**
  String get noSchedulesHint;

  /// No description provided for @addSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Agendamento'**
  String get addSchedule;

  /// No description provided for @scheduleTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get scheduleTime;

  /// No description provided for @scheduleDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get scheduleDescription;

  /// No description provided for @scheduleCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria (opcional)'**
  String get scheduleCategory;

  /// No description provided for @scheduleReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete'**
  String get scheduleReminder;

  /// No description provided for @scheduleAdded.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento criado com sucesso'**
  String get scheduleAdded;

  /// No description provided for @scheduleUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento atualizado'**
  String get scheduleUpdated;

  /// No description provided for @scheduleDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento excluído'**
  String get scheduleDeleted;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
