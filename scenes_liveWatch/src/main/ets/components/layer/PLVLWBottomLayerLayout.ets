import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWPlayerLayout } from '../player/PLVLWPlayerLayout';

@Preview
@Component
export struct PLVLWBottomLayerLayout {

  build() {
    RelativeContainer() {
      PLVLWPlayerLayout()
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}