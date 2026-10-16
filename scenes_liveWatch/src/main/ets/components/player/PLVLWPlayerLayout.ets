import { PLVCommonConstants, PLVLiveScene, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import {
  lateInit,
  MutableObserver,
  PLVLiveStatusEnum,
  PLVMediaOutputMode,
  PLVMediaPlayerAppContext,
  PLVMediaPlayerBusinessErrorEnum,
  PLVMediaPlayerPlayingState,
  Rect,
  watchStates
} from '@polyvharmony/media-player-sdk'
import { window } from '@kit.ArkUI'
import { AbilityLifecycleCallback, common, UIAbility, wantAgent } from '@kit.AbilityKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { avSession } from '@kit.AVSessionKit'
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus'
import { PLVLWPlayerControllerLayout } from './controller/PLVLWPlayerControllerLayout'
import { PLVLWPPTPlayerExchangeView } from '../ppt/node/PLVLWPPTPlayerExchangeView'
import { PLVLWDanmuLayout } from './danmu/PLVLWDanmuLayout'
import { PLVLWPiPManager } from '../../common/PLVLWPiPManager'

@Component
export struct PLVLWPlayerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  /** 是否允许应用进入后台后继续播放音频，默认开启。 */
  @Prop backgroundAudioPlaybackEnabled: boolean = true
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
      PLVLWPlayerKeepBackgroundTask({
        backgroundAudioPlaybackEnabled: this.backgroundAudioPlaybackEnabled
      })

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

      if (!this.isPPTToMainScreen) {
        // 音频模式提示
        PLVLWPlayerAudioModeLayout({
          containerWidth: this.containerWidth,
          containerHeight: this.containerHeight,
          isNoLive: this.isNoLive
        })
          .id('plvlw_player_audio_mode_layout')
          .hitTestBehavior(HitTestMode.Transparent)
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(PLVCommonConstants.FULL_PERCENT)
      }

      // 播放器异常提示
      PLVLWPlayerErrorLayout()
        .id('plvlw_player_error_layout')
        .hitTestBehavior(HitTestMode.Transparent)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)

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
      const layoutArea = this.layoutDataBus.layoutArea.value ?? new Rect()
      if (layoutArea.width() <= 0 || layoutArea.height() <= 0) {
        return
      }
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

      this.containerWidth = isFullscreen ? layoutArea.width() : containerLocation.width()
      this.containerHeight = isFullscreen ? layoutArea.height() : containerLocation.height()
      this.containerMarginTop = isFullscreen ? 0 : Math.max(0, containerLocation.top - layoutArea.top)

      this.layoutDataBus.bottomLayerViewTouchArea.setValue(new Rect({
        left: layoutArea.left,
        top: layoutArea.top + this.containerMarginTop,
        right: isPortrait && isFullscreen ? layoutArea.left : this.containerWidth + layoutArea.left,
        bottom: isPortrait && isFullscreen ? layoutArea.top : this.containerHeight + this.containerMarginTop + layoutArea.top
      }))

      const containerRatio = this.containerWidth / this.containerHeight
      let videoWidth = this.containerWidth
      let videoHeight = this.containerHeight
      const videoRatio = videoSize.width() > 0 && videoSize.height() > 0
        ? videoSize.width() / videoSize.height() : containerRatio
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
    if (!PLVLWPiPManager.instance.shouldKeepPlayerAlive(this.sdk.uniqueId)) {
      this.sdk.playerManager.mainMediaPlayer.pause()
    }
  }
}

@Component
struct PLVLWPlayerKeepBackgroundTask {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Prop backgroundAudioPlaybackEnabled: boolean = true
  private readonly context = getContext(this) as common.UIAbilityContext
  private lifecycleCallbackId: number = -1
  private lifecycleCallback: AbilityLifecycleCallback | undefined
  private pausedWhenEnterBackground: boolean = false
  private backgroundTaskStarted: boolean = false
  private mediaSession: avSession.AVSession | undefined
  private observers: MutableObserver[] = []

  async aboutToAppear(): Promise<void> {
    this.registerAbilityLifecycleCallback()
    if (this.backgroundAudioPlaybackEnabled) {
      await this.startMediaSession()
      await this.startBackgroundTask()
    }
  }

  build() {
  }

  private registerAbilityLifecycleCallback(): void {
    const player = this.sdk.playerManager.mainMediaPlayer
    this.lifecycleCallback = new PLVLWAbilityLifecycleCallback(
      () => {
        if (this.backgroundAudioPlaybackEnabled) {
          return
        }
        this.pausedWhenEnterBackground = player.getStateListenerRegistry().playingState.value ===
          PLVMediaPlayerPlayingState.PLAYING
        if (this.pausedWhenEnterBackground) {
          player.pause()
        }
      },
      () => {
        if (this.pausedWhenEnterBackground) {
          this.pausedWhenEnterBackground = false
          player.start()
        }
      }
    )
    this.lifecycleCallbackId = this.context.getApplicationContext()
      .on('abilityLifecycle', this.lifecycleCallback)
  }

