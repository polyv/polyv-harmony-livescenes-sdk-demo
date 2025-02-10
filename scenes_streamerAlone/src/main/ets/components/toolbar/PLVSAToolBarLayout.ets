import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import { PLVSAPageDataBus } from '../../common/PLVSAPageDataBus'
import { PLVSALinkMicButton } from '../linkmic/widgets/PLVSALinkMicButton'
import { PLVSAMoreLayout } from '../more/PLVSAMoreLayout'
import { PLVSAToolBarLinkMicLayoutButton } from './widgets/PLVSAToolBarLinkMicLayoutButton'

@Component
export struct PLVSAToolBarLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  private readonly moreLayoutController = new CustomDialogController({
    builder: PLVSAMoreLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  build() {
    Row({ space: 12 }) {
      PLVSAToolBarLinkMicLayoutButton()

      PLVSALinkMicButton()

      Image($r("app.media.plvsa_tool_bar_more_button_icon"))
        .width(36)
        .height(36)
        .onClick(() => {
          this.moreLayoutController.open()
        })
    }
  }
}