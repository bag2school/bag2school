# Symbol index (generated)

Tabel `method -> class -> baris`. Hasil generate `tool/build_symbol_index.py`;
jangan diedit manual. Gunakan `grep` untuk mencari, bukan membuka JSON.

**64 berkas · 130 class**

## `lib/Widget/child_avatar.dart`

| Method | Class | Baris |
|---|---|---:|
| `ChildAvatar` | `ChildAvatar` | 8 |
| `build` | `ChildAvatar` | 11 |

## `lib/auth_gate.dart`

| Method | Class | Baris |
|---|---|---:|
| `AuthGate` | `AuthGate` | 13 |
| `_showFamilyJoinedDialog` | `_AuthGateState` | 26 |
| `initState` | `_AuthGateState` | 61 |
| `_checkCurrentUser` | `_AuthGateState` | 66 |
| `build` | `_AuthGateState` | 236 |

## `lib/bagi_identity_settings_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `BagiIdentitySettingsPage` | `BagiIdentitySettingsPage` | 6 |
| `initState` | `_BagiIdentitySettingsPageState` | 30 |
| `dispose` | `_BagiIdentitySettingsPageState` | 41 |
| `_genderLabel` | `_BagiIdentitySettingsPageState` | 46 |
| `_save` | `_BagiIdentitySettingsPageState` | 59 |
| `_showMessage` | `_BagiIdentitySettingsPageState` | 102 |
| `_buildGenderOption` | `_BagiIdentitySettingsPageState` | 114 |
| `build` | `_BagiIdentitySettingsPageState` | 157 |

## `lib/child_permission_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `ChildPermission` | `ChildPermission` | 13 |
| `getPermission` | `ChildPermissionService` | 47 |

## `lib/choose_family_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `ChooseFamilyPage` | `ChooseFamilyPage` | 11 |
| `build` | `ChooseFamilyPage` | 23 |
| `_ChoiceCard` | `_ChoiceCard` | 154 |
| `build` | `_ChoiceCard` | 166 |

## `lib/create_family_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `CreateFamilyPage` | `CreateFamilyPage` | 14 |
| `initState` | `_CreateFamilyPageState` | 37 |
| `_loadProfileName` | `_CreateFamilyPageState` | 42 |
| `dispose` | `_CreateFamilyPageState` | 53 |
| `_createFamily` | `_CreateFamilyPageState` | 58 |
| `build` | `_CreateFamilyPageState` | 149 |

## `lib/data/store.dart`

| Method | Class | Baris |
|---|---|---:|
| `_isOwner` | `LocalAuthorization` | 32 |
| `canView` | `LocalAuthorization` | 34 |
| `canEdit` | `LocalAuthorization` | 54 |
| `canEditActive` | `LocalAuthorization` | 74 |
| `requestViewAccess` | `LocalAuthorization` | 77 |
| `featureLabel` | `LocalAuthorization` | 127 |
| `showDenied` | `LocalAuthorization` | 140 |
| `restrictedView` | `LocalAuthorization` | 216 |
| `authorizedView` | `LocalAuthorization` | 299 |
| `_ChildDataBundle` | `_ChildDataBundle` | 330 |
| `toJson` | `_ChildDataBundle` | 342 |
| `loadSupabaseFamily` | `Bag2SchoolStore` | 427 |
| `restoreSupabaseSession` | `Bag2SchoolStore` | 673 |
| `signInLocal` | `Bag2SchoolStore` | 686 |
| `signOutLocal` | `Bag2SchoolStore` | 711 |
| `updateCurrentAccount` | `Bag2SchoolStore` | 716 |
| `createLocalAccountForFamilyMember` | `Bag2SchoolStore` | 736 |
| `canViewChild` | `Bag2SchoolStore` | 789 |
| `restoreLocalFamilyActivity` | `Bag2SchoolStore` | 872 |
| `_persistLocalFamilyActivity` | `Bag2SchoolStore` | 943 |
| `_persistLocalFamilyNotifications` | `Bag2SchoolStore` | 974 |
| `pruneNotificationInbox` | `Bag2SchoolStore` | 1006 |
| `markCurrentNotificationsRead` | `Bag2SchoolStore` | 1066 |
| `memberCanViewFeature` | `Bag2SchoolStore` | 1090 |
| `recordFamilyActivity` | `Bag2SchoolStore` | 1116 |
| `recordFamilyManagementActivity` | `Bag2SchoolStore` | 1198 |
| `notificationsForCurrentMember` | `Bag2SchoolStore` | 1215 |
| `responseNotificationsForCurrentMember` | `Bag2SchoolStore` | 1225 |
| `familyAccessGrantKey` | `Bag2SchoolStore` | 1238 |
| `saveAccessGrant` | `Bag2SchoolStore` | 1245 |
| `removeAccessGrant` | `Bag2SchoolStore` | 1251 |
| `Function` | `Bag2SchoolStore` | 1260 |
| `cacheFamilySnapshot` | `Bag2SchoolStore` | 1277 |
| `restoreFamilySnapshot` | `Bag2SchoolStore` | 1317 |
| `restoreAccessGrants` | `Bag2SchoolStore` | 1404 |
| `_persistAccessGrants` | `Bag2SchoolStore` | 1441 |
| `applyPendingAccessToNewMembers` | `Bag2SchoolStore` | 1468 |
| `updateActiveChild` | `Bag2SchoolStore` | 1559 |
| `deleteActiveChild` | `Bag2SchoolStore` | 1572 |
| `deleteChild` | `Bag2SchoolStore` | 1576 |
| `accessForChild` | `Bag2SchoolStore` | 1607 |
| `updateChildAccess` | `Bag2SchoolStore` | 1612 |
| `_saveActiveChildData` | `Bag2SchoolStore` | 1616 |
| `dayDataForChild` | `Bag2SchoolStore` | 1653 |
| `restoreActiveChildSchoolData` | `Bag2SchoolStore` | 1720 |
| `persistActiveChildSchoolData` | `Bag2SchoolStore` | 1745 |
| `persistSchoolDataSoon` | `Bag2SchoolStore` | 1751 |
| `_scheduleSchoolDataWrite` | `Bag2SchoolStore` | 1758 |
| `flushSchoolDataWrites` | `Bag2SchoolStore` | 1779 |
| `_clearActiveChildData` | `Bag2SchoolStore` | 1781 |
| `_loadChildData` | `Bag2SchoolStore` | 1793 |
| `switchActiveChild` | `Bag2SchoolStore` | 1818 |
| `cancelActivityOccurrence` | `Bag2SchoolStore` | 1854 |
| `isOccurrenceCancelled` | `Bag2SchoolStore` | 1863 |
| `moveCancelledOccurrences` | `Bag2SchoolStore` | 1872 |
| `activityOccurrenceKey` | `Bag2SchoolStore` | 1901 |
| `isActivityOccurrenceCancelled` | `Bag2SchoolStore` | 1906 |
| `preparationOccurrenceKey` | `Bag2SchoolStore` | 1925 |
| `hasPreparationOccurrenceOverride` | `Bag2SchoolStore` | 1930 |
| `preparationsForOccurrence` | `Bag2SchoolStore` | 1939 |

