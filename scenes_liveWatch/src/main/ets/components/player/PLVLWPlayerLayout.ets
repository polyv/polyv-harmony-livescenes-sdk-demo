import { PLVCommonConstants, PLVLiveScene, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import {
  lateInit,
  MutableObserver,
  PLVLiveStatusEnum,
  PLVMediaPlayerAppContext,
  PLVMediaPlayerBusinessErrorEnum,
  PLVMediaPlayerPlayingState,
  Rect,
  watchStates
} from '@polyvharmony/media-player-sdk'
import { display, window } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus'
import { PLVLWPlayerControllerLayout } from './controller/PLVLWPlayerControllerLayout'
import { PLVLWPPTPlayerExchangeView } from '../ppt/node/PLVLWPPTPlayerExchangeView'
import { PLVLWDanmuLayout } from './danmu/PLVLWDanmuLayout'

@Component
export struct PLVLWPlayerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private context = getContext(this) as common.UIAbilityContext
  @State private containerWidth: number = 0
  @State private containerHeight: number = 0
  @State private containerMarginTop: number = 0
  @State private videoWidth: Length = 0
  @State private videoHeight: Length = 0
  @State private isNoLive: boolean = true
  @State isPPTToMainScreen: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.observeMediaPlayerState()
  }

  build() {
    RelativeContainer() {
      // 播放器渲染视图
      PLVLWPPTPlayerExchangeView({ isMainScreenUse: true })
        .width(this.videoWidth)
        .height(this.videoHeight)
        .alignRules({
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })

      // 弹幕
      PLVLWDanmuLayout()
        .id('plvlw_danmu_layout')
        .hitTestBehavior(HitTestMode.None)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)

      // 暂无直播提示
      Column({ space: 12 }) {
        Image($r("app.media.plvlw_player_no_live_placeholder"))
          .width(150)
          .height(116)

        Text($r("app.string.plvlw_player_no_live_hint_text"))
          .fontSize(12)
          .fontColor('#e4e4e4')
      }
      .id('plvlw_player_no_live_placeholder_layout')
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#00021A')
      .visibility(this.isNoLive ? Visibility.Visible : Visibility.None)
      .hitTestBehavior(HitTestMode.None)

      // 播放器异常提示
      PLVLWPlayerErrorOverlayLayout()
        .id('plvlw_player_error_overlay_layout')
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
        .hitTestBehavior(HitTestMode.None)

      // 播放器皮肤
      PLVLWPlayerControllerLayout()
        .id('plvlw_player_controller_layout')
        .hitTestBehavior(HitTestMode.Transparent)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
    }
    .width(this.containerWidth)
    .height(this.containerHeight)
    .backgroundColor($r('app.color.plvlw_player_background'))
    .margin({
      top: this.containerMarginTop
    })
  }

  private observeMediaPlayerState() {
    watchStates(() => {
      const isPortrait = this.layoutDataBus.isPortrait.value ?? true
      const isPortraitTemplate = this.sdk.channelData.liveScene === PLVLiveScene.PORTRAIT_TEMPLATE
      const videoSize = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
        .videoSize
        .value ?? new Rect()
      const containerLocation = this.layoutDataBus.playerLocation.value ?? new Rect()
      const isPortraitVideo = videoSize.height() > videoSize.width()
      this.isPPTToMainScreen = this.layoutDataBus.isPPTToMainScreen.value ?? false
      const isFullscreen = !isPortrait || (isPortraitTemplate && isPortraitVideo && !this.isPPTToMainScreen)

      this.layoutDataBus.playerFullscreen.setValue(isFullscreen)

      this.containerWidth = isFullscreen ? px2vp(display.getDefaultDisplaySync().width) : containerLocation.width()
      this.containerHeight = isFullscreen ? px2vp(display.getDefaultDisplaySync().height) : containerLocation.height()
      this.containerMarginTop = isFullscreen ? 0 : containerLocation.top

      this.layoutDataBus.bottomLayerViewTouchArea.setValue(new Rect({
        left: containerLocation.left,
        top: this.containerMarginTop,
        right: isPortrait && isFullscreen ? 0 : this.containerWidth + containerLocation.left,
        bottom: isPortrait && isFullscreen ? 0 : this.containerHeight + this.containerMarginTop
      }))

      const containerRatio = this.containerWidth / this.containerHeight
      let videoWidth = this.containerWidth
      let videoHeight = this.containerHeight
      const videoRatio = videoSize.width() / videoSize.height()
      // fit center
      if (containerRatio > videoRatio) {
        videoWidth = this.containerHeight / videoSize.height() * videoSize.width()
      } else if (containerRatio < videoRatio) {
        videoHeight = this.containerWidth / videoSize.width() * videoSize.height()
      }
      this.videoWidth = this.isPPTToMainScreen ? PLVCommonConstants.FULL_PERCENT : videoWidth
      this.videoHeight = this.isPPTToMainScreen ? PLVCommonConstants.FULL_PERCENT : videoHeight
    }).pushTo(this.observers)

    this.sdk.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
      .liveStatus
      .observe((liveStatus) => {
        this.isNoLive = liveStatus === PLVLiveStatusEnum.NO_LIVE
      })
      .pushTo(this.observers)

    this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
      .playingState
      .observe((playingState) => {
        this.setKeepScreenOn(playingState === PLVMediaPlayerPlayingState.PLAYING)
      })
      .pushTo(this.observers)
  }

  private async setKeepScreenOn(keepScreenOn: boolean) {
    const lastWindow = await window.getLastWindow(this.context);
    lastWindow.setWindowKeepScreenOn(keepScreenOn);
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
    this.sdk.playerManager.mainMediaPlayer.pause()
  }
}

@Component
struct PLVLWPlayerErrorOverlayLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State error: PLVMediaPlayerBusinessErrorEnum | null = null
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
      .businessErrorState
      .observe((error) => {
        this.error = error
      })
      .pushTo(this.observers)
  }

  build() {
    if (this.error !== null) {
      Column({ space: 12 }) {
        Image($r("app.media.plvlw_player_error_placeholder"))
          .width(150)
          .height(116)

        Text(this.getErrorMessage())
          .fontSize(12)
          .fontColor('#e4e4e4')

        Text($r("app.string.plvlw_player_error_action_refresh"))
          .fontSize(12)
          .fontColor('#e4e4e4')
          .borderRadius(30)
          .backgroundColor('#4880f6')
          .padding({
            left: 12,
            right: 12,
            top: 4,
            bottom: 4
          })
          .onClick(() => {
            this.sdk.playerManager.mainMediaPlayer.restart()
          })
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#00021A')
      .hitTestBehavior(HitTestMode.None)
    }
  }

  private getErrorMessage(): string {
    if (this.error === null) {
      return ""
    }
    const errorCodeMessage = PLVMediaPlayerAppContext.getString($r('app.string.plvlw_player_error_message_code'), this.error.code)
    if (this.error.code === PLVMediaPlayerBusinessErrorEnum.ERROR_RESTRICT_WATCH.code) {
      return PLVMediaPlayerAppContext.getString($r('app.string.plvlw_player_error_message_restricted'), errorCodeMessage)
    } else {
      return PLVMediaPlayerAppContext.getString($r('app.string.plvlw_player_error_message_general'), errorCodeMessage)
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}