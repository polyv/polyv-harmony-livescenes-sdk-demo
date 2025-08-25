import { PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, PLVMediaPlayerState, watchStates } from '@polyvharmony/media-player-sdk';

@Component
export struct PLVLWPlayerControllerPlayPauseButton {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isLive: boolean = false
  @State private isPlaying: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const isPaused = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
        .playerState
        .value === PLVMediaPlayerState.STATE_PAUSED
      this.isPlaying = !isPaused
      this.isLive = this.sdk.channelData.loginType === PLVLoginType.LIVE
    }).pushTo(this.observers)
  }

  build() {
    Image(this.isPlaying ? $r('app.media.plvlw_player_controller_to_pause_icon') : $r('app.media.plvlw_player_controller_to_play_icon'))
      .objectFit(ImageFit.Contain)
      .onClick(() => {
        if (this.isPlaying) {
          this.sdk.playerManager.mainMediaPlayer.pause()
        } else {
          if (this.isLive) {
            this.sdk.playerManager.mainMediaPlayer.restart()
          } else {
            this.sdk.playerManager.mainMediaPlayer.start()
          }
        }
      })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}