## `lib/family_request_pending_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `FamilyRequestPendingPage` | `FamilyRequestPendingPage` | 6 |
| `build` | `FamilyRequestPendingPage` | 14 |

## `lib/family_waiting_room_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `FamilyWaitingRoomPage` | `FamilyWaitingRoomPage` | 10 |
| `initState` | `_FamilyWaitingRoomPageState` | 26 |
| `_loadPendingRequest` | `_FamilyWaitingRoomPageState` | 31 |
| `build` | `_FamilyWaitingRoomPageState` | 49 |
| `_WaitingCard` | `_WaitingCard` | 488 |
| `build` | `_WaitingCard` | 501 |

## `lib/features/family/family_activity_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `FamilyActivityPage` | `FamilyActivityPage` | 10 |
| `_actorName` | `_FamilyActivityPageState` | 24 |
| `_featureLabel` | `_FamilyActivityPageState` | 33 |
| `_dayHeader` | `_FamilyActivityPageState` | 37 |
| `build` | `_FamilyActivityPageState` | 81 |

## `lib/features/family/family_settings_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `FamilySettingsPage` | `FamilySettingsPage` | 23 |
| `initState` | `_FamilySettingsPageState` | 43 |
| `_runFamilyPageTutorial` | `_FamilySettingsPageState` | 52 |
| `_roleLabel` | `_FamilySettingsPageState` | 94 |
| `_accessLabel` | `_FamilySettingsPageState` | 107 |
| `_showMemberEditor` | `_FamilySettingsPageState` | 118 |
| `_showAddFamilyMemberMethodDialog` | `_FamilySettingsPageState` | 615 |
| `_showBagiChatDialog` | `_FamilySettingsPageState` | 699 |
| `_accessSummary` | `_FamilySettingsPageState` | 850 |
| `_showInvitationCodeDialog` | `_FamilySettingsPageState` | 870 |
| `_showInvitationLinkDialog` | `_FamilySettingsPageState` | 1119 |
| `_grantAccess` | `_FamilySettingsPageState` | 1232 |
| `_editChildAccess` | `_FamilySettingsPageState` | 1517 |
| `_memberCard` | `_FamilySettingsPageState` | 1636 |
| `_childAccessCard` | `_FamilySettingsPageState` | 1668 |
| `_showFamilyFeedback` | `_FamilySettingsPageState` | 1818 |
| `_renameCurrentFamily` | `_FamilySettingsPageState` | 1835 |
| `_leaveCurrentFamily` | `_FamilySettingsPageState` | 1903 |
| `_showFamilySwitcher` | `_FamilySettingsPageState` | 2013 |
| `_showJoinFamilyDialog` | `_FamilySettingsPageState` | 2113 |
| `build` | `_FamilySettingsPageState` | 2283 |

## `lib/features/home/home_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `HomePage` | `HomePage` | 30 |
| `_bagiHomeMessagesForHour` | `_HomePageState` | 59 |
| `initState` | `_HomePageState` | 115 |
| `dispose` | `_HomePageState` | 125 |
| `_maybeStartOwnerTutorial` | `_HomePageState` | 130 |
| `_waitForHomeRoute` | `_HomePageState` | 198 |
| `_runHomeMenuTutorial` | `_HomePageState` | 207 |
| `_pushTutorialPage` | `_HomePageState` | 335 |
| `_startBagiHomeConversation` | `_HomePageState` | 355 |
| `_nextBagiHomeMessage` | `_HomePageState` | 363 |
| `_dayOnly` | `_HomePageState` | 383 |
| `_activitiesForDate` | `_HomePageState` | 385 |
| `_preparationsForDate` | `_HomePageState` | 399 |
| `_isHomeworkPreparationHome` | `_HomePageState` | 440 |
| `_isPreparationChecked` | `_HomePageState` | 443 |
| `_isHomeHomeworkChecked` | `_HomePageState` | 475 |
| `_readinessProgress` | `_HomePageState` | 483 |
| `_toggleHomePreparation` | `_HomePageState` | 499 |
| `_toggleHomeHomework` | `_HomePageState` | 550 |
| `_formatDateLong` | `_HomePageState` | 561 |
| `_formatTime` | `_HomePageState` | 588 |
| `_activityColor` | `_HomePageState` | 592 |
| `_activityBackground` | `_HomePageState` | 607 |
| `_activityIcon` | `_HomePageState` | 622 |
| `_chooseActiveChild` | `_HomePageState` | 671 |
| `_pickChildPhoto` | `_HomePageState` | 730 |
| `_editChildProfile` | `_HomePageState` | 741 |
| `_buildChildAvatar` | `_HomePageState` | 913 |
| `_buildOfflineBanner` | `_HomePageState` | 926 |
| `_buildOtherChildCards` | `_HomePageState` | 956 |
| `_buildOtherChildCard` | `_HomePageState` | 999 |
| `_showChildTomorrow` | `_HomePageState` | 1044 |
| `_daySectionLabel` | `_HomePageState` | 1187 |
| `_readOnlyActivityRow` | `_HomePageState` | 1202 |
| `_readOnlySimpleRow` | `_HomePageState` | 1250 |
| `_buildHomeBagiCompanion` | `_HomePageState` | 1298 |
| `_buildTomorrowSection` | `_HomePageState` | 1366 |
| `_homeScheduleItem` | `_HomePageState` | 1418 |
| `_buildReadinessRing` | `_HomePageState` | 1477 |
| `_buildReadinessStatus` | `_HomePageState` | 1527 |
| `_buildReadinessRow` | `_HomePageState` | 1566 |
| `_buildPreparationSummary` | `_HomePageState` | 1696 |
| `_homeworksForHome` | `_HomePageState` | 1908 |
| `_homeworksForDate` | `_HomePageState` | 1921 |
| `_buildHomeworkSummary` | `_HomePageState` | 1933 |
| `_openNotificationTarget` | `_HomePageState` | 2061 |
| `_openAccessResponseTarget` | `_HomePageState` | 2096 |
| `_showNotifications` | `_HomePageState` | 2126 |
| `build` | `_HomePageState` | 2644 |
| `Bag2SchoolLogo` | `Bag2SchoolLogo` | 2960 |
| `build` | `Bag2SchoolLogo` | 2963 |

