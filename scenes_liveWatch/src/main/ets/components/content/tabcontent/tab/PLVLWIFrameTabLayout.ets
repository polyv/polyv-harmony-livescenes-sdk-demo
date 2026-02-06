import { PLVCallback, PLVChannelData, PLVCommonConstants, PLVSimpleWeb, PLVWebController } from '@polyvharmony/live-scenes-sdk';
import { PLVLWCommonDef } from '../../../../common/PLVLWCommonDef';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';

@Preview
@Component
export struct PLVLWIFrameTabLayout {
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private webController: PLVWebController = new PLVWebController()
  @State iframeContent: string | undefined = this.channelData?.getMenuIFrameContent()
  private isLayoutVisibleArea: boolean = false
  private backHandler?: PLVCallback<void, boolean>

  aboutToAppear(): void {
    this.layoutDataBus.registerBackPressedHandler(this.backHandler = ()=>{
      if (this.isLayoutVisibleArea && this.webController.accessBackward()) {
        this.webController.backward()
        return true
      }
      return false
    }, PLVLWCommonDef.BACK_PRIORITY_IFRAME_TAB_CONTENT)
  }

  aboutToDisappear(): void {
    this.layoutDataBus.unregisterBackPressedHandler(this.backHandler)
  }

  build() {
    Stack() {
      PLVSimpleWeb({ controller: this.webController, src: this.channelData?.buildIFrameLinkParams(this.iframeContent ?? '') })
    }
    .onVisibleAreaChange([0.0, 1.0], (isExpanding: boolean, currentRatio: number) => {
      this.isLayoutVisibleArea = isExpanding
    })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}