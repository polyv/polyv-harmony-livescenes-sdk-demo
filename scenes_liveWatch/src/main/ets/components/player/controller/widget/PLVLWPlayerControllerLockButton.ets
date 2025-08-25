import { MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWPlayerControllerLockButton {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isLocked: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.playerControllerStatus.observe(status => {
      this.isLocked = status.locked
    }).pushTo(this.observers)
  }

  build() {
    Image(this.isLocked ? $r('app.media.plvlw_controller_lock') : $r('app.media.plvlw_controller_unlock'))
      .onClick(() => {
        this.layoutDataBus.playerControllerStatus.mutate({
          locked: !this.isLocked
        })
      })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}