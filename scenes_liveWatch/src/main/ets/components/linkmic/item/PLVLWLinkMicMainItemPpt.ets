import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import {
  PLVLWPlayerControllerPPTStatusLayout
} from '../../player/controller/widget/PLVLWPlayerControllerPPTStatusLayout';
import { PLVLWPPTNodeContainer } from '../../ppt/node/PLVLWPPTNodeContainer';

@Component
export struct PLVLWLinkMicMainItemPpt {

  build() {
    RelativeContainer() {
      PLVLWPPTNodeContainer()

      PLVLWPlayerControllerPPTStatusLayout()
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          bottom: 12
        })
    }
    .width('100%')
    .height('100%')
  }

}