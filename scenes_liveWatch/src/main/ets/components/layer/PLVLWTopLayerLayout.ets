import {
  PLVCommonConstants,
  PLVLinkMicState,
  PLVLiveSceneSDK,
  PLVLoginType,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, Rect, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus';
import { PLVLWChatInputLayout } from '../content/toolbar/chat/PLVLWChatInputLayout';
import { PLVLWLikesParticleLayout } from '../content/toolbar/likes/PLVLWLikesParticleLayout';
import { PLVLWInteractLayout } from '../interact/PLVLWInteractLayout';
import { PLVLWLinkMicInvitationLayout } from '../linkmic/PLVLWLinkMicInvitationLayout';
import { PLVLWPPTLayout } from '../ppt/PLVLWPPTLayout';

@Preview
@Component
export struct PLVLWTopLayerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State responseRegionX: Length = 0
  @State responseRegionY: Length = 0
  @State responseRegionWidth: Length = 0
  @State responseRegionHeight: Length = 0
  @State private isLinkmic: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onLayoutData()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    RelativeContainer() {
      if (!this.isLinkmic) {
        // PPT布局
        PLVLWPPTLayout()
      }

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

      // 邀请连麦
      if (PLVLoginType.LIVE == this.sdk.channelData?.loginType) {
        PLVLWLinkMicInvitationLayout()
      }

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
      const isLinkMic = this.sdk?.linkmicManager.linkmicState.value === PLVLinkMicState.Joined
      const topLayerViewArea = this.layoutDataBus.topLayerViewTouchArea.value ?? new Rect()
      const pptLayoutVisible = !isLinkMic
      this.isLinkmic = isLinkMic
      PLVUtils.debounce(() => {
        this.responseRegionX = pptLayoutVisible ? topLayerViewArea.left : 0
        this.responseRegionY = pptLayoutVisible ? topLayerViewArea.top : 0
        this.responseRegionWidth = pptLayoutVisible ? topLayerViewArea.width() : 0
        this.responseRegionHeight = pptLayoutVisible ? topLayerViewArea.height() : 0
      }, 100, 'topLayerViewAreaEvent')
    }).pushTo(this.observers)
  }
}