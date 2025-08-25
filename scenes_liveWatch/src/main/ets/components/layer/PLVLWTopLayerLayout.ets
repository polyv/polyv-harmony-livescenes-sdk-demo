import { PLVCommonConstants, PLVUtils } from '@polyvharmony/live-scenes-sdk';
import { MutableObserver, watchStates, Rect } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus';
import { PLVLWChatInputLayout } from '../content/toolbar/chat/PLVLWChatInputLayout';
import { PLVLWLikesParticleLayout } from '../content/toolbar/likes/PLVLWLikesParticleLayout';
import { PLVLWInteractLayout } from '../interact/PLVLWInteractLayout';
import { PLVLWPPTLayout } from '../ppt/PLVLWPPTLayout';

@Preview
@Component
export struct PLVLWTopLayerLayout {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State responseRegionX: Length = 0
  @State responseRegionY: Length = 0
  @State responseRegionWidth: Length = 0
  @State responseRegionHeight: Length = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onLayoutData()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    RelativeContainer() {
      // PPT布局
      PLVLWPPTLayout()

      // 点赞动画
      PLVLWLikesParticleLayout()
        .width(136)
        .height(169)
        .alignRules({
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          bottom: 52
        })
        .hitTestBehavior(HitTestMode.None)

      // 聊天室输入框
      PLVLWChatInputLayout()

      // 互动布局
      PLVLWInteractLayout()
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .responseRegion({
      x: this.responseRegionX,
      y: this.responseRegionY,
      width: this.responseRegionWidth,
      height: this.responseRegionHeight
    })
    .hitTestBehavior(HitTestMode.Default)
  }

  onLayoutData() {
    watchStates(() => {
      const topLayerViewArea = this.layoutDataBus.topLayerViewTouchArea.value ?? new Rect()
      PLVUtils.debounce(() => {
        this.responseRegionX = topLayerViewArea.left
        this.responseRegionY = topLayerViewArea.top
        this.responseRegionWidth = topLayerViewArea.width()
        this.responseRegionHeight = topLayerViewArea.height()
      }, 100, 'topLayerViewAreaEvent')
    }).pushTo(this.observers)
  }
}