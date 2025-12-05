import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import {
  PLVMediaCastData,
  PLVMediaCastDevice,
  PLVMediaCastManager,
  PLVMediaCastPlayState
} from '@polyvharmony/media-cast';
import {
  lateInit,
  MutableObserver,
  PLVMediaBitRate,
  runCatching,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';

@Component
export struct PLVLWCastControlHandler {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private isCallingStartCast: boolean = false
  private pausePlayerByCast: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.mediaCast.onStartCast.observe((device) => {
      this.handleOnStartCast(device)
    })
      .pushTo(this.observers)
    this.layoutDataBus.mediaCast.onSwitchBitRate.observe((bitRate) => {
      this.handleOnSwitchBitRate(bitRate)
    })
      .pushTo(this.observers)
    watchStates(() => {
      const controller = this.layoutDataBus.mediaCast.castController.value ?? undefined
      const isStopped = controller?.listenerRegistry.playState.value === PLVMediaCastPlayState.STOPPED
      if (isStopped && !this.isCallingStartCast) {
        this.recoverPlayerOnCastStopped()
        this.resetOnCastStopped()
      }
    }).pushTo(this.observers)
  }

  private async handleOnStartCast(device: PLVMediaCastDevice) {
    const player = this.sdk.playerManager.mainMediaPlayer
    const bitRate = this.layoutDataBus.mediaCast.castBitRate.value
      ?? player.getBusinessListenerRegistry().currentMediaBitRate.value
      ?? undefined
    await this.startCast(device, bitRate)
  }

  private async handleOnSwitchBitRate(bitRate: PLVMediaBitRate) {
    const device = this.layoutDataBus.mediaCast.currentCastDevice.value
    if (!device) {
      return
    }
    await this.startCast(device, bitRate)
  }

  private async startCast(
    device: PLVMediaCastDevice,
    bitRate?: PLVMediaBitRate
  ) {
    const player = this.sdk.playerManager.mainMediaPlayer
    const castData = new PLVMediaCastData()
    castData.mediaResource = player.getBusinessListenerRegistry().currentMediaResource.value ?? undefined
    castData.route = player.getBusinessListenerRegistry().currentMediaRoute.value ?? undefined
    castData.bitrate = bitRate
    this.isCallingStartCast = true
    const castResult = await runCatching(PLVMediaCastManager.getInstance().startCast(device, castData))
    if (!castResult.success) {
      this.resetOnCastStopped()
      return
    }
    this.layoutDataBus.mediaCast.currentCastDevice.value = device
    this.layoutDataBus.mediaCast.castController.value = castResult.data
    this.layoutDataBus.mediaCast.castBitRate.value = castData.bitrate
    player.pause()
    this.pausePlayerByCast = true
    this.isCallingStartCast = false
  }

  private recoverPlayerOnCastStopped() {
    if (this.pausePlayerByCast) {
      this.sdk.playerManager.mainMediaPlayer.restart()
    }
    this.pausePlayerByCast = false
  }

  private resetOnCastStopped() {
    this.layoutDataBus.mediaCast.currentCastDevice.value = undefined
    this.layoutDataBus.mediaCast.castController.value = undefined
    this.layoutDataBus.mediaCast.castBitRate.value = undefined
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }

  build() {

  }
}