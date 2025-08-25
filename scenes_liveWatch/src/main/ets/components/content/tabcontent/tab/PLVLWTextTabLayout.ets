import { PLVCallback, PLVChannelData, PLVCommonConstants, PLVSimpleWeb, PLVUtils, PLVWebController, PLVWebUtils } from '@polyvharmony/live-scenes-sdk';
import { PLVLWCommonDef } from '../../../../common/PLVLWCommonDef';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';

@Preview
@Component
export struct PLVLWTextTabLayout {
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private webController: PLVWebController = new PLVWebController()
  @State textContent: string | undefined = this.channelData?.getMenuTextContent()
  private isLayoutVisibleArea: boolean = false
  private backHandler?: PLVCallback<void, boolean>

  aboutToAppear(): void {
    this.webController
      .onControllerAttached(() => {
        this.webController.loadHtmlData(PLVWebUtils.toWebViewContent(this.textContent, PLVUtils.colorResourceToHex($r('app.color.plvlw_web_content_color'))))
      })
    this.layoutDataBus.registerBackPressedHandler(this.backHandler = ()=>{
      if (this.isLayoutVisibleArea && this.webController.accessBackward()) {
        this.webController.backward()
        return true
      }
      return false
    }, PLVLWCommonDef.BACK_PRIORITY_TEXT_TAB_CONTENT)
  }

  aboutToDisappear(): void {
    this.layoutDataBus.unregisterBackPressedHandler(this.backHandler)
  }

  build() {
    Stack() {
      PLVSimpleWeb({ controller: this.webController, src: '' })
    }
    .onVisibleAreaChange([0.0, 1.0], (isExpanding: boolean, currentRatio: number) => {
      this.isLayoutVisibleArea = isExpanding
    })
    .padding({ left: 16, right: 16 })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}