## `lib/features/homework/homework_history_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `HomeworkHistoryPage` | `HomeworkHistoryPage` | 8 |
| `build` | `HomeworkHistoryPage` | 11 |

## `lib/features/homework/homework_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `HomeworkPage` | `HomeworkPage` | 26 |
| `initState` | `_HomeworkPageState` | 61 |
| `_runHomeworkTutorial` | `_HomeworkPageState` | 79 |
| `dispose` | `_HomeworkPageState` | 93 |
| `_typeMessage` | `_HomeworkPageState` | 99 |
| `_dayOnly` | `_HomeworkPageState` | 113 |
| `_dateLabel` | `_HomeworkPageState` | 115 |
| `_dueLabel` | `_HomeworkPageState` | 133 |
| `_sameDay` | `_HomeworkPageState` | 142 |
| `_homeworkStatusLabel` | `_HomeworkPageState` | 145 |
| `_openHomework` | `_HomeworkPageState` | 155 |
| `_todayHomework` | `_HomeworkPageState` | 163 |
| `_tomorrowHomework` | `_HomeworkPageState` | 170 |
| `_upcomingHomework` | `_HomeworkPageState` | 177 |
| `_overdueHomework` | `_HomeworkPageState` | 186 |
| `_completedItems` | `_HomeworkPageState` | 194 |
| `_toggleDone` | `_HomeworkPageState` | 199 |
| `_undoCompleted` | `_HomeworkPageState` | 219 |
| `_removeHomeworkFromPreparation` | `_HomeworkPageState` | 228 |
| `_addHomeworkToPreparation` | `_HomeworkPageState` | 239 |
| `_delete` | `_HomeworkPageState` | 266 |
| `_bagiHero` | `_HomeworkPageState` | 313 |
| `_speechBubble` | `_HomeworkPageState` | 337 |
| `_segmentedTabs` | `_HomeworkPageState` | 380 |
| `_tabButton` | `_HomeworkPageState` | 409 |
| `_emptyState` | `_HomeworkPageState` | 440 |
| `_homeworkSection` | `_HomeworkPageState` | 506 |
| `_homeworkEmptyHint` | `_HomeworkPageState` | 604 |
| `_homeworkCard` | `_HomeworkPageState` | 632 |
| `_completedInfo` | `_HomeworkPageState` | 894 |
| `_smallInfo` | `_HomeworkPageState` | 924 |
| `_formField` | `_HomeworkPageState` | 949 |
| `_selector` | `_HomeworkPageState` | 1007 |
| `_relatedActivityLabel` | `_HomeworkPageState` | 1049 |
| `_addHomework` | `_HomeworkPageState` | 1062 |
| `_editHomework` | `_HomeworkPageState` | 1575 |
| `build` | `_HomeworkPageState` | 2014 |
| `_HomeworkActivityOption` | `_HomeworkActivityOption` | 2193 |

