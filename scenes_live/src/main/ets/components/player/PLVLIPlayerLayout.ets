import { PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import {
  DerivedState,
  lateInit,
  MutableObserver,
  PLVLiveStatusEnum,
  PLVMediaPlayerPlayingState,
  PLVMediaPlayerState
} from '@polyvharmony/media-player-sdk'
import { display, window } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'

@Component
export struct PLVLIPlayerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private context = getContext(this) as common.UIAbilityContext
  @State videoWidth: number = 0
  @State videoHeight: number = 0
  @State isNoLive: boolean = true
  @State isToPlayButtonVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.observeMediaPlayerState()
  }

  build() {
    RelativeContainer() {
      // 播放器渲染视图
      XComponent({
        id: `plvli_video_xcomponent`,
        type: "surface",
        libraryname: "plvplayer_xcomponent"
      }) {
      }
      .onLoad((component) => {
        this.sdk.playerManager.startMainMediaPlayerWithComponent(component!)
      })
      .id('plvli_player_xcomponent')
      .width(this.videoWidth)
      .height(this.videoHeight)
      .alignRules({
        center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
        middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
      })

      // 双击暂停播放手势 & 暂停播放按钮
      Stack() {
        Image($r("app.media.plvli_player_to_play_icon"))
          .width(72)
          .height(72)
          .visibility(this.isToPlayButtonVisible ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            this.switchMainPlayerPlayingState()
          })
      }
      .id('plvli_player_play_pause_gesture_layout')
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .gesture(
        TapGesture({ count: 2 })
          .onAction(() => {
            this.switchMainPlayerPlayingState()
          })
      )

      // 暂无直播提示
      Column({ space: 12 }) {
        Image($r("app.media.plvli_player_no_live_placeholder"))
          .width(150)
          .height(116)

        Text($r("app.string.plvli_player_no_live_hint_text"))
          .fontSize(12)
          .fontColor('#e4e4e4')
      }
      .id('plvli_player_no_live_placeholder_layout')
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#00021A')
      .visibility(this.isNoLive ? Visibility.Visible : Visibility.None)
      .hitTestBehavior(HitTestMode.None)
    }
  }

  private observeMediaPlayerState() {
    this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
      .videoSize
      .observe((videoSize) => {
        const containerWidth = px2vp(display.getDefaultDisplaySync().width)
        const containerHeight = px2vp(display.getDefaultDisplaySync().height)
        const containerRatio = containerWidth / containerHeight
        let videoWidth = containerWidth
        let videoHeight = containerHeight
        const videoRatio = videoSize.width() / videoSize.height()
        // fit center
        if (containerRatio > videoRatio) {
          videoWidth = containerHeight / videoSize.height() * videoSize.width()
        } else if (containerRatio < videoRatio) {
          videoHeight = containerWidth / videoSize.width() * videoSize.height()
        }
        this.videoWidth = videoWidth
        this.videoHeight = videoHeight
      })
      .pushTo(this.observers)

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

    const toPlayButtonVisibleState = new DerivedState(() => {
      const isLive = this.sdk.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
        .liveStatus
        .value === PLVLiveStatusEnum.LIVE
      const isPaused = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
        .playerState
        .value === PLVMediaPlayerState.STATE_PAUSED
      return isLive && isPaused
    });
    toPlayButtonVisibleState.observe((isToPlayButtonVisible) => {
      this.isToPlayButtonVisible = isToPlayButtonVisible
    }).pushTo(this.observers)
  }

  private switchMainPlayerPlayingState() {
    const isPlaying = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
      .playingState
      .value === PLVMediaPlayerPlayingState.PLAYING
    if (isPlaying) {
      this.sdk.playerManager.mainMediaPlayer.pause()
    } else {
      this.sdk.playerManager.mainMediaPlayer.restart()
    }
  }

  private async setKeepScreenOn(keepScreenOn: boolean) {
    const lastWindow = await window.getLastWindow(this.context);
    lastWindow.setWindowKeepScreenOn(keepScreenOn);
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}