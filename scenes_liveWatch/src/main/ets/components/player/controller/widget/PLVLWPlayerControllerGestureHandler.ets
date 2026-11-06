import { PLVCommonConstants, PLVLiveSceneSDK, PLVLoginType, PLVTimeUtils } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, PLVMediaPlayerState, watchStates } from '@polyvharmony/media-player-sdk'
import { PlayerSeekPreviewState, PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWPlayerControllerGestureHandler {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private countClicksInDuration: number = 0
  private countClicksTimeoutId: number | undefined = undefined
  @State private seekPreviewStatus: PlayerSeekPreviewState = new PlayerSeekPreviewState()
  private isSeeking: boolean = false
  private seekPosition: number = 0
  private seekDuration: number = 0
  private progressOnStartDrag: number = 0
  private gestureWidth: number = 0
  private gestureHeight: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.playerSeekPreviewState.observe((preview) => {
      const state = new PlayerSeekPreviewState()
      state.source = preview.source
      state.position = preview.position
      state.duration = preview.duration
      this.seekPreviewStatus = state
    }).pushTo(this.observers)
    watchStates(() => {
      if (!this.canSeekProgress()) {
        this.cancelSeek()
      }
    }).pushTo(this.observers)
    // 切换回放视频或横竖屏时，不提交旧手势的目标位置。
    this.sdk.playerManager.mainMediaPlayer.getBusinessListenerRegistry().currentMediaResource.observe(() => {
      this.cancelSeek()
    }).pushTo(this.observers)
    this.layoutDataBus.isPortrait.observe(() => {
      this.cancelSeek()
    }).pushTo(this.observers)
  }

  build() {
    Stack() {
      if (this.seekPreviewStatus.source !== undefined) {
        Row({ space: 4 }) {
          Text(PLVTimeUtils.generateTime(this.seekPreviewStatus.position, true))
            .fontColor(Color.White)
            .fontSize(24)
          Text('/')
            .fontColor('#99FFFFFF')
            .fontSize(14)
          Text(PLVTimeUtils.generateTime(this.seekPreviewStatus.duration, true))
            .fontColor('#99FFFFFF')
            .fontSize(24)
        }
        .padding(12)
        .borderRadius(8)
        .backgroundColor('#99000000')
        .hitTestBehavior(HitTestMode.None)
      }
    }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .onAreaChange((oldArea: Area, newArea: Area) => {
        const width = newArea.width as number
        const height = newArea.height as number
        if (width !== this.gestureWidth || height !== this.gestureHeight) {
          this.cancelSeek()
        }
        this.gestureWidth = width
        this.gestureHeight = height
      })
      .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer): GestureJudgeResult => {
        if (current.getType() === GestureControl.GestureType.PAN_GESTURE && !this.canSeekProgress()) {
          return GestureJudgeResult.REJECT
        }
        return GestureJudgeResult.CONTINUE
      })
      .gesture(
        GestureGroup(GestureMode.Exclusive,
          TapGesture({ count: 1 })
            .onAction(() => {
              this.countClicksInDuration++
              if (this.countClicksTimeoutId !== undefined) {
                clearTimeout(this.countClicksTimeoutId)
              }
              this.countClicksTimeoutId = setTimeout(() => this.handleClicks(), 200)
            }),
          PanGesture({ direction: PanDirection.Horizontal })
            .onActionStart((event: GestureEvent) => {
              this.startSeek(event)
            })
            .onActionUpdate((event: GestureEvent) => {
              this.updateSeek(event)
            })
            .onActionEnd((event: GestureEvent) => {
              if (!this.isSeeking) {
                return
              }
              this.updateSeek(event)
              if (this.isSeeking) {
                const position = this.seekPosition
                this.cancelSeek()
                this.sdk.playerManager.mainMediaPlayer.seek(position)
              }
            })
            .onActionCancel(() => {
              this.cancelSeek()
            })
        )
      )
  }

  private canSeekProgress(): boolean {
    const duration = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry().durationState.value ?? 0
    return this.sdk.channelData.loginType === PLVLoginType.PLAYBACK
      && !(this.layoutDataBus.playerControllerStatus.value?.locked ?? false)
      && !(this.layoutDataBus.mediaCast.isCasting.value ?? false)
      && Number.isFinite(duration) && duration > 0
      && this.gestureWidth > 0
  }

  private startSeek(event: GestureEvent): void {
    if (!this.canSeekProgress()) {
      return
    }
    clearTimeout(this.countClicksTimeoutId)
    this.countClicksTimeoutId = undefined
    this.countClicksInDuration = 0
    const player = this.sdk.playerManager.mainMediaPlayer
    this.seekDuration = player.getStateListenerRegistry().durationState.value ?? 0
    this.progressOnStartDrag = player.getCurrentPosition()
    this.isSeeking = true
    this.updateSeek(event)
  }

  private updateSeek(event: GestureEvent): void {
    if (!this.isSeeking) {
      return
    }
    if (!this.canSeekProgress()) {
      this.cancelSeek()
      return
    }
    // 与播放器项目一致：滑动一屏最多调整三分钟，短视频按总时长计算。
    const delta = event.offsetX / this.gestureWidth * Math.min(this.seekDuration, 3 * 60 * 1000)
    this.seekPosition = Math.round(Math.max(0, Math.min(this.seekDuration, this.progressOnStartDrag + delta)))
    this.layoutDataBus.playerSeekPreviewState.mutate({
      source: 'gesture',
      position: this.seekPosition,
      duration: this.seekDuration
    })
  }

  private cancelSeek(): void {
    this.isSeeking = false
    if (this.layoutDataBus.playerSeekPreviewState.value?.source === 'gesture') {
      this.layoutDataBus.playerSeekPreviewState.setValue(new PlayerSeekPreviewState())
    }
  }

  aboutToDisappear(): void {
    this.cancelSeek()
    clearTimeout(this.countClicksTimeoutId)
    this.countClicksTimeoutId = undefined
    this.countClicksInDuration = 0
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }

  private handleClicks(): void {
    if (this.countClicksInDuration > 1) {
      this.onDoubleClick()
    } else {
      this.onSingleClick()
    }
    this.countClicksInDuration = 0
    clearTimeout(this.countClicksTimeoutId)
    this.countClicksTimeoutId = undefined
  }

  private onSingleClick() {
    const controllerVisible = this.layoutDataBus.playerControllerStatus.value?.visible ?? false
    this.layoutDataBus.playerControllerStatus.mutate({
      visible: !controllerVisible
    })
  }

  private onDoubleClick() {
    const isPlaying = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
      .playerState
      .value === PLVMediaPlayerState.STATE_PLAYING
    const isLive = this.sdk.channelData.loginType === PLVLoginType.LIVE
    if (isPlaying) {
      this.sdk.playerManager.mainMediaPlayer.pause()
    } else {
      if (isLive) {
        this.sdk.playerManager.mainMediaPlayer.restart()
      } else {
        this.sdk.playerManager.mainMediaPlayer.start()
      }
    }
  }
}