## `lib/features/preparation/preparation_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `PreparationPage` | `PreparationPage` | 32 |
| `_currentBagiGreeting` | `_PreparationPageState` | 54 |
| `_dayOnly` | `_PreparationPageState` | 61 |
| `_formatDate` | `_PreparationPageState` | 64 |
| `_formatTime` | `_PreparationPageState` | 82 |
| `_preparationGroupTitle` | `_PreparationPageState` | 112 |
| `_personalizeBagi` | `_PreparationPageState` | 116 |
| `_categoryLabel` | `_PreparationPageState` | 120 |
| `_activityIcon` | `_PreparationPageState` | 136 |
| `_activityTint` | `_PreparationPageState` | 152 |
| `_itemsForDate` | `_PreparationPageState` | 168 |
| `_preparationDates` | `_PreparationPageState` | 175 |
| `_done` | `_PreparationPageState` | 184 |
| `_progress` | `_PreparationPageState` | 187 |
| `_progressText` | `_PreparationPageState` | 192 |
| `_groupsForTodayAndFuture` | `_PreparationPageState` | 196 |
| `_historyGroups` | `_PreparationPageState` | 278 |
| `_bagiThoughts` | `_PreparationPageState` | 312 |
| `_startBagi` | `_PreparationPageState` | 387 |
| `_showNextBagi` | `_PreparationPageState` | 396 |
| `initState` | `_PreparationPageState` | 431 |
| `_runPreparationTutorial` | `_PreparationPageState` | 441 |
| `dispose` | `_PreparationPageState` | 458 |
| `_occurrenceKey` | `_PreparationPageState` | 463 |
| `_isOccurrenceChecked` | `_PreparationPageState` | 467 |
| `_editPreparationGroup` | `_PreparationPageState` | 496 |
| `_deletePreparationItem` | `_PreparationPageState` | 762 |
| `_deleteHomeworkFromPreparation` | `_PreparationPageState` | 836 |
| `_deletePreparationGroup` | `_PreparationPageState` | 893 |
| `_toggleItem` | `_PreparationPageState` | 951 |
| `_showHistory` | `_PreparationPageState` | 1049 |
| `_isHomeworkPreparation` | `_PreparationPageState` | 1147 |
| `_hasEditablePreparations` | `_PreparationPageState` | 1150 |
| `_buildPreparationCard` | `_PreparationPageState` | 1153 |
| `_preparationActionButton` | `_PreparationPageState` | 1412 |
| `_sectionLabel` | `_PreparationPageState` | 1435 |
| `build` | `_PreparationPageState` | 1461 |
| `PreparationOfferCard` | `PreparationOfferCard` | 1988 |
| `_loadDefaults` | `PreparationOfferCardState` | 2012 |
| `_removeDefault` | `PreparationOfferCardState` | 2022 |
| `initState` | `PreparationOfferCardState` | 2034 |
| `dispose` | `PreparationOfferCardState` | 2046 |
| `_formatTime` | `PreparationOfferCardState` | 2053 |
| `_formatShortDate` | `PreparationOfferCardState` | 2061 |
| `_formatDate` | `PreparationOfferCardState` | 2079 |
| `_addCustomItem` | `PreparationOfferCardState` | 2107 |
| `_toggleItem` | `PreparationOfferCardState` | 2126 |
| `_pickReminderDate` | `PreparationOfferCardState` | 2138 |
| `_pickReminderTime` | `PreparationOfferCardState` | 2170 |
| `build` | `PreparationOfferCardState` | 2194 |
| `_messageFor` | `PreparationOfferCardState` | 2473 |
| `PreparationChecklistItem` | `PreparationChecklistItem` | 2511 |
| `_itemIcon` | `_PreparationChecklistItemState` | 2528 |
| `build` | `_PreparationChecklistItemState` | 2552 |

## `lib/features/schedule/forms/event_activity_form.dart`

| Method | Class | Baris |
|---|---|---:|
| `EventActivityForm` | `EventActivityForm` | 12 |
| `initState` | `_EventActivityFormState` | 30 |
| `dispose` | `_EventActivityFormState` | 40 |
| `_formatDate` | `_EventActivityFormState` | 45 |
| `_formatTime` | `_EventActivityFormState` | 63 |
| `_pickDate` | `_EventActivityFormState` | 74 |
| `_pickTime` | `_EventActivityFormState` | 86 |
| `_save` | `_EventActivityFormState` | 109 |
| `build` | `_EventActivityFormState` | 157 |

## `lib/features/schedule/forms/exam_activity_form.dart`

| Method | Class | Baris |
|---|---|---:|
| `ExamActivityForm` | `ExamActivityForm` | 12 |
| `initState` | `_ExamActivityFormState` | 31 |
| `dispose` | `_ExamActivityFormState` | 41 |
| `_formatDate` | `_ExamActivityFormState` | 46 |
| `_formatTime` | `_ExamActivityFormState` | 64 |
| `_pickDate` | `_ExamActivityFormState` | 75 |
| `_pickTime` | `_ExamActivityFormState` | 87 |
| `_save` | `_ExamActivityFormState` | 114 |
| `build` | `_ExamActivityFormState` | 157 |

## `lib/features/schedule/forms/extracurricular_activity_form.dart`

| Method | Class | Baris |
|---|---|---:|
| `ExtracurricularActivityForm` | `ExtracurricularActivityForm` | 16 |
| `initState` | `_ExtracurricularActivityFormState` | 43 |
| `dispose` | `_ExtracurricularActivityFormState` | 53 |
| `_formatDate` | `_ExtracurricularActivityFormState` | 58 |
| `_formatTime` | `_ExtracurricularActivityFormState` | 76 |
| `_pickDate` | `_ExtracurricularActivityFormState` | 83 |
| `_pickTime` | `_ExtracurricularActivityFormState` | 106 |
| `_recurrenceLabel` | `_ExtracurricularActivityFormState` | 129 |
| `_buildRecurrence` | `_ExtracurricularActivityFormState` | 146 |
| `_hasTimeError` | `_ExtracurricularActivityFormState` | 166 |
| `_buildActivity` | `_ExtracurricularActivityFormState` | 171 |
| `_save` | `_ExtracurricularActivityFormState` | 191 |
| `_showConflictWarning` | `_ExtracurricularActivityFormState` | 321 |
| `_finishSave` | `_ExtracurricularActivityFormState` | 364 |
| `_sectionTitle` | `_ExtracurricularActivityFormState` | 370 |
| `_timeCard` | `_ExtracurricularActivityFormState` | 384 |
| `_repeatOption` | `_ExtracurricularActivityFormState` | 423 |
| `_weekdayChip` | `_ExtracurricularActivityFormState` | 468 |
| `build` | `_ExtracurricularActivityFormState` | 494 |

## `lib/features/schedule/forms/lesson_activity_form.dart`

