import {
  MenuType as ContentTabMenuType,
  PLVCommonConstants,
  PLVLiveSceneSDK,
  PLVLoginType,
  PLVProductDataBean,
  PLVTextUtils
} from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus'
import { PLVLWChatInputEntryLayout } from './chat/PLVLWChatInputEntryLayout'
import { PLVLWToolBarLinkMicControlIcon } from './linkmic/PLVLWLinkMicControlLayout'
import { PLVLWMoreSettingIcon } from './moresetting/PLVLWMoreSettingLayout'
import { PLVLWToolBarPreviousIcon } from './previous/PLVLWToolBarPreviousLayout'
import { PLVLWToolBarProductIcon } from './product/PLVLWToolBarProductLayout'
import { PLVLWToolBarRewardIcon } from './reward/PLVLWToolBarRewardLayout'

@Component
export struct PLVLWToolBarLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private isLinkMicIconVisible: boolean = false
  @State private currentContentTabMenuType: ContentTabMenuType | undefined = undefined
  @State private rewardIconVisible: boolean = false
  @State private productIconVisible: boolean = false
  @State private likesCount: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
    this.rewardIconVisible = this.sdk.channelData.loginType === PLVLoginType.LIVE
    this.layoutDataBus.contentTabMenuStatus.observe(status => {
      this.currentContentTabMenuType = status.selectTabType
    }).pushTo(this.observers)
    this.sdk.chatroomManager.eventNotify.on('likes_count', this.onLikesCount, this)
    this.onLikesCount(this.sdk.chatroomManager.likesCount)
    this.sdk.productManager.eventNotify.on('product_data', this.onProductData, this)
    this.onProductData(this.sdk.productManager.getData())
  }

  build() {
    RelativeContainer() {
      PLVLWChatInputEntryLayout()
        .id('plvlw_tool_bar_chat_input_layout')
        .height(36)
        .constraintSize({
          maxWidth: this.isPortrait ? undefined : 180
        })
        .margin({
          left: 12,
          right: 8
        })
        .alignRules({
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          end: { anchor: 'plvlw_tool_bar_tools_layout', align: HorizontalAlign.Start }
        })
        .visibility(this.currentContentTabMenuType === ContentTabMenuType.CHAT || !this.isPortrait ? Visibility.Visible : Visibility.None)

      Scroll() {
        Row({ space: 8 }) {
          PLVLWMoreSettingIcon()
            .width(36)
            .height(36)
            .visibility(this.isPortrait ? Visibility.Visible : Visibility.None)

          PLVLWToolBarLinkMicControlIcon({
            isLinkMicIconVisible: this.isLinkMicIconVisible
          })
            .width(36)
            .height(36)
            .visibility(this.isPortrait && this.isLinkMicIconVisible ? Visibility.Visible : Visibility.None)

          PLVLWToolBarProductIcon()
            .width(36)
            .height(36)
            .visibility(this.productIconVisible ? Visibility.Visible : Visibility.None)

          PLVLWToolBarRewardIcon()
            .width(36)
            .height(36)
            .visibility(this.rewardIconVisible ? Visibility.Visible : Visibility.None)

          PLVLWToolBarPreviousIcon({
            viewWidth: 36,
            viewHeight: 36
          })

          RelativeContainer() {
            Image($r('app.media.plvlw_tool_bar_like_icon'))
              .width(36)
              .height(36)

            Text(PLVTextUtils.toKString(this.likesCount))
              .fontSize(8)
              .fontColor($r('app.color.plvlw_tool_bar_like_count_foreground'))
              .backgroundColor($r('app.color.plvlw_tool_bar_like_count_background'))
              .borderRadius(6)
              .constraintSize({
                minWidth: 26
              })
              .textAlign(TextAlign.Center)
              .translate({
                y: -3
              })
              .padding({
                left: 4,
                right: 4,
                top: 1,
                bottom: 1
              })
              .alignRules({
                middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
              })
          }
          .width(36)
          .height(36)
          .onClick(() => {
            this.layoutDataBus.onClickLike.setValue(this.likesCount + 1)
            this.sdk.chatroomManager.likes(1)
          })
        }
      }
      .id('plvlw_tool_bar_tools_layout')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .clip(false)
      .constraintSize({
        maxWidth: 212
      })
      .margin({
        right: 12
      })
      .alignRules({
        center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
        end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
      })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(36)
  }

  private readonly onLikesCount = (likesCount: number) => {
    this.likesCount = likesCount
  }

  private readonly onProductData = (value: PLVProductDataBean) => {
    this.productIconVisible = value.isOpenProduct ?? false
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.sdk.chatroomManager.eventNotify.off('likes_count', this.onLikesCount)
    this.sdk.productManager.eventNotify.off('product_data', this.onProductData)
  }
}