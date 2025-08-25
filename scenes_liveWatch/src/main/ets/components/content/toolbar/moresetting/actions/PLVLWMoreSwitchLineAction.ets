import { PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import {
  deepEquals,
  lateInit,
  MutableObserver,
  PLVMediaPlayerPlayingState,
  PLVMediaRoute,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../../common/PLVLWLayoutDataBus';
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common';

@Component
export struct PLVLWMoreSwitchLineAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback
  @State private isVisible: boolean = false
  private readonly lineSelectDialog = new CustomDialogController({
    builder: LineSelectDialog(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
      const supportLines = mediaPlayer.getBusinessListenerRegistry().supportMediaRoutes.value ?? []
      const isMediaPlaying = mediaPlayer.getStateListenerRegistry()
        .playingState
        .value === PLVMediaPlayerPlayingState.PLAYING
      this.isVisible = supportLines.length > 0 && isMediaPlaying
    }).pushTo(this.observers)
  }

  build() {
    MoreSettingActionView({
      icon: $r('app.media.plvlw_more_switch_line_icon'),
      title: $r('app.string.plvlw_player_route')
    })
      .onClick(() => {
        this.moreSettingActionCallback.hideMoreSettingDialog?.()
        this.lineSelectDialog.open()
      })
      .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@CustomDialog
struct LineSelectDialog {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private supportLines: PLVMediaRoute[] = []
  @State private currentLine: PLVMediaRoute | null = null
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
    watchStates(() => {
      const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
      this.supportLines = mediaPlayer.getBusinessListenerRegistry().supportMediaRoutes.value ?? []
      this.currentLine = mediaPlayer.getBusinessListenerRegistry().currentMediaRoute.value ?? null
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      Text($r('app.string.plvlw_player_route'))
        .id('plvlw_more_switch_line_title')
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
          this.supportLines,
          (line: PLVMediaRoute) => {
            ListItem() {
              Text(line.name)
                .width(PLVCommonConstants.FULL_PERCENT)
                .height(56)
                .textAlign(TextAlign.Center)
                .fontSize(14)
                .fontColor(deepEquals(line, this.currentLine)
                  ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_text')
                  : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_text')
                )
                .border({
                  radius: 8,
                  color: deepEquals(line, this.currentLine)
                    ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_stroke')
                    : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_solid'),
                  width: 1
                })
                .backgroundColor(deepEquals(line, this.currentLine)
                  ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_solid')
                  : $r('app.color.plvlw_more_setting_action_popup_layout_not_selected_item_solid')
                )
            }
            .onClick(() => {
              this.sdk.playerManager.mainMediaPlayer.changeRoute(line)
              this.controller.close()
            })
          },
          (line: PLVMediaRoute) => line.index.toString()
        )
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .padding({
        left: 16,
        right: 16
      })
      .alignRules({
        top: { anchor: 'plvlw_more_switch_line_title', align: VerticalAlign.Bottom },
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
    MutableObserver.disposeAll(this.observers)
  }
}