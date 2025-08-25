import { PLVCommonConstants, PLVLanguage, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../../common/PLVLWLayoutDataBus';
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common';

@Component
export struct PLVLWMoreSwitchLanguageAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback
  private readonly languageSelectDialog = new CustomDialogController({
    builder: LanguageSelectDialog(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  aboutToAppear(): void {
  }

  build() {
    MoreSettingActionView({
      icon: $r('app.media.plvlw_more_switch_language_icon'),
      title: $r('app.string.plvlw_live_language_switch')
    })
      .onClick(() => {
        this.moreSettingActionCallback.hideMoreSettingDialog?.()
        this.languageSelectDialog.open()
      })
  }

  aboutToDisappear(): void {
  }
}

const supportLanguages: LanguageData[] = [
  {
    lang: PLVLanguage.ZH,
    text: $r('app.string.plvlw_live_language_switch_zh'),
    onClick: (sdk: PLVLiveSceneSDK) => {
      sdk.languageManager.changeToZH()
    }
  },
  {
    lang: PLVLanguage.EN,
    text: $r('app.string.plvlw_live_language_switch_en'),
    onClick: (sdk: PLVLiveSceneSDK) => {
      sdk.languageManager.changeToEN()
    }
  }
]

@CustomDialog
struct LanguageSelectDialog {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private currentLanguage: PLVLanguage = PLVLanguage.ZH
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
    this.currentLanguage = this.sdk.channelData.language ?? PLVLanguage.ZH
    this.sdk.channelData.eventNotify.on('language', this.onLanguage, this)
  }

  private readonly onLanguage = (language: PLVLanguage) => {
    this.currentLanguage = language
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvlw_live_language_switch'))
        .id('plvlw_more_language_title')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.plvlw_more_setting_action_popup_layout_title'))
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
        })
        .margin({
          top: 15
        })

      List({
        space: 8
      }) {
        ForEach(
          supportLanguages,
          (languageData: LanguageData) => {
            ListItem() {
              Text(languageData.text)
                .width(PLVCommonConstants.FULL_PERCENT)
                .height(56)
                .textAlign(TextAlign.Center)
                .fontSize(14)
                .fontColor(languageData.lang === this.currentLanguage
                  ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_text')
                  : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_text')
                )
                .border({
                  radius: 8,
                  color: languageData.lang === this.currentLanguage
                    ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_stroke')
                    : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_solid'),
                  width: 1
                })
                .backgroundColor(languageData.lang === this.currentLanguage
                  ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_solid')
                  : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_solid')
                )
            }
            .onClick(() => {
              languageData.onClick(this.sdk)
              this.controller.close()
            })
          },
          (languageData: LanguageData) => languageData.lang
        )
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .padding({
        left: 16,
        right: 16
      })
      .alignRules({
        top: { anchor: 'plvlw_more_language_title', align: VerticalAlign.Bottom },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .margin({
        top: 27,
        bottom: 46
      })
    }
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : 375)
    .height(this.isPortrait ? 294 : PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_common_popup_background'))
    .borderRadius({
      topLeft: 16,
      topRight: this.isPortrait ? 16 : 0,
      bottomLeft: this.isPortrait ? 0 : 16
    })
  }

  aboutToDisappear(): void {
    this.sdk.channelData.eventNotify.off('language', this.onLanguage)
    MutableObserver.disposeAll(this.observers)
  }
}

interface LanguageData {
  lang: PLVLanguage
  text: ResourceStr
  onClick: (sdk: PLVLiveSceneSDK) => void
}