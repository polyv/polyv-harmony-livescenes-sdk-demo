import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWPlayerControllerVariantState } from '../vo/PLVLWPlayerControllerVariantState';

/** 播放器控制栏边缘渐变，随皮肤显隐，不拦截触摸事件。 */
@Component
export struct PLVLWPlayerControllerGradientBackground {
  @Prop variantState: PLVLWPlayerControllerVariantState = new PLVLWPlayerControllerVariantState()
  @Prop isVisible: boolean = false

  build() {
    if (this.isVisible && !this.variantState.isCasting) {
      RelativeContainer() {
        if (!this.variantState.isPortrait && !this.variantState.isLocked) {
          Row()
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(70)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['#4D000000', 0], ['#00000000', 1]]
            })
            .alignRules({
              start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
              top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
            })
        }
        if ((this.variantState.isPortrait && !this.variantState.isPlayerFullscreen) ||
          (!this.variantState.isPortrait && (!this.variantState.isLocked || !this.variantState.isLive))) {
          Row()
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(70)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['#00000000', 0], ['#4D000000', 1]]
            })
            .alignRules({
              start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
              bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
            })
        }
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .hitTestBehavior(HitTestMode.None)
    }
  }
}