| Method | Class | Baris |
|---|---|---:|
| `LessonActivityForm` | `LessonActivityForm` | 16 |
| `initState` | `_LessonActivityFormState` | 41 |
| `dispose` | `_LessonActivityFormState` | 51 |
| `_formatDate` | `_LessonActivityFormState` | 56 |
| `_formatTime` | `_LessonActivityFormState` | 74 |
| `_pickDate` | `_LessonActivityFormState` | 81 |
| `_pickTime` | `_LessonActivityFormState` | 104 |
| `_recurrenceLabel` | `_LessonActivityFormState` | 121 |
| `_buildRecurrence` | `_LessonActivityFormState` | 138 |
| `_hasTimeError` | `_LessonActivityFormState` | 163 |
| `_buildActivity` | `_LessonActivityFormState` | 168 |
| `_save` | `_LessonActivityFormState` | 189 |
| `_showConflictWarning` | `_LessonActivityFormState` | 319 |
| `_finishSave` | `_LessonActivityFormState` | 362 |
| `_sectionTitle` | `_LessonActivityFormState` | 368 |
| `_timeCard` | `_LessonActivityFormState` | 382 |
| `_repeatOption` | `_LessonActivityFormState` | 421 |
| `_weekdayChip` | `_LessonActivityFormState` | 466 |
| `build` | `_LessonActivityFormState` | 492 |

## `lib/features/schedule/forms/school_activity_form.dart`

| Method | Class | Baris |
|---|---|---:|
| `SchoolActivityForm` | `SchoolActivityForm` | 14 |
| `initState` | `_SchoolActivityFormState` | 45 |
| `dispose` | `_SchoolActivityFormState` | 55 |
| `_formatDate` | `_SchoolActivityFormState` | 60 |
| `_formatTime` | `_SchoolActivityFormState` | 78 |
| `_pickDate` | `_SchoolActivityFormState` | 85 |
| `_pickTime` | `_SchoolActivityFormState` | 108 |
| `_recurrenceLabel` | `_SchoolActivityFormState` | 125 |
| `_buildRecurrence` | `_SchoolActivityFormState` | 142 |
| `_hasTimeError` | `_SchoolActivityFormState` | 167 |
| `_buildActivity` | `_SchoolActivityFormState` | 172 |
| `_save` | `_SchoolActivityFormState` | 192 |
| `_showConflictWarning` | `_SchoolActivityFormState` | 240 |
| `_finishSave` | `_SchoolActivityFormState` | 283 |
| `_sectionTitle` | `_SchoolActivityFormState` | 289 |
| `_timeCard` | `_SchoolActivityFormState` | 303 |
| `_repeatOption` | `_SchoolActivityFormState` | 342 |
| `_weekdayChip` | `_SchoolActivityFormState` | 387 |
| `build` | `_SchoolActivityFormState` | 413 |

## `lib/features/schedule/schedule_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `SchedulePage` | `SchedulePage` | 33 |
| `_personalizeBagi` | `_SchedulePageState` | 59 |
| `initState` | `_SchedulePageState` | 71 |
| `_runScheduleTutorial` | `_SchedulePageState` | 88 |
| `_startBagiScheduleConversation` | `_SchedulePageState` | 120 |
| `_showNextBagiScheduleThought` | `_SchedulePageState` | 130 |
| `_bagiActivityCategory` | `_SchedulePageState` | 150 |
| `_buildBagiUpcomingReminderThoughts` | `_SchedulePageState` | 165 |
| `_buildBagiScheduleThoughts` | `_SchedulePageState` | 194 |
| `_mondayOf` | `_SchedulePageState` | 312 |
| `_dateForWeekPage` | `_SchedulePageState` | 319 |
| `dispose` | `_SchedulePageState` | 325 |
| `_buildDateSummaryMessage` | `_SchedulePageState` | 332 |
| `_onScheduleDateSelected` | `_SchedulePageState` | 419 |
| `_showBagiScheduleMessage` | `_SchedulePageState` | 440 |
| `_goToToday` | `_SchedulePageState` | 475 |
| `_buildBagiHighlightedText` | `_SchedulePageState` | 504 |
| `_buildEmptyScheduleCard` | `_SchedulePageState` | 586 |
| `_buildBagiScheduleBubble` | `_SchedulePageState` | 651 |
| `_activityChoice` | `_SchedulePageState` | 694 |
| `_afterActivitySaved` | `_SchedulePageState` | 733 |
| `_showSchoolForm` | `_SchedulePageState` | 799 |
| `_showLessonForm` | `_SchedulePageState` | 817 |
| `_showExtracurricularForm` | `_SchedulePageState` | 835 |
| `_showEventForm` | `_SchedulePageState` | 853 |
| `_showExamForm` | `_SchedulePageState` | 871 |
| `_showPreparationOffer` | `_SchedulePageState` | 893 |
| `_formatFriendlyDate` | `_SchedulePageState` | 1004 |
| `_activityCategoryLabel` | `_SchedulePageState` | 1031 |
| `_showFriendlyTimeWarning` | `_SchedulePageState` | 1046 |
| `_showEditActivityDialog` | `_SchedulePageState` | 1155 |
| `_formatDateShort` | `_SchedulePageState` | 2246 |
| `_formatTimeOfDay24` | `_SchedulePageState` | 2264 |
| `_confirmDeleteActivity` | `_SchedulePageState` | 2269 |
| `_savedActivitiesForSelectedDate` | `_SchedulePageState` | 2469 |
| `_homeworkForSelectedDate` | `_SchedulePageState` | 2480 |
| `_openHomeworkFromSchedule` | `_SchedulePageState` | 2504 |
| `_timelineType` | `_SchedulePageState` | 2511 |
| `_timelineIcon` | `_SchedulePageState` | 2526 |
| `_timelineBackground` | `_SchedulePageState` | 2541 |
| `_timelineColor` | `_SchedulePageState` | 2556 |
| `_formatTimelineTime` | `_SchedulePageState` | 2571 |
| `dayName` | `_SchedulePageState` | 2577 |
| `monthName` | `_SchedulePageState` | 2583 |
| `fullDate` | `_SchedulePageState` | 2602 |
| `_calendarIndicators` | `_SchedulePageState` | 2639 |
| `openCalendar` | `_SchedulePageState` | 2723 |
| `_showAddActivityChooser` | `_SchedulePageState` | 2744 |
| `build` | `_SchedulePageState` | 2867 |
| `ScheduleTimelineItem` | `ScheduleTimelineItem` | 3335 |
| `build` | `_ScheduleTimelineItemState` | 3357 |
| `BagiConflictCard` | `BagiConflictCard` | 3589 |
| `build` | `BagiConflictCard` | 3596 |

