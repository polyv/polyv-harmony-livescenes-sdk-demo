import { PLVCommonConstants, PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk'
import { lateInit, PLVMediaPlayerState } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWPlayerControllerGestureHandler {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private countClicksInDuration: number = 0
  private countClicksTimeoutId: number | undefined = undefined

  build() {
    Stack()
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .gesture(
        GestureGroup(GestureMode.Exclusive,
          TapGesture({ count: 1 })
            .onAction(() => {
              this.countClicksInDuration++
              if (this.countClicksTimeoutId !== null) {
                clearTimeout(this.countClicksTimeoutId)
              }
              this.countClicksTimeoutId = setTimeout(() => this.handleClicks(), 200)
            })
        )
      )
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