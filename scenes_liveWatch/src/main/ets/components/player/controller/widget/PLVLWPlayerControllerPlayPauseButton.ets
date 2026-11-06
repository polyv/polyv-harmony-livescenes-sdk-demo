import { PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, PLVMediaPlayerState, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';

@Component
export struct PLVLWPlayerControllerPlayPauseButton {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isLive: boolean = false
  @State private isPlaying: boolean = false
  @State private isEnabled: boolean = true
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const playerState = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
        .playerState
        .value
      this.isPlaying = playerState !== PLVMediaPlayerState.STATE_PAUSED
        && playerState !== PLVMediaPlayerState.STATE_COMPLETED
      this.isLive = this.sdk.channelData.loginType === PLVLoginType.LIVE
      const isLinkmic = this.layoutDataBus.isLinkmic.value ?? false
      this.isEnabled = !isLinkmic
    }).pushTo(this.observers)
  }

  build() {
    if (this.isEnabled) {
      Image(this.isPlaying ? $r('app.media.plvlw_player_controller_to_pause_icon') : $r('app.media.plvlw_player_controller_to_play_icon'))
        .objectFit(ImageFit.Contain)
        .onClick(() => {
          const player = this.sdk.playerManager.mainMediaPlayer
          if (this.isPlaying) {
            player.pause()
          } else {
            if (this.isLive) {
              player.restart()
            } else {
              player.start()
            }
          }
        })
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}
