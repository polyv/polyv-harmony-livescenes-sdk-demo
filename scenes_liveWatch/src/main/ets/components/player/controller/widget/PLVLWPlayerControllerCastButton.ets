import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, PLVMediaPlayerPlayingState, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVMediaCastData, PLVMediaCastManager } from '@polyvharmony/media-cast'
import { PLVLWCastDeviceSelectLayout } from './PLVLWCastDeviceSelectLayout'

@Component
export struct PLVLWPlayerControllerCastButton {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isCastEnable: boolean = false
  private readonly deviceSelectDialog = new CustomDialogController({
    builder: PLVLWCastDeviceSelectLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(async () => {
      const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
      const mediaResource = mediaPlayer.getBusinessListenerRegistry().currentMediaResource.value
      const isMediaPlaying = mediaPlayer.getStateListenerRegistry()
        .playingState
        .value === PLVMediaPlayerPlayingState.PLAYING
      if (mediaResource && isMediaPlaying) {
        const castData = new PLVMediaCastData()
        castData.mediaResource = mediaResource
        this.isCastEnable = await PLVMediaCastManager.getInstance().isMediaSupportCast(castData)
      } else {
        this.isCastEnable = false
      }
    }).pushTo(this.observers)
  }

  build() {
    if (this.isCastEnable) {
      Image($r('app.media.plvlw_controller_btn_cast'))
        .padding(8)
        .objectFit(ImageFit.Contain)
        .onClick(() => {
          this.deviceSelectDialog.open()
        })
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}