## `lib/features/schedule/widgets/conflict_card.dart`

| Method | Class | Baris |
|---|---|---:|
| `BagiConflictCard` | `BagiConflictCard` | 14 |
| `build` | `BagiConflictCard` | 21 |

## `lib/features/settings/local_account_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `LocalAccountPage` | `LocalAccountPage` | 15 |
| `_changePassword` | `_LocalAccountPageState` | 27 |
| `_deleteAccount` | `_LocalAccountPageState` | 112 |
| `_editAccount` | `_LocalAccountPageState` | 160 |
| `_openBagiIdentitySettings` | `_LocalAccountPageState` | 286 |
| `_showLocalSignIn` | `_LocalAccountPageState` | 297 |
| `_roleLabel` | `_LocalAccountPageState` | 359 |
| `_accessSummary` | `_LocalAccountPageState` | 372 |
| `build` | `_LocalAccountPageState` | 491 |

## `lib/features/settings/settings_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `SettingsPage` | `SettingsPage` | 29 |
| `initState` | `_SettingsPageState` | 63 |
| `dispose` | `_SettingsPageState` | 78 |
| `_runOwnerSetupTutorial` | `_SettingsPageState` | 84 |
| `_runFamilySettingsTutorial` | `_SettingsPageState` | 153 |
| `_runChildFormTutorial` | `_SettingsPageState` | 191 |
| `_chooseLanguage` | `_SettingsPageState` | 251 |
| `_editChildProfile` | `_SettingsPageState` | 318 |
| `_showComingSoon` | `_SettingsPageState` | 486 |
| `_sectionTitle` | `_SettingsPageState` | 502 |
| `_settingTile` | `_SettingsPageState` | 517 |
| `_buildAccountCard` | `_SettingsPageState` | 571 |
| `_showChildEditor` | `_SettingsPageState` | 654 |
| `_chooseSettingsChild` | `_SettingsPageState` | 1029 |
| `_activateChild` | `_SettingsPageState` | 1090 |
| `_buildChildProfilesSection` | `_SettingsPageState` | 1105 |
| `build` | `_SettingsPageState` | 1213 |
| `_DailyReminderTile` | `_DailyReminderTile` | 1409 |
| `initState` | `_DailyReminderTileState` | 1427 |
| `_load` | `_DailyReminderTileState` | 1432 |
| `_toggle` | `_DailyReminderTileState` | 1448 |
| `_pickTime` | `_DailyReminderTileState` | 1483 |
| `build` | `_DailyReminderTileState` | 1506 |

## `lib/login_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `LoginPage` | `LoginPage` | 13 |
| `dispose` | `_LoginPageState` | 33 |
| `_forgotPassword` | `_LoginPageState` | 39 |
| `_signIn` | `_LoginPageState` | 131 |
| `build` | `_LoginPageState` | 250 |

## `lib/main.dart`

| Method | Class | Baris |
|---|---|---:|
| `_BagiErrorScreen` | `_BagiErrorScreen` | 197 |
| `build` | `_BagiErrorScreen` | 202 |
| `Bag2SchoolApp` | `Bag2SchoolApp` | 260 |
| `build` | `Bag2SchoolApp` | 263 |
| `show` | `Bag2SchoolSuccessNotification` | 351 |
| `BagiSmallCharacter` | `BagiSmallCharacter` | 466 |
| `build` | `BagiSmallCharacter` | 469 |
| `BagiMiniCharacter` | `BagiMiniCharacter` | 475 |
| `build` | `BagiMiniCharacter` | 478 |

## `lib/models/activity_models.dart`

| Method | Class | Baris |
|---|---|---:|
| `TimeOfDayData` | `TimeOfDayData` | 26 |
| `ActivityRecurrence` | `ActivityRecurrence` | 37 |
| `occursOn` | `ActivityRecurrence` | 44 |
| `_monthsBetween` | `ActivityRecurrence` | 94 |
| `_weeksBetween` | `ActivityRecurrence` | 98 |
| `HomeworkDetails` | `HomeworkDetails` | 110 |
| `copyWith` | `HomeworkDetails` | 118 |
| `BagActivity` | `BagActivity` | 151 |
| `occursOn` | `BagActivity` | 168 |
| `startMinutes` | `BagActivity` | 172 |
| `endMinutes` | `BagActivity` | 176 |
| `copyWith` | `BagActivity` | 180 |
| `PreparationItem` | `PreparationItem` | 225 |
| `copyWith` | `PreparationItem` | 237 |
| `occursOn` | `PreparationItem` | 259 |
| `HomeworkItem` | `HomeworkItem` | 285 |
| `copyWith` | `HomeworkItem` | 301 |
| `ActivityConflict` | `ActivityConflict` | 344 |
| `ActivityConflictDetector` | `ActivityConflictDetector` | 352 |
| `findConflicts` | `ActivityConflictDetector` | 354 |
| `_overlappingDates` | `ActivityConflictDetector` | 389 |
| `CalendarIndicator` | `CalendarIndicator` | 428 |
| `ChildDayData` | `ChildDayData` | 449 |

## `lib/models/child_profile.dart`

| Method | Class | Baris |
|---|---|---:|
| `ChildProfile` | `ChildProfile` | 8 |
| `copyWith` | `ChildProfile` | 16 |

## `lib/models/family_models.dart`

| Method | Class | Baris |
|---|---|---:|
| `LocalAccount` | `LocalAccount` | 19 |
| `copyWith` | `LocalAccount` | 27 |
| `FamilyMember` | `FamilyMember` | 49 |
| `copyWith` | `FamilyMember` | 56 |
| `FamilyAccessGrant` | `FamilyAccessGrant` | 83 |
| `copyWith` | `FamilyAccessGrant` | 96 |
| `ChildAccessSettings` | `ChildAccessSettings` | 131 |
| `copyWith` | `ChildAccessSettings` | 140 |
| `LocalAccessRequest` | `LocalAccessRequest` | 169 |
| `copyWith` | `LocalAccessRequest` | 179 |
| `LocalFamilyNotification` | `LocalFamilyNotification` | 202 |
| `LocalFamilyActivity` | `LocalFamilyActivity` | 228 |

## `lib/reset_password_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `ResetPasswordPage` | `ResetPasswordPage` | 10 |
| `dispose` | `_ResetPasswordPageState` | 30 |
| `_submit` | `_ResetPasswordPageState` | 36 |
| `build` | `_ResetPasswordPageState` | 109 |

## `lib/services/bagi_app_bootstrap.dart`

| Method | Class | Baris |
|---|---|---:|
| `initialize` | `BagiAppBootstrap` | 6 |

## `lib/services/bagi_auth_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `SignUpOutcome` | `SignUpOutcome` | 10 |
| `signIn` | `BagiAuthService` | 39 |
| `_isNetworkFailure` | `BagiAuthService` | 125 |
| `signUp` | `BagiAuthService` | 138 |
| `_isSignupTimeout` | `BagiAuthService` | 268 |
| `_rememberThisDeviceSignIn` | `BagiAuthService` | 279 |
| `detectSignInOnAnotherDevice` | `BagiAuthService` | 295 |
| `requestPasswordReset` | `BagiAuthService` | 334 |
| `completePasswordRecovery` | `BagiAuthService` | 354 |
| `signOut` | `BagiAuthService` | 382 |
| `updatePassword` | `BagiAuthService` | 392 |

## `lib/services/bagi_avatar_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `childAvatarPath` | `BagiAvatarService` | 12 |
| `uploadChildAvatar` | `BagiAvatarService` | 19 |
| `deleteChildAvatar` | `BagiAvatarService` | 38 |
| `createChildAvatarSignedUrl` | `BagiAvatarService` | 42 |

## `lib/services/bagi_family_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `createFamily` | `BagiFamilyService` | 133 |
| `createFamilyInvitation` | `BagiFamilyService` | 259 |
| `renameFamily` | `BagiFamilyService` | 612 |
| `deleteOwnAccount` | `BagiFamilyService` | 653 |

## `lib/services/bagi_greeting_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `parentTitle` | `BagiGreetingService` | 10 |
| `greeting` | `BagiGreetingService` | 20 |
| `morning` | `BagiGreetingService` | 26 |
| `afternoon` | `BagiGreetingService` | 33 |
| `evening` | `BagiGreetingService` | 40 |
| `current` | `BagiGreetingService` | 47 |
| `night` | `BagiGreetingService` | 70 |

## `lib/services/bagi_identity_bootstrap.dart`

| Method | Class | Baris |
|---|---|---:|
| `initialize` | `BagiIdentityBootstrap` | 12 |
| `refresh` | `BagiIdentityBootstrap` | 33 |
| `clear` | `BagiIdentityBootstrap` | 41 |

## `lib/services/bagi_identity_controller.dart`

| Method | Class | Baris |
|---|---|---:|
| `load` | `BagiIdentityController` | 49 |
| `saveIdentity` | `BagiIdentityController` | 89 |
| `clear` | `BagiIdentityController` | 111 |
| `resolveAddressName` | `BagiIdentityController` | 125 |
| `personalize` | `BagiIdentityController` | 161 |
| `morningGreeting` | `BagiIdentityController` | 178 |
| `afternoonGreeting` | `BagiIdentityController` | 183 |
| `eveningGreeting` | `BagiIdentityController` | 188 |
| `nightGreeting` | `BagiIdentityController` | 193 |

## `lib/services/bagi_local_auth_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `signIn` | `BagiLocalAuthService` | 16 |
| `signOut` | `BagiLocalAuthService` | 46 |

## `lib/services/bagi_profile_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `BagiProfile` | `BagiProfile` | 10 |
| `loadCurrentProfile` | `BagiProfileService` | 44 |
| `loadCurrentParentTitle` | `BagiProfileService` | 64 |
| `updateIdentity` | `BagiProfileService` | 70 |

## `lib/services/bagi_session_bridge.dart`

| Method | Class | Baris |
|---|---|---:|
| `refresh` | `BagiSessionBridge` | 9 |
| `clear` | `BagiSessionBridge` | 35 |

## `lib/services/family_access_defaults.dart`

| Method | Class | Baris |
|---|---|---:|
| `_accessKey` | `FamilyAccessDefaults` | 15 |
| `_knownMembersKey` | `FamilyAccessDefaults` | 18 |
| `save` | `FamilyAccessDefaults` | 21 |
| `saveKnownMembers` | `FamilyAccessDefaults` | 75 |

## `lib/services/owner_tutorial_state.dart`

| Method | Class | Baris |
|---|---|---:|
| `_pendingKey` | `OwnerTutorialState` | 6 |
| `_completedKey` | `OwnerTutorialState` | 8 |
| `markPending` | `OwnerTutorialState` | 11 |
| `shouldShow` | `OwnerTutorialState` | 18 |
| `isCompleted` | `OwnerTutorialState` | 25 |
| `markCompleted` | `OwnerTutorialState` | 31 |

## `lib/services/preparation_defaults.dart`

| Method | Class | Baris |
|---|---|---:|
| `builtInFor` | `PreparationDefaults` | 29 |
| `_save` | `PreparationDefaults` | 73 |

## `lib/services/reminder_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `initialize` | `DailyReminder` | 34 |
| `isEnabled` | `DailyReminder` | 58 |
| `reminderHour` | `DailyReminder` | 63 |
| `reminderMinute` | `DailyReminder` | 68 |
| `saveTime` | `DailyReminder` | 73 |
| `saveEnabled` | `DailyReminder` | 79 |
| `requestPermissions` | `DailyReminder` | 87 |
| `schedule` | `DailyReminder` | 104 |
| `cancel` | `DailyReminder` | 170 |
| `describeTime` | `DailyReminder` | 183 |

## `lib/services/supabase_auth_test.dart`

| Method | Class | Baris |
|---|---|---:|
| `loginOwner` | `SupabaseAuthTest` | 6 |
| `logout` | `SupabaseAuthTest` | 29 |

## `lib/services/supabase_connection_test.dart`

| Method | Class | Baris |
|---|---|---:|
| `testConnection` | `SupabaseConnectionTest` | 6 |

## `lib/signup_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `SignUpPage` | `SignUpPage` | 8 |
| `dispose` | `_SignUpPageState` | 30 |
| `_signUp` | `_SignUpPageState` | 38 |
| `_showFriendlyMessage` | `_SignUpPageState` | 126 |
| `build` | `_SignUpPageState` | 221 |

## `lib/supabase_debug_page.dart`

| Method | Class | Baris |
|---|---|---:|
| `SupabaseDebugPage` | `SupabaseDebugPage` | 5 |
| `testOwnerLogin` | `_SupabaseDebugPageState` | 21 |
| `testOwnerDataAccess` | `_SupabaseDebugPageState` | 91 |
| `testChildAccessGrants` | `_SupabaseDebugPageState` | 172 |
| `testFamilyMembersAccess` | `_SupabaseDebugPageState` | 253 |
| `testOwnProfileAccess` | `_SupabaseDebugPageState` | 340 |
| `testOwnerIdentity` | `_SupabaseDebugPageState` | 456 |
| `testChildPermissionResolution` | `_SupabaseDebugPageState` | 599 |
| `logout` | `_SupabaseDebugPageState` | 740 |
| `build` | `_SupabaseDebugPageState` | 759 |

## `lib/supabase_service.dart`

| Method | Class | Baris |
|---|---|---:|
| `signIn` | `SupabaseService` | 16 |
| `signOut` | `SupabaseService` | 23 |

## `lib/widgets/bagi_character.dart`

| Method | Class | Baris |
|---|---|---:|
| `BagiCharacter` | `BagiCharacter` | 16 |
| `initState` | `_BagiCharacterState` | 34 |
| `_loadSheet` | `_BagiCharacterState` | 39 |
| `dispose` | `_BagiCharacterState` | 56 |
| `build` | `_BagiCharacterState` | 63 |
| `_BagiSpritePainter` | `_BagiSpritePainter` | 104 |
| `paint` | `_BagiSpritePainter` | 110 |
| `shouldRepaint` | `_BagiSpritePainter` | 144 |

## `lib/widgets/bagi_tutorial_overlay.dart`

| Method | Class | Baris |
|---|---|---:|
| `register` | `BagiTutorialTargetActions` | 125 |
| `activate` | `BagiTutorialTargetActions` | 130 |
| `clear` | `BagiTutorialTargetActions` | 134 |
| `_BagiTutorialSpotlight` | `_BagiTutorialSpotlight` | 250 |
| `build` | `_BagiTutorialSpotlight` | 266 |

## `lib/widgets/bubble_tail_painters.dart`

| Method | Class | Baris |
|---|---|---:|
| `paint` | `BagiBubbleTailPainter` | 8 |
| `shouldRepaint` | `BagiBubbleTailPainter` | 23 |
| `paint` | `BagiHomeBubbleTailPainter` | 28 |
| `shouldRepaint` | `BagiHomeBubbleTailPainter` | 43 |
| `paint` | `OrangeBubbleTailPainter` | 48 |
| `shouldRepaint` | `OrangeBubbleTailPainter` | 59 |
| `paint` | `PreparationBubbleTailPainter` | 64 |
| `shouldRepaint` | `PreparationBubbleTailPainter` | 77 |

## `lib/widgets/child_avatar.dart`

| Method | Class | Baris |
|---|---|---:|
| `ChildAvatar` | `ChildAvatar` | 8 |
| `build` | `ChildAvatar` | 11 |

## `lib/widgets/list_items.dart`

| Method | Class | Baris |
|---|---|---:|
| `ActionIconButton` | `ActionIconButton` | 12 |
| `build` | `ActionIconButton` | 20 |
| `ScheduleItem` | `ScheduleItem` | 49 |
| `build` | `ScheduleItem` | 59 |
| `TodoItem` | `TodoItem` | 102 |
| `build` | `TodoItem` | 110 |
| `BagiTip` | `BagiTip` | 171 |
| `build` | `BagiTip` | 174 |

## `lib/widgets/month_calendar.dart`

| Method | Class | Baris |
|---|---|---:|
| `Bag2SchoolMonthCalendar` | `Bag2SchoolMonthCalendar` | 12 |
| `initState` | `_Bag2SchoolMonthCalendarState` | 23 |
| `monthName` | `_Bag2SchoolMonthCalendarState` | 32 |
| `daysInMonth` | `_Bag2SchoolMonthCalendarState` | 51 |
| `indicatorsFor` | `_Bag2SchoolMonthCalendarState` | 55 |
| `build` | `_Bag2SchoolMonthCalendarState` | 130 |
| `_CalendarWeekday` | `_CalendarWeekday` | 326 |
| `build` | `_CalendarWeekday` | 329 |
| `_CalendarLegend` | `_CalendarLegend` | 347 |
| `build` | `_CalendarLegend` | 350 |

