class AppConstants {
  // Date picker configuration - disable manual entry globally
  static const bool disableDateManualEntry = true;
  // Table Management Page
  static const String tableManagementTitle = 'Tischverwaltung';
  static const String addTableTooltip = 'Neuen Tisch hinzufügen';
  static const String maxGuestsDisplay = 'Max. Gäste: ';
  static const String assignedGuestsCount = 'Zugewiesene Gäste (';
  static const String assignGuestsButtonText = 'Gäste zuweisen';
  static const String cancelButtonText = 'Stornieren';
  static const String tableTypePrefix = ' - ';
  static const String multipleGuestsAssignedFormat =
      ' Gäste wurden dem Tisch zugewiesen';

  // Table Types
  static const String tableTypeRound = 'rund';
  static const String tableTypeOval = 'oval';
  static const String tableTypeRectangular = 'rechteckig';
  static const String tableTypeSquare = 'quadratisch';

  // Dialog Titles
  static const String deleteTableTitle = 'Tisch löschen';
  static const String errorTitle = 'Fehler';

  // Dialog Messages
  static const String deleteTableConfirmation =
      'Möchten Sie diesen Tisch wirklich löschen?';

  // Dialog Buttons
  static const String deleteButton = 'Löschen';
  static const String cancelButton = 'Abbrechen';
  static const String okButton = 'OK';
  static const String saveButton = 'Speichern';

  // Form Labels
  static const String tableNumberLabel = 'Tischnummer';
  static const String maxGuestsLabel = 'Max. Gäste';
  static const String tableTypeLabel = 'Tischtyp';

  // Error Messages
  static const String loadDataError = 'Failed to load data: ';
  static const String enterTableNumberError =
      'Bitte geben Sie eine Tischnummer ein';
  static const String enterValidGuestsError =
      'Bitte geben Sie eine gültige Gästeanzahl ein';
  static const String tableNameExistsError =
      'Ein Tisch mit dieser Nummer existiert bereits.';
  static const String addTableError = 'Fehler beim Hinzufügen des Tisches: ';
  static const String updateTableError =
      'Fehler beim Aktualisieren des Tisches: ';
  static const String deleteTableError = 'Tisch konnte nicht gelöscht werden: ';
  static const String assignGuestError = 'Fehler beim Zuweisen: ';
  static const String maxCapacityWarning = 'Tischkapazität erreicht';

  // Success Messages
  static const String tableDeletedSuccess = 'Tisch erfolgreich gelöscht';
  static const String oneGuestAssignedSuccess =
      'Ein Gast wurde dem Tisch zugewiesen';
  static const String multipleGuestsAssignedSuccess =
      ' Gäste wurden dem Tisch zugewiesen';

  // Info Messages
  static const String noAvailableGuests =
      'Keine verfügbaren Gäste zum Zuweisen';
  static const String tableCapacityReached = 'Tischkapazität erreicht';
  static const String noTablesAvailable =
      'Kein Tisch verfügbar. Bitte fügen Sie einen Tisch über die Schaltfläche + hinzu.';

  // Guest Status
  static const String guestStatusConfirmed = 'Bestätigt';
  static const String guestStatusMaybe = 'Vielleicht';
  static const String guestStatusDeclined = 'Abgelehnt';

  // Section Titles
  static const String assignedGuestsTitle = 'Zugewiesene Gäste';
  static const String assignGuestTitle = 'Gäste zuweisen';
  static const String assignGuestButton = 'Gast zuweisen';

  // Asset Paths
  static const String tableManagementBackground =
      'assets/images/table_management/table_management.jpg';
  static const String tableIconCircle = 'assets/icons/circle.png';
  static const String tableIconOval = 'assets/icons/oval.png';
  static const String tableIconRectangle = 'assets/icons/rectangle.png';
  static const String tableIconSquare = 'assets/icons/square.png';

  // Gaestelist Page
  static const String gaestelistTitle = 'Gästeliste';
  static const String noGuestsMessage =
      'Keine Gäste vorhanden. Bitte fügen Sie Gäste mit dem + Button hinzu.';
  static const String tableManagementButtonLabel = 'Tischverwaltung';