  private async startBackgroundTask(): Promise<void> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    }
    const wantAgentObject = await wantAgent.getWantAgent(wantAgentInfo)
    await backgroundTaskManager.startBackgroundRunning(
      this.context,
      backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
      wantAgentObject
    )
    this.backgroundTaskStarted = true
  }

  private async startMediaSession(): Promise<void> {
    const player = this.sdk.playerManager.mainMediaPlayer
    this.mediaSession = await avSession.createAVSession(
      this.context,
      `PLVLWPlayer-${this.sdk.uniqueId}`,
      'video'
    )
    this.mediaSession.on('play', () => player.start())
    this.mediaSession.on('pause', () => player.pause())
    await this.mediaSession.activate()

    player.getStateListenerRegistry().playingState.observe((playingState) => {
      this.mediaSession?.setAVPlaybackState({
        state: playingState === PLVMediaPlayerPlayingState.PLAYING
          ? avSession.PlaybackState.PLAYBACK_STATE_PLAY
          : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
        speed: 1
      })
    }).pushTo(this.observers)
  }

  async aboutToDisappear(): Promise<void> {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
    if (this.lifecycleCallbackId >= 0) {
      await this.context.getApplicationContext().off('abilityLifecycle', this.lifecycleCallbackId)
      this.lifecycleCallbackId = -1
      this.lifecycleCallback = undefined
    }
    if (this.backgroundTaskStarted) {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      this.backgroundTaskStarted = false
    }
    if (this.mediaSession !== undefined) {
      await this.mediaSession.deactivate()
      await this.mediaSession.destroy()
      this.mediaSession = undefined
    }
  }
}

class PLVLWAbilityLifecycleCallback extends AbilityLifecycleCallback {
  private readonly backgroundCallback: () => void
  private readonly foregroundCallback: () => void

  constructor(
    backgroundCallback: () => void,
    foregroundCallback: () => void
  ) {
    super()
    this.backgroundCallback = backgroundCallback
    this.foregroundCallback = foregroundCallback
  }

  onAbilityCreate(ability: UIAbility): void {
  }

  onWindowStageCreate(ability: UIAbility, windowStage: window.WindowStage): void {
  }

  onWindowStageActive(ability: UIAbility, windowStage: window.WindowStage): void {
  }

  onWindowStageInactive(ability: UIAbility, windowStage: window.WindowStage): void {
  }

  onWindowStageDestroy(ability: UIAbility, windowStage: window.WindowStage): void {
  }

  onAbilityDestroy(ability: UIAbility): void {
  }

  onAbilityForeground(ability: UIAbility): void {
    this.foregroundCallback()
  }

  onAbilityBackground(ability: UIAbility): void {
    this.backgroundCallback()
  }

  onAbilityContinue(ability: UIAbility): void {
  }
}

@Component
struct PLVLWPlayerAudioModeLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Prop containerWidth: number = 0
  @Prop containerHeight: number = 0
  @Prop isNoLive: boolean = true
  @State private isAudioMode: boolean = false
  @State private hasPlayerError: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const businessListenerRegistry = this.sdk.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
      const outputMode = businessListenerRegistry
        .currentMediaOutputMode
        .value ?? PLVMediaOutputMode.AUDIO_VIDEO
      this.isAudioMode = outputMode === PLVMediaOutputMode.AUDIO_ONLY
      this.hasPlayerError = businessListenerRegistry.businessErrorState.value !== null
    }).pushTo(this.observers)
  }

  build() {
    if (this.isAudioMode && !this.isNoLive && !this.hasPlayerError) {
      Column() {
        Stack({ alignContent: Alignment.Bottom }) {
          Image($r('app.media.plvlw_bg_player_audio_mode'))
            .width(this.audioModeImageWidth())
            .aspectRatio(560 / 444)
            .objectFit(ImageFit.Contain)

          if (!this.isSmallWindow()) {
            Text($r('app.string.plvlw_player_video_play_mode'))
              .id('plvlw_player_audio_mode_play_video_button')
              .width(this.isLandscape() ? 96 : 80)
              .height(this.isLandscape() ? 30 : 24)
              .margin({ bottom: this.isLandscape() ? 16 : 0 })
              .offset({ y: 16 })
              .fontSize(12)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .borderRadius(14)
              .border({
                width: 0.5,
                color: Color.White
              })
              .backgroundColor('#1AFFFFFF')
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Up) {
                  this.sdk.playerManager.mainMediaPlayer.changeMediaOutputMode(PLVMediaOutputMode.AUDIO_VIDEO)
                }
              })
          }
        }
        .width(this.audioModeImageWidth())
        .height(this.audioModeImageWidth() / (560 / 444))
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .hitTestBehavior(HitTestMode.Transparent)
      .backgroundColor('#1B202D')
    }
  }

  private audioModeImageWidth(): number {
    const width = Math.max(this.containerWidth, 0)
    if (this.isSmallWindow()) {
      return width * 0.6
    }
    return width * (this.isLandscape() ? 0.38 : 0.44)
  }

  private isLandscape(): boolean {
    return this.containerWidth > this.containerHeight
  }

  private isSmallWindow(): boolean {
    return this.containerWidth < 240 || this.containerHeight < 140
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVLWPlayerErrorLayout {
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

    this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
      .playingState
      .observe((playingState) => {
        if (playingState === PLVMediaPlayerPlayingState.PLAYING) {
          this.error = null
        }
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
          .id('plvlw_player_error_refresh_button')
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
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Up) {
              this.sdk.playerManager.mainMediaPlayer.restart()
            }
          })
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#00021A')
      .hitTestBehavior(HitTestMode.Transparent)
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
