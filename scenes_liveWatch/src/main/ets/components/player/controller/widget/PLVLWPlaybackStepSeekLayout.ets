import { PLVLiveSceneSDK, PLVPlaybackSeekPolicy } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'
import { PLVLWPlayerControllerPlayPauseButton } from './PLVLWPlayerControllerPlayPauseButton'

/** 共用回放中央控制，不覆盖按钮以外的画面，原有业务浮层仍在上方。 */
@Component
export struct PLVLWPlaybackStepSeekLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isVisible: boolean = false
  @State private stepSeconds: number = 15
  private pendingPosition?: number = undefined
  private submittedPosition?: number = undefined
  private pendingTimeout?: number = undefined
  private maxPlayedPosition: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const player = this.sdk.playerManager.mainMediaPlayer
    watchStates(() => {
      this.stepSeconds = this.sdk.channelData.playbackSeekConfig.value?.stepSeconds ?? 15
      if (!this.sdk.playerManager.isPlaybackSeekButtonsEnabled()) {
        this.clearPendingSeek()
      }
      const progress = player.getStateListenerRegistry().progressState.value ?? 0
      if (this.pendingPosition === undefined && Number.isFinite(progress)) {
        this.maxPlayedPosition = Math.max(this.maxPlayedPosition, progress)
      }
      this.isVisible = this.sdk.playerManager.isPlaybackSeekButtonsEnabled()
        && (this.layoutDataBus.playerControllerStatus.value?.visible ?? false)
        && !(this.layoutDataBus.playerControllerStatus.value?.locked ?? false)
        && !(this.layoutDataBus.mediaCast.isCasting.value ?? false)
        && !(this.layoutDataBus.isLinkmic.value ?? false)
        && this.layoutDataBus.playerSeekPreviewState.value?.source === undefined
    }).pushTo(this.observers)
    player.getEventListenerRegistry().onSeekCompleteEvent.observe(() => {
      const submitted = this.submittedPosition
      if (submitted === undefined) return
      this.submittedPosition = undefined
      if (this.pendingPosition === submitted) {
        this.clearPendingSeek()
      } else {
        this.submitPendingSeek()
      }
    }).pushTo(this.observers)
    player.getBusinessListenerRegistry().currentMediaResource.observe(() => {
      this.clearPendingSeek()
      this.maxPlayedPosition = 0
    }).pushTo(this.observers)
    this.layoutDataBus.playerSeekPreviewState.observe((state) => {
      if (state?.source !== undefined) {
        this.clearPendingSeek()
      }
    }).pushTo(this.observers)
  }

  @Builder
  private seekButton(forward: boolean) {
    Stack() {
      Image(forward ? $r('app.media.plvlw_player_seek_forward') : $r('app.media.plvlw_player_seek_backward'))
        .width(40)
        .height(40)
        .hitTestBehavior(HitTestMode.None)
      Text(`${this.stepSeconds}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(56)
    .height(56)
    // 此节点自身接收点击，阻止下层画面 Tap/Pan 手势参与；图标、文字无需命中。
    .hitTestBehavior(HitTestMode.Block)
    .accessibilityText(forward ? $r('app.string.plvlw_player_seek_forward', this.stepSeconds)
      : $r('app.string.plvlw_player_seek_backward', this.stepSeconds))
    .onClick(() => this.seekByStep(forward))
  }

  build() {
    if (this.isVisible) {
      Row({ space: 20 }) {
        this.seekButton(false)
        PLVLWPlayerControllerPlayPauseButton({ exclusiveTouch: true })
          .width(44)
          .height(44)
        this.seekButton(true)
      }
      .width(196)
      .height(56)
      .hitTestBehavior(HitTestMode.Default)
    }
  }

  private seekByStep(forward: boolean): void {
    if (!this.isVisible || !this.sdk.playerManager.isPlaybackSeekButtonsEnabled()) {
      return
    }
    const player = this.sdk.playerManager.mainMediaPlayer
    const duration = player.getStateListenerRegistry().durationState.value ?? 0
    if (!Number.isFinite(duration) || duration <= 0) {
      return
    }
    this.maxPlayedPosition = Math.max(this.maxPlayedPosition, player.getCurrentPosition())
    let target = PLVPlaybackSeekPolicy.target(player.getCurrentPosition(), this.pendingPosition,
      duration, this.stepSeconds, forward)
    if (this.sdk.channelData.liveDetail?.playbackProgressBarOperationType === 'dragHistoryOnly') {
      target = Math.min(target, this.maxPlayedPosition)
    }
    this.pendingPosition = target
    this.submitPendingSeek()
  }

  private submitPendingSeek(): void {
    if (this.submittedPosition !== undefined || this.pendingPosition === undefined) return
    if (!this.sdk.playerManager.isPlaybackSeekButtonsEnabled()) {
      this.clearPendingSeek()
      return
    }
    const player = this.sdk.playerManager.mainMediaPlayer
    const target = this.pendingPosition
    if (player.getCurrentPosition() === target) {
      this.clearPendingSeek()
      return
    }
    // 串行提交，完成回调只确认当前请求，不按瞬时进度误差判断。
    this.submittedPosition = target
    if (this.pendingTimeout !== undefined) {
      clearTimeout(this.pendingTimeout)
    }
    this.pendingTimeout = setTimeout(() => this.clearPendingSeek(), 10000)
    // 只定位，不调用 start，暂停时保持暂停；结尾直接使用 duration。
    player.seek(target)
  }

  private clearPendingSeek(): void {
    this.pendingPosition = undefined
    this.submittedPosition = undefined
    if (this.pendingTimeout !== undefined) {
      clearTimeout(this.pendingTimeout)
      this.pendingTimeout = undefined
    }
  }

  aboutToDisappear(): void {
    this.clearPendingSeek()
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}
