import { PLVUtils } from '@polyvharmony/live-scenes-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWPlayerControllerToggleOrientationButton {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus

  build() {
    Image($r('app.media.plvlw_player_controller_fullscreen'))
      .objectFit(ImageFit.Contain)
      .onClick(() => {
        const isPortrait = this.layoutDataBus.isPortrait.value ?? true
        if (isPortrait) {
          PLVUtils.changeOrientation(true)
        } else {
          PLVUtils.changeOrientation(false)
        }
      })
  }
}