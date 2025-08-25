import { MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWPlayerControllerDanmuOpenButton {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isDanmuOpen: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.danmuSetting.observe(danmuSetting => {
      this.isDanmuOpen = danmuSetting.show
    }).pushTo(this.observers)
  }

  build() {
    Image(this.isDanmuOpen ? $r('app.media.plvlw_controller_danmu_open') : $r('app.media.plvlw_controller_danmu_closed'))
      .objectFit(ImageFit.Contain)
      .onClick(() => {
        this.layoutDataBus.danmuSetting.mutate({
          show: !this.isDanmuOpen
        })
      })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}