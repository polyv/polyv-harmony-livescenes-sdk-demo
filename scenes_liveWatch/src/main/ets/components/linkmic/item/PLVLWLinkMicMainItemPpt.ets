import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { PLVLWPPTNodeContainer } from '../../ppt/node/PLVLWPPTNodeContainer';

@Component
export struct PLVLWLinkMicMainItemPpt {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus

  aboutToAppear(): void {
    this.layoutDataBus.isPPTInLinkmicMainItem.setValue(true)
  }

  aboutToDisappear(): void {
    this.layoutDataBus.isPPTInLinkmicMainItem.setValue(false)
  }

  build() {
    RelativeContainer() {
      PLVLWPPTNodeContainer()
    }
    .width('100%')
    .height('100%')
  }

}