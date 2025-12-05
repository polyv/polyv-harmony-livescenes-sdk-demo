import { PLVMediaCastManager } from '@polyvharmony/media-cast'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWCastStopButton {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus

  build() {
    Image($r('app.media.plvlw_cast_close'))
      .padding(8)
      .objectFit(ImageFit.Contain)
      .onClick(() => {
        const controller = this.layoutDataBus.mediaCast.castController.value
        PLVMediaCastManager.getInstance().stopCast(controller)
      })
  }
}