  // Guest Status Labels
  static const String confirmedLabel = 'zugesagt:';
  static const String maybeLabel = 'vielleicht:';
  static const String declinedLabel = 'abgesagt:';
  static const String guestCountLabel = 'Anzahl';

  // Guest Management
  static const String addGuestError = 'Fehler beim Hinzufügen des Gastes:';
  static const String updateGuestStatusError = 'Error updating guest status: ';
  static const String loadGuestsError = 'Error loading guests: ';
  static const String deleteGuestError = 'Error deleting guest: ';

  // Guest Dialog
  static const String addGuestTitle = 'Gast hinzufügen';
  static const String editGuestTitle = 'Gast bearbeiten';
  static const String guestNameLabel = 'Name';
  static const String guestNameHint = 'Gastname eingeben';
  static const String addGuestButton = 'Hinzufügen';
  static const String updateGuestButton = 'Aktualisieren';

  // Guest Item
  static const String deleteGuestConfirmation =
      'Möchten Sie diesen Gast wirklich löschen?';
  static const String deleteGuestTitle = 'Gast löschen';

  // Image Assets
  static const String gaestelistBackground =
      'assets/images/gaestelist/gaesteliste.png';
  static const String appLogo = 'assets/images/logo/secrets-logo.jpg';

  // Sign In Screen
  static const String signInTitle = 'Willkommen';
  static const String signInButtonText = 'Anmelden';
  static const String signInSubtitle = 'Melden Sie sich an, um fortzufahren';
  static const String emailLabel = 'E-Mail';
  static const String passwordLabel = 'Passwort';
  static const String forgotPasswordLink = 'Passwort vergessen?';
  static const String rememberMeLabel = 'Anmeldedaten speichern';
  static const String noAccountText = 'Noch kein Konto?';
  static const String signUpLink = 'Bitte registrieren.';
  static const String welcomeBackMessage = 'Willkommen zurück!';

  // Sign In Error Messages
  static const String userNotFoundError =
      'Kein Konto mit dieser E-Mail vorhanden. Bitte registrieren Sie sich zuerst.';
  static const String wrongPasswordError =
      'Falsches Passwort. Bitte versuchen Sie es erneut oder nutzen Sie "Passwort vergessen".';
  static const String invalidEmailError =
      'Bitte geben Sie eine gültige E-Mail-Adresse ein.';
  static const String userDisabledError =
      'Dieses Konto wurde deaktiviert. Bitte kontaktieren Sie den Support.';
  static const String tooManyRequestsError =
      'Zu viele fehlgeschlagene Versuche. Bitte versuchen Sie es in einigen Minuten erneut.';
  static const String networkRequestFailedError =
      'Netzwerkfehler. Bitte überprüfen Sie Ihre Internetverbindung.';
  static const String operationNotAllowedError =
      'Diese Art der Anmeldung ist nicht aktiviert. Bitte kontaktieren Sie den Support.';
  static const String defaultSignInError = 'Anmeldung fehlgeschlagen: ';
  static const String unexpectedError =
      'Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';
  static const String emailValidationError =
      'Bitte geben Sie eine gültige E-Mail-Adresse ein';
  static const String emptyEmailError =
      'Bitte geben Sie Ihre E-Mail-Adresse ein';
  static const String emptyPasswordError = 'Bitte geben Sie Ihr Passwort ein';

  // Sign Up Screen
  static const String signUpTitle = 'Konto erstellen';
  static const String signUpSubtitle =
      'Bitte registrieren Sie sich, um fortzufahren';
  static const String addProfilePictureText = 'Profilbild hinzufügen';
  static const String changeProfilePictureText = 'Profilbild ändern';
  static const String nameLabel = 'Name';
  static const String confirmPasswordLabel = 'Passwort bestätigen';
  static const String registerButton = 'Registrieren';
  static const String haveAccountText = 'Bereits registriert?';
  static const String signInLink = 'Anmelden';

  // Sign Up Error Messages
  static const String emptyNameError = 'Bitte geben Sie Ihren Namen ein';
  static const String passwordLengthError =
      'Das Passwort muss mindestens 6 Zeichen lang sein';
  static const String passwordMismatchError =
      'Die Passwörter stimmen nicht überein';
  static const String emptyConfirmPasswordError =
      'Bitte bestätigen Sie Ihr Passwort';
  static const String emailAlreadyInUseError =
      'Ein Konto mit dieser E-Mail existiert bereits. Bitte melden Sie sich an.';
  static const String weakPasswordError =
      'Das Passwort ist zu schwach. Bitte verwenden Sie mindestens 6 Zeichen mit einer Mischung aus Buchstaben, Zahlen und Symbolen.';
  // static const String operationNotAllowedError = 'Diese Art der Anmeldung ist nicht aktiviert. Bitte kontaktieren Sie den Support.';
  static const String signUpFailedError = 'Registrierung fehlgeschlagen: ';

  // Forgot Password Screen
  static const String forgotPasswordTitle = 'Passwort zurücksetzen';
  static const String forgotPasswordInstructions =
      'Geben Sie Ihre E-Mail-Adresse ein, und wir senden Ihnen einen Link zum Zurücksetzen Ihres Passworts.';
  static const String resetPasswordButton = 'Passwort zurücksetzen';
  static const String passwordResetEmailSent =
      'E-Mail zum Zurücksetzen des Passworts gesendet. Bitte überprüfen Sie Ihren Posteingang.';

  // Edit Profile Screen
  static const String editProfileTitle = 'Profil bearbeiten';
  static const String changePasswordTitle = 'Passwort ändern';
  static const String currentPasswordLabel = 'Aktuelles Passwort';
  static const String newPasswordLabel = 'Neues Passwort';
  static const String confirmNewPasswordLabel = 'Neues Passwort bestätigen';
  static const String changePasswordButton = 'Passwort ändern';
  static const String saveChangesButton = 'Änderungen speichern';
  static const String deleteAccountButton = 'Konto löschen';
  static const String deleteAccountTitle = 'Konto löschen';
  static const String deleteAccountConfirmation =
      'Sind Sie sicher, dass Sie Ihr Konto löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  // Edit Profile Error Messages
  static const String emptyCurrentPasswordError =
      'Bitte geben Sie Ihr aktuelles Passwort ein';
  static const String newPasswordLengthError =
      'Das neue Passwort muss mindestens 6 Zeichen lang sein';
  static const String newPasswordMismatchError =
      'Die neuen Passwörter stimmen nicht überein';
  static const String wrongCurrentPasswordError =
      'Das aktuelle Passwort ist falsch';
  static const String tooManyPasswordRequestsError =
      'Zu viele Anfragen. Bitte versuchen Sie es später erneut';
  static const String passwordUpdateFailedError =
      'Passwort konnte nicht aktualisiert werden';
  static const String profileUpdateSuccessMessage =
      'Profil erfolgreich aktualisiert';
  static const String profileUpdateFailedError =
      'Profil konnte nicht aktualisiert werden: ';
  static const String accountDeleteFailedError =
      'Konto konnte nicht gelöscht werden: ';
  static const String passwordUpdateSuccessMessage =
      'Passwort erfolgreich aktualisiert';
  static const String noUserLoggedInError = 'Kein Benutzer angemeldet';

//wedding schedulePage
  static const String weddingAddPageTitle = "Tagesablauf";
  static const String weddingSchedulePageTitle = "Programmpunkt / Titel";
  static const String weddingSchedulePageDescription = "Beschreibung";
  static const String weddingSchedulePageResponsiblePerson =
      "Zuständige Person";
  static const String weddingSchedulePageNotes = "Notizen";
  static const String weddingSchedulePageTime = "Uhrzeit";
  static const String weddingSchedulePageDate = "Uhrzeit auswählen";
  static const String weddingSchedulePageLocation = "Ort";
  static const String weddingSchedulePageReminderDate =
      "Erinnerungsdatum auswählen";
  static const String weddingSchedulePageReminder = "Erinnerung";
  static const String weddingSchedulePageReminderTime = "Erinnerungszeit";
  static const String weddingSchedulePageSave = "Speichern";
  static const String weddingSchedulePageCancel = "Abbrechen";
  static const String weddingSchedulePageUpdate = "Aktualisieren";
  static const String weddingSchedulePageTitleError =
      "Bitte geben Sie einen Titel ein";
  static const String weddingSchedulePageTimeError =
      "Bitte wählen Sie eine Uhrzeit aus";
  static const String weddingSchedulePageDateError =
      "Bitte wählen Sie ein Datum aus";
  static const String weddingSchedulePageReminderTimeError =
      "Bitte wählen Sie eine Erinnerungszeit aus";
  static const String weddingSchedulePageReminderDateError =
      "Bitte wählen Sie ein Erinnerungsdatum aus";

  //inspiration folder
  static const String inspirationFolderPageTitle = "Inspirationen";

  static const String inspirationFolderPageAdd = "Hinzufügen";
  static const String inspirationFolderPageImageTitle = "Bildtitel";
  static const String inspirationFolderPageImageTitleError =
      "Bitte geben Sie einen Bildtitel ein";
  static const String inspirationFolderPageImageError =
      "Bitte wählen Sie ein Bild aus";
  static const String inspirationFolderPageSave = "Speichern";
  static const String inspirationFolderPageCancel = "Abbrechen";
  static const String inspirationFolderPageDelete = "Löschen";
  static const String inspirationFolderPageDeleteTitle = "Löschen";
  static const String inspirationFolderPageDeleteMessage =
      "Möchten Sie dieses Bild wirklich löschen?";
  static const String inspirationFolderPageDeleteButton = "Löschen";
  static const String inspirationFolderPageCancelButton = "Abbrechen";
  static const String inspirationFolderPageImage = "Bild";
  static const String inspirationFolderPageImageUpdate = "Bild aktualisieren";
  static const String inspirationFolderPageImageSelectError =
      "Bitte wählen Sie ein Bild aus";
  static const String inspirationFolderPageImageSelectError2 =
      "Bitte füllen Sie alle Felder aus";
  static const String inspirationFolderPageImageSelectError3 =
      "Fehler beim Hochladen des Bildes";
  static const String inspirationFolderPageImageSelectError4 =
      "Fehler beim Speichern des Bildes";
  static const String inspirationFolderPageImageSelectError5 =
      "Fehler beim Löschen des Bildes";
  static const String inspirationFolderPageEmpty =
      "Bitte fügen Sie Bilder hinzu, indem Sie auf das + Symbol klicken";

  //wedding category title page
  static const String weddingCategoryTitlePageNoCategoriesFound =
      'Keine Kategorie gefunden. Fügen Sie eine benutzerdefinierte hinzu!';
  static const String weddingCategoryTitlePageAddCustomCategory =
      'Benutzerdefinierte Kategorie hinzufügen';
  static const String weddingCategoryTitlePageCategoryName = 'Kategoriename';
  static const String weddingCategorySelectCategory = 'Kategorie auswählen';
  static const String weddingCategoryTitlePageItemName = 'Titel';
  static const String weddingCategoryTitlePageAdd = 'Hinzufügen';
  static const String weddingCustomCategoryAppBarTitle =
      'Benutzerdefinierte Kategorie hinzufügen';
  static const String weddingCategoryTitlePageCancel = 'Abbrechen';
  static const String weddingCategoryDuplicateError =
      'Element existiert bereits';
  static const String weddingCategoryTitlePageCancelEdit =
      'Bearbeitung abbrechen';
  static const String weddingCategoryTitlePageAddCategory = 'Speichern';
  static const String weddingCategoryTitlePageUpdateCategory = 'Speichern';
  static const String weddingCategoryTitlePageAddItem = 'Artikel hinzufügen';
  static const String weddingCategoryTitlePageAddCategoryError =
      'Bitte geben Sie einen Kategoriename ein';
  static const String weddingCategoryTitlePageAddItemError =
      'Bitte geben Sie einen Programmpunkt ein';

  static const String inspirationImageSelectText = "Wählen Sie eine Datei aus";
  static const String toDoPageTitle = "Hochzeitskit";

  static var kategorie = "Kategorie";

  static var weddingSchedulePageReminderDate1;
}
