import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';

/** PPT 小窗底部控制栏的渐变衬底，不拦截按钮或拖动手势。 */
@Component
export struct PLVLWPPTFloatingControllerBackground {
  build() {
    RelativeContainer() {
      Row()
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(40)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#00000000', 0], ['#4D000000', 1]]
        })
        .alignRules({
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .hitTestBehavior(HitTestMode.None)
  }
}
