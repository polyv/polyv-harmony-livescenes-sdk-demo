import { PLVCommonConstants, PLVNodeController } from '@polyvharmony/live-scenes-sdk'
import { Mutex } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWPPTNodeContainer {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private readonly pptViewNodeMutex = new Mutex()
  @State private pptViewNodeController: PLVNodeController | undefined = undefined

  async aboutToAppear(): Promise<void> {
    await this.pptViewNodeMutex.withLock(null, async () => {
      this.pptViewNodeController = await this.layoutDataBus.pptController.require()
    })
  }

  build() {
    if (this.pptViewNodeController) {
      NodeContainer(this.pptViewNodeController)
        .hitTestBehavior(HitTestMode.Transparent)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
    }
  }

  async aboutToDisappear(): Promise<void> {
    await this.pptViewNodeMutex.withLock(null, async () => {
      if (this.pptViewNodeController) {
        this.layoutDataBus.pptController.release(this.pptViewNodeController)
        this.pptViewNodeController = undefined
      }
    })
  }
}