import { PLVMediaCastPlayState } from '@polyvharmony/media-cast'
import { MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWCastPlayPauseButton {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPlaying: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const controller = this.layoutDataBus.mediaCast.castController.value
      const isPlaying = controller?.listenerRegistry.playState.value === PLVMediaCastPlayState.PLAYING
      this.isPlaying = isPlaying
    }).pushTo(this.observers)
  }

  build() {
    Image(this.isPlaying ? $r('app.media.plvlw_player_controller_to_pause_icon') : $r('app.media.plvlw_player_controller_to_play_icon'))
      .objectFit(ImageFit.Contain)
      .onClick(() => {
        const controller = this.layoutDataBus.mediaCast.castController.value
        if (this.isPlaying) {
          controller?.pause()
        } else {
          controller?.play()
        }
      })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}