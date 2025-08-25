import { PLVCommonConstants, PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk';
import { isLiteralTrue, lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../../common/PLVLWLayoutDataBus';
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common';

@Component
export struct PLVLWMoreSpeedAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback
  @State private isVisible: boolean = false
  private readonly speedSelectDialog = new CustomDialogController({
    builder: PLVLWMoreSpeedSelectDialog(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  aboutToAppear(): void {
    const channelSupportSpeedControl = isLiteralTrue(this.sdk.channelData.liveDetail?.playbackMultiplierEnabled)
    const isPlayback = this.sdk.channelData.loginType === PLVLoginType.PLAYBACK
    this.isVisible = channelSupportSpeedControl && isPlayback
  }

  build() {
    MoreSettingActionView({
      icon: $r('app.media.plvlw_more_speed_icon'),
      title: $r('app.string.plvlw_player_speed')
    })
      .onClick(() => {
        this.moreSettingActionCallback.hideMoreSettingDialog?.()
        this.speedSelectDialog.open()
      })
      .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
  }

  aboutToDisappear(): void {
  }
}

const supportSpeeds = ['2.0', '1.5', '1.25', '1.0', '0.5']

@CustomDialog
export struct PLVLWMoreSpeedSelectDialog {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private currentSpeed: number = 1.0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
    watchStates(() => {
      const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
      this.currentSpeed = mediaPlayer.getStateListenerRegistry().speed.value ?? 1.0
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvlw_player_speed'))
        .id('plvlw_more_speed_title')
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
          supportSpeeds,
          (speed: string) => {
            ListItem() {
              Text(`${speed}x`)
                .width(PLVCommonConstants.FULL_PERCENT)
                .height(56)
                .textAlign(TextAlign.Center)
                .fontSize(14)
                .fontColor(parseFloat(speed) === this.currentSpeed
                  ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_text')
                  : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_text')
                )
                .border({
                  radius: 8,
                  color: parseFloat(speed) === this.currentSpeed
                    ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_stroke')
                    : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_solid'),
                  width: 1
                })
                .backgroundColor(parseFloat(speed) === this.currentSpeed
                  ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_solid')
                  : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_solid')
                )
            }
            .onClick(() => {
              this.sdk.playerManager.mainMediaPlayer.setSpeed(parseFloat(speed))
              this.controller.close()
            })
          }
        )
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .padding({
        left: 16,
        right: 16
      })
      .alignRules({
        top: { anchor: 'plvlw_more_speed_title', align: VerticalAlign.Bottom },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .margin({
        top: 27,
        bottom: 46
      })
    }
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : 375)
    .height(this.isPortrait ? 422 : PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_common_popup_background'))
    .borderRadius({
      topLeft: 16,
      topRight: this.isPortrait ? 16 : 0,
      bottomLeft: this.isPortrait ? 0 : 